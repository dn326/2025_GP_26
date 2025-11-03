import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/models/dropdown_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide createModel;
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/services/elan_storage.dart';
import '../components/feq_components.dart';
import '../profile/models/influencer_profile_model.dart';
import '../services/dropdown_list_loader.dart';

export 'influencer_edit_profile_model.dart';

InputDecoration inputDecoration(BuildContext context, {bool isError = false}) {
  final t = FlutterFlowTheme.of(context);
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: t.secondary, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: isError
            ? Colors.red
            : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: t.containers,
  );
}

InputDecoration platformInputDecoration(
    BuildContext context, {
      bool isError = false,
    }) {
  final t = FlutterFlowTheme.of(context);
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: t.secondary, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: isError
            ? Colors.red
            : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: t.containers,
  );
}

class InfluncerEditProfileWidget extends StatefulWidget {
  const InfluncerEditProfileWidget({super.key});

  static String routeName = 'influncer_edit_profile';
  static String routePath = '/influncerEditProfile';

  @override
  State<InfluncerEditProfileWidget> createState() =>
      _InfluncerEditProfileWidgetState();
}

class _InfluncerEditProfileWidgetState extends State<InfluncerEditProfileWidget>
    with SingleTickerProviderStateMixin {
  late InfluencerEditProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _profileDocId;
  String? _influencerSubDocId;

  File? _pickedImage;
  Uint8List? _pickedBytes;
  String? _imageUrl;

  bool _loading = true;
  String? _error;

  bool _uploadingImage = false;

  List<_SocialRow> _socialRows = [_SocialRow()];

  bool _initialized = false;
  String _initialSnapshot = '';
  late bool _dirty = false;
  bool _nameEmpty = false;
  bool _contentEmpty = false;
  bool _bothContactsEmpty = false;
  bool _socialsRequireError = false;
  bool _showErrors = false;

  late AnimationController _shakeCtrl;

  late List<DropDownList> _influencerContentTypes;
  late List<DropDownList> _socialPlatforms;

  DropDownList? _selectedInfluencerContentType;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfluencerEditProfileModel());

    _influencerContentTypes =
        DropDownListLoader.instance.influencerContentTypes;
    _socialPlatforms = DropDownListLoader.instance.socialPlatforms;

    _model.influncerNameTextController ??= TextEditingController();
    _model.influncerNameFocusNode ??= FocusNode();

    _model.influncerDescreptionTextController ??= TextEditingController();
    _model.influncerDescreptionFocusNode ??= FocusNode();

    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _attachFieldListeners();
    _attachSocialRowListeners(_socialRows.first);
    _prefillFromDb();
  }

  void _attachFieldListeners() {
    for (final c in [
      _model.influncerNameTextController,
      _model.influncerDescreptionTextController,
      _model.phoneNumberTextController,
      _model.emailTextController,
    ]) {
      c?.addListener(_onAnyFieldChanged);
    }
  }

  void _attachSocialRowListeners(_SocialRow row) {
    row.usernameCtrl.addListener(_onAnyFieldChanged);
  }

  String _currentSnapshot() {
    final socials = _socialRows
        .map(
          (r) => {'p': r.platform?.id ?? '', 'u': r.usernameCtrl.text.trim()},
    )
        .toList();
    return {
      'name': _model.influncerNameTextController?.text.trim() ?? '',
      'content_id': _selectedInfluencerContentType?.id ?? 0,
      'desc': _model.influncerDescreptionTextController?.text.trim() ?? '',
      'phone': _model.phoneNumberTextController?.text.trim() ?? '',
      'email': _model.emailTextController?.text.trim() ?? '',
      'img': _imageUrl ?? '',
      'socials': socials,
    }.toString();
  }

  void _recomputeValidation() {
    final name = _model.influncerNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';

    _nameEmpty = name.isEmpty;
    _contentEmpty = _selectedInfluencerContentType == null;
    _bothContactsEmpty = phone.isEmpty && email.isEmpty;

    bool hasCompletePair = false;
    for (final r in _socialRows) {
      final p = r.platform?.id.toString() ?? '';
      final u = r.usernameCtrl.text.trim();
      if (p.isNotEmpty && u.isNotEmpty) {
        hasCompletePair = true;
        break;
      }
    }
    _socialsRequireError = !hasCompletePair;
  }

  void _onAnyFieldChanged() {
    if (!_initialized) return;
    _recomputeValidation();
    final now = _currentSnapshot();
    final changed =
        now != _initialSnapshot || _pickedImage != null || _pickedBytes != null;
    setState(() => _dirty = changed);
  }

  Future<void> _prefillFromDb() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _redirectToLogin();
        return;
      }

      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (usersSnap.docs.isEmpty) {
        throw Exception('User record not found');
      }
      DocumentSnapshot userDoc = usersSnap.docs.first;
      if (!userDoc.exists) {
        _redirectToLogin();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userType = (userData['user_type'] ?? '').toString().toLowerCase();
      if (userType != 'influencer') {
        setState(() {
          _loading = false;
          _error = 'الحساب ليس من نوع مؤثر.';
        });
        return;
      }

      final profilesSnap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('profile_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (profilesSnap.docs.isNotEmpty) {
        final profileDoc = profilesSnap.docs.first;
        _profileDocId = profileDoc.id;

        InfluencerProfileModel userProfileModel =
        InfluencerProfileModel.fromJson(profileDoc.data());
        _model.influncerNameTextController!.text = userProfileModel.name;
        _model.influncerDescreptionTextController!.text =
            userProfileModel.description;
        _model.emailTextController!.text = userProfileModel.contactEmail;
        _model.phoneNumberTextController!.text = userProfileModel.phoneNumber;

        final rawImageUrl = userProfileModel.profileImage;
        if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
          _imageUrl = rawImageUrl;
        }

        final influencerSnap = await profileDoc.reference
            .collection('influencer_profile')
            .limit(1)
            .get();

        if (influencerSnap.docs.isNotEmpty) {
          final influencerDoc = influencerSnap.docs.first;
          _influencerSubDocId = influencerDoc.id;

          final contentTypeRaw = influencerDoc.data()['content_type_id'];
          int contentId = 0;

          if (contentTypeRaw is int) {
            contentId = contentTypeRaw;
          } else if (contentTypeRaw is String && contentTypeRaw.isNotEmpty) {
            contentId = int.tryParse(contentTypeRaw) ?? 0;
          }

          _selectedInfluencerContentType = _influencerContentTypes.firstWhere(
                (c) => c.id == contentId,
            orElse: () => _influencerContentTypes.first,
          );
        }
      }

      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapString = await FirebaseFirestore.instance
          .collection('social_account')
          .where('influencer_id', isEqualTo: uid)
          .get();
      final snapRef = await FirebaseFirestore.instance
          .collection('social_account')
          .where('influencer_id', isEqualTo: usersRef)
          .get();
      final allDocs = [...snapString.docs, ...snapRef.docs];

      final rows = allDocs.map((d) {
        final m = d.data();
        final platId = (m['platform'] ?? '').toString();
        final plat = _socialPlatforms.firstWhere(
              (p) => p.id.toString() == platId,
          orElse: () => _socialPlatforms.first,
        );
        final row = _SocialRow(
          platform: plat,
          usernameCtrl: TextEditingController(
            text: (m['username'] ?? '').toString(),
          ),
        );
        _attachSocialRowListeners(row);
        return row;
      }).toList();

      if (rows.isNotEmpty) {
        _socialRows = rows;
      } else {
        _attachSocialRowListeners(_socialRows.first);
      }

      _recomputeValidation();

      setState(() {
        _loading = false;
        _error = null;
        _initialized = true;
        _initialSnapshot = _currentSnapshot();
        _dirty = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'حصل خطأ أثناء جلب البيانات: $e';
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(UserLoginPage.routePath, (route) => false);
  }

  Future<void> _pickAndUploadImage() async {
    if (_loading) return;

    try {
      setState(() => _uploadingImage = true);

      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (x == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      String extension = 'jpg';
      final String? mimeType = x.mimeType;
      final String path = x.path;

      if (mimeType != null) {
        if (mimeType.contains('png')) {
          extension = 'png';
        } else if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
          extension = 'jpg';
        } else if (mimeType.contains('webp')) {
          extension = 'webp';
        } else if (mimeType.contains('gif')) {
          extension = 'gif';
        }
      } else if (path.isNotEmpty) {
        final parts = path.split('.');
        if (parts.length > 1) {
          extension = parts.last.toLowerCase();
          if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension)) {
            extension = 'jpg';
          }
        }
      }

      final storage = await ElanStorage.storage;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$ts.$extension';

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = storage.ref().child('profiles').child(uid).child(fileName);

      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=3600',
      );

      String newUrl;
      if (kIsWeb) {
        final bytes = await x.readAsBytes();
        setState(() {
          _pickedBytes = bytes;
          _pickedImage = null;
        });
        await ref.putData(bytes, metadata);
        newUrl = await ref.getDownloadURL();
      } else {
        final file = File(x.path);
        setState(() {
          _pickedImage = file;
          _pickedBytes = null;
        });
        await ref.putFile(file, metadata);
        newUrl = await ref.getDownloadURL();
      }

      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final oldUrlClean = _imageUrl!.split('?').first;
        final newUrlClean = newUrl.split('?').first;
        if (oldUrlClean != newUrlClean) {
          await ElanStorage.deleteByUrl(oldUrlClean);
        }
      }

      setState(() {
        _imageUrl = newUrl;
        _uploadingImage = false;
        _dirty = true;
      });
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e')));
      }
      debugPrint('pick/upload error: $e');
    }
  }

  Future<void> _saveAll() async {
    _recomputeValidation();

    final phoneError = _validatePhone(_model.phoneNumberTextController?.text);
    final emailError = _validateEmail(_model.emailTextController?.text);

    if (_nameEmpty ||
        _contentEmpty ||
        _bothContactsEmpty ||
        _socialsRequireError ||
        phoneError != null ||
        emailError != null) {
      setState(() => _showErrors = true);
      _shakeCtrl.forward(from: 0);

      final errors = <TextSpan>[];
      if (emailError != null) {
        errors.add(
          TextSpan(
            text: '$emailError\n',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
      if (phoneError != null) {
        errors.add(
          TextSpan(
            text: phoneError,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: RichText(
            text: TextSpan(
              children: errors,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      DocumentReference profileRef;
      if (_profileDocId != null) {
        profileRef = FirebaseFirestore.instance
            .collection('profiles')
            .doc(_profileDocId);
      } else {
        profileRef = FirebaseFirestore.instance.collection('profiles').doc();
        _profileDocId = profileRef.id;
      }

      final updates = {
        'profile_id': uid,
        'name': _model.influncerNameTextController!.text.trim(),
        'description': _model.influncerDescreptionTextController!.text.trim(),
        'contact_email': _model.emailTextController!.text.trim(),
        'phone_number': _model.phoneNumberTextController!.text.trim(),
      };

      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final cleanUrl = _imageUrl!.split('?').first;
        updates['profile_image'] = cleanUrl;
      } else {
        updates['profile_image'] = '';
      }

      await profileRef.set(updates, SetOptions(merge: true));

      final influencerCol = profileRef.collection('influencer_profile');
      if (_influencerSubDocId != null) {
        await influencerCol.doc(_influencerSubDocId!).update({
          'content_type_id': _selectedInfluencerContentType?.id,
          'content_type': _selectedInfluencerContentType?.nameAr,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        final newDoc = await influencerCol.add({
          'content_type_id': _selectedInfluencerContentType?.id,
          'content_type': _selectedInfluencerContentType?.nameAr,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        _influencerSubDocId = newDoc.id;
      }

      final socialCol = FirebaseFirestore.instance.collection('social_account');
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final oldSnapString = await socialCol
          .where('influencer_id', isEqualTo: uid)
          .get();
      final oldSnapRef = await socialCol
          .where('influencer_id', isEqualTo: usersRef)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final d in [...oldSnapString.docs, ...oldSnapRef.docs]) {
        batch.delete(d.reference);
      }

      for (final row in _socialRows) {
        final platformId = row.platform?.id ?? '';
        final platformEmpty =
            row.platform?.id == null || row.platform!.id.toString().isEmpty;
        final username = row.usernameCtrl.text.trim();
        if (platformEmpty && username.isEmpty) continue;

        batch.set(socialCol.doc(), {
          'platform': platformId,
          'username': username,
          'influencer_id': uid,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (mounted) {
        _initialSnapshot = _currentSnapshot();
        _dirty = false;
        _pickedImage = null;
        _pickedBytes = null;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));

        context.pushNamed(InfluncerProfileWidget.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
      }
      debugPrint('Save error: $e');
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    for (final r in _socialRows) {
      r.dispose();
    }
    _model.dispose();
    super.dispose();
  }

  double _shakeOffset() {
    if (!_shakeCtrl.isAnimating) return 0;
    return math.sin(_shakeCtrl.value * 10 * math.pi) * 8;
  }

  Widget _avatarWidget({
    String? imageUrl,
    Uint8List? bytes,
    File? file,
    double size = 100,
  }) {
    final theme = FlutterFlowTheme.of(context);

    Widget imageWidget;

    if (bytes != null && bytes.isNotEmpty) {
      imageWidget = Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/person_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      );
    } else if (file != null) {
      imageWidget = Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/person_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => Image.asset(
          'assets/images/person_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = Image.asset(
        'assets/images/person_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    return Container(
      key: ValueKey(imageUrl ?? bytes ?? file),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.tertiary,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
              .withValues(alpha: 0.2),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'رقم الجوال يجب أن يكون 05xxxxxxxx';
    if (!RegExp(r'^05[0-9]{8}$').hasMatch(v)) {
      return 'رقم الجوال يجب أن يكون 05xxxxxxxx';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'البريد الإلكتروني غير صحيح';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: AppBar(
        backgroundColor: t.containers,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const _TitleText(),
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: 16,
                top: 8,
                child: FlutterFlowIconButton(
                  borderRadius: 8,
                  buttonSize: 40,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color:
                    t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                    size: 24,
                  ),
                  onPressed: () async {
                    context.pushNamed(InfluncerProfileWidget.routeName);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Text(
            _error!,
            style: t.bodyMedium.copyWith(color: t.primaryText),
          ),
        )
            : Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
          child: Container(
            decoration: BoxDecoration(color: t.backgroundElan),
            child: Padding(
              padding:
              const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.containers,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4,
                              color: Color(0x33000000),
                              offset: Offset(0, 2),
                            ),
                          ],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(16),
                          ),
                        ),
                        child: Padding(
                          padding:
                          const EdgeInsetsDirectional.fromSTEB(
                            0,
                            16,
                            0,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              // Avatar
                              Padding(
                                padding: const EdgeInsetsDirectional
                                    .fromSTEB(
                                  0,
                                  16,
                                  0,
                                  0,
                                ),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment:
                                      const AlignmentDirectional(
                                        0,
                                        -1,
                                      ),
                                      child: GestureDetector(
                                        onTap: (_uploadingImage ||
                                            _loading)
                                            ? null
                                            : _pickAndUploadImage,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            _avatarWidget(
                                              imageUrl: _imageUrl,
                                              bytes: _pickedBytes,
                                              file: _pickedImage,
                                              size: 100,
                                            ),
                                            if (_uploadingImage)
                                              const SizedBox(
                                                width: 28,
                                                height: 28,
                                                child:
                                                CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment:
                                      const AlignmentDirectional(
                                        0,
                                        -1,
                                      ),
                                      child: Padding(
                                        padding:
                                        const EdgeInsetsDirectional
                                            .fromSTEB(
                                          0,
                                          10,
                                          0,
                                          40,
                                        ),
                                        child: Opacity(
                                          opacity: (_uploadingImage ||
                                              _loading)
                                              ? 0.5
                                              : 1,
                                          child: GestureDetector(
                                            onTap: (_uploadingImage ||
                                                _loading)
                                                ? null
                                                : _pickAndUploadImage,
                                            child: Text(
                                              'تغيير صورة الحساب',
                                              style: t.bodyMedium
                                                  .override(
                                                fontFamily: 'Inter',
                                                color: t.primaryText,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Name
                              FeqLabeledTextField(
                                label: 'الاسم ',
                                controller:
                                _model.influncerNameTextController,
                                focusNode:
                                _model.influncerNameFocusNode,
                                textCapitalization:
                                TextCapitalization.words,
                                textAlign: TextAlign.end,
                                width: double.infinity,
                                isError: _showErrors && _nameEmpty,
                                errorText: _showErrors && _nameEmpty
                                    ? 'يرجى إدخال الاسم.'
                                    : null,
                                decoration: inputDecoration(
                                  context,
                                  isError: _showErrors && _nameEmpty,
                                ),
                              ),

                              // Content Type Dropdown
                              FeqLabeled(
                                'نوع المحتوى',
                                errorText: _showErrors && _contentEmpty
                                    ? 'يرجى اختيار نوع المحتوى.'
                                    : null,
                                child: FeqSearchableDropdown<
                                    DropDownList>(
                                  items: _influencerContentTypes,
                                  value:
                                  _selectedInfluencerContentType,
                                  onChanged: (v) {
                                    setState(
                                          () =>
                                      _selectedInfluencerContentType =
                                          v,
                                    );
                                    _onAnyFieldChanged();
                                  },
                                  hint: 'اختر أو ابحث...',
                                  isError:
                                  _showErrors && _contentEmpty,
                                ),
                              ),

                              // Social Accounts
                              Padding(
                                padding: const EdgeInsetsDirectional
                                    .fromSTEB(
                                  20,
                                  20,
                                  20,
                                  20,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    const BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                    border: Border.all(
                                      color: t.secondary,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding:
                                        const EdgeInsetsDirectional
                                            .fromSTEB(
                                          0,
                                          0,
                                          0,
                                          16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .center,
                                          children: [
                                            Align(
                                              alignment:
                                              const AlignmentDirectional(
                                                1,
                                                0,
                                              ),
                                              child:
                                              FlutterFlowIconButton(
                                                borderRadius: 8,
                                                buttonSize: 50,
                                                icon: Icon(
                                                  Icons.add_circle,
                                                  color: t
                                                      .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    final r =
                                                    _SocialRow();
                                                    _attachSocialRowListeners(
                                                      r,
                                                    );
                                                    _socialRows.add(
                                                        r);
                                                  });
                                                  _onAnyFieldChanged();
                                                },
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                              const AlignmentDirectional(
                                                1,
                                                -1,
                                              ),
                                              child: Padding(
                                                padding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                  0,
                                                  0,
                                                  20,
                                                  0,
                                                ),
                                                child: Text(
                                                  'منصاتك في مواقع التواصل الاجتماعي',
                                                  textAlign:
                                                  TextAlign.end,
                                                  style: t.bodyMedium
                                                      .override(
                                                    fontFamily:
                                                    'Inter',
                                                    color:
                                                    t.primaryText,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                        const EdgeInsetsDirectional
                                            .fromSTEB(
                                          35,
                                          0,
                                          20,
                                          5,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Padding(
                                              padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                0,
                                                0,
                                                10,
                                                0,
                                              ),
                                              child: Text(
                                                'اسم الحساب في المنصة',
                                                style: t.bodyMedium
                                                    .override(
                                                  fontFamily: 'Inter',
                                                  color:
                                                  t.primaryText,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment:
                                              const AlignmentDirectional(
                                                1,
                                                -1,
                                              ),
                                              child: Text(
                                                'اسم المنصة ',
                                                textAlign:
                                                TextAlign.end,
                                                style: t.bodyMedium
                                                    .override(
                                                  fontFamily: 'Inter',
                                                  color:
                                                  t.primaryText,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                        const EdgeInsetsDirectional
                                            .fromSTEB(
                                          0,
                                          0,
                                          0,
                                          16,
                                        ),
                                        child: Column(
                                          children: List.generate(
                                              _socialRows.length, (
                                              i,
                                              ) {
                                            final row =
                                            _socialRows[i];
                                            final platformEmpty =
                                                row.platform?.id ==
                                                    null ||
                                                    row.platform!.id
                                                        .toString()
                                                        .isEmpty;
                                            final usernameEmpty = row
                                                .usernameCtrl.text
                                                .trim()
                                                .isEmpty;
                                            final showPlatformErr =
                                                _showErrors &&
                                                    _socialsRequireError &&
                                                    platformEmpty;
                                            final showUsernameErr =
                                                _showErrors &&
                                                    _socialsRequireError &&
                                                    usernameEmpty;

                                            return Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceEvenly,
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Align(
                                                  alignment:
                                                  const AlignmentDirectional(
                                                    1,
                                                    0,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                      0,
                                                      0,
                                                      0,
                                                      16,
                                                    ),
                                                    child:
                                                    FlutterFlowIconButton(
                                                      borderRadius: 8,
                                                      buttonSize: 50,
                                                      icon: Icon(
                                                        Icons
                                                            .minimize_outlined,
                                                        color: t
                                                            .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _socialRows
                                                              .removeAt(
                                                            i,
                                                          );
                                                          if (_socialRows
                                                              .isEmpty) {
                                                            final r =
                                                            _SocialRow();
                                                            _attachSocialRowListeners(
                                                              r,
                                                            );
                                                            _socialRows
                                                                .add(
                                                                r);
                                                          }
                                                        });
                                                        _onAnyFieldChanged();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                      0,
                                                      0,
                                                      20,
                                                      0,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .end,
                                                      children: [
                                                        TextFormField(
                                                          controller:
                                                          row.usernameCtrl,
                                                          textCapitalization:
                                                          TextCapitalization
                                                              .none,
                                                          decoration:
                                                          platformInputDecoration(
                                                            context,
                                                            isError:
                                                            showUsernameErr,
                                                          ),
                                                          style: t
                                                              .bodyMedium
                                                              .copyWith(
                                                            color: t
                                                                .primaryText,
                                                          ),
                                                          textAlign:
                                                          TextAlign
                                                              .end,
                                                        ),
                                                        if (row.platform !=
                                                            null &&
                                                            row
                                                                .usernameCtrl
                                                                .text
                                                                .trim()
                                                                .isNotEmpty)
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .only(
                                                              top: 4,
                                                            ),
                                                            child:
                                                            InkWell(
                                                              onTap:
                                                                  () {
                                                                final url =
                                                                    'https://${row.platform!.domain}/${row.usernameCtrl.text.trim()}';
                                                                launchUrl(
                                                                  Uri.parse(
                                                                    url,
                                                                  ),
                                                                );
                                                              },
                                                              child:
                                                              Text(
                                                                '${row.platform!.domain}/${row.usernameCtrl.text.trim()}',
                                                                style:
                                                                const TextStyle(
                                                                  color:
                                                                  Colors.blue,
                                                                  decoration:
                                                                  TextDecoration.underline,
                                                                ),
                                                                textAlign:
                                                                TextAlign.end,
                                                              ),
                                                            ),
                                                          ),
                                                        if (showUsernameErr)
                                                          const Padding(
                                                            padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                              0,
                                                              6,
                                                              4,
                                                              0,
                                                            ),
                                                            child:
                                                            Text(
                                                              'يرجى إدخال اسم الحساب.',
                                                              style:
                                                              TextStyle(
                                                                color:
                                                                Colors.red,
                                                                fontSize:
                                                                12,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                      0,
                                                      0,
                                                      20,
                                                      0,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .end,
                                                      children: [
                                                        FeqSearchableDropdown<
                                                            DropDownList>(
                                                          items:
                                                          _socialPlatforms,
                                                          value: row
                                                              .platform,
                                                          onChanged:
                                                              (v) {
                                                            setState(
                                                                  () =>
                                                              row.platform =
                                                                  v,
                                                            );
                                                            _onAnyFieldChanged();
                                                          },
                                                          hint:
                                                          'اختر المنصة',
                                                          isError:
                                                          showPlatformErr,
                                                        ),
                                                        if (showPlatformErr)
                                                          const Padding(
                                                            padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                              0,
                                                              6,
                                                              4,
                                                              0,
                                                            ),
                                                            child:
                                                            Text(
                                                              'يرجى اختيار المنصة.',
                                                              style:
                                                              TextStyle(
                                                                color:
                                                                Colors.red,
                                                                fontSize:
                                                                12,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Description
                              FeqLabeledTextField(
                                label: 'النبذة الشخصية',
                                controller: _model
                                    .influncerDescreptionTextController,
                                focusNode: _model
                                    .influncerDescreptionFocusNode,
                                textCapitalization:
                                TextCapitalization.sentences,
                                textAlign: TextAlign.end,
                                width: double.infinity,
                                maxLines: 3,
                                decoration: inputDecoration(context),
                              ),

                              // Phone
                              FeqLabeledTextField(
                                label: 'رقم الجوال',
                                controller:
                                _model.phoneNumberTextController,
                                focusNode:
                                _model.phoneNumberFocusNode,
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.end,
                                width: double.infinity,
                                validator: _validatePhone,
                                isError: _showErrors &&
                                    _bothContactsEmpty &&
                                    _model.phoneNumberTextController!
                                        .text
                                        .trim()
                                        .isEmpty,
                                errorText: _showErrors &&
                                    _bothContactsEmpty &&
                                    _model
                                        .phoneNumberTextController!
                                        .text
                                        .trim()
                                        .isEmpty
                                    ? 'يرجى إدخال رقم الجوال أو البريد الإلكتروني.'
                                    : null,
                                decoration: inputDecoration(
                                  context,
                                  isError: _showErrors &&
                                      _bothContactsEmpty &&
                                      _model
                                          .phoneNumberTextController!
                                          .text
                                          .trim()
                                          .isEmpty,
                                ),
                              ),

                              // Email
                              FeqLabeledTextField(
                                label: 'البريد الإلكتروني',
                                controller:
                                _model.emailTextController,
                                focusNode: _model.emailFocusNode,
                                keyboardType:
                                TextInputType.emailAddress,
                                textAlign: TextAlign.end,
                                width: double.infinity,
                                validator: _validateEmail,
                                isError: _showErrors &&
                                    _bothContactsEmpty &&
                                    _model.emailTextController!.text
                                        .trim()
                                        .isEmpty,
                                errorText: _showErrors &&
                                    _bothContactsEmpty &&
                                    _model.emailTextController!
                                        .text
                                        .trim()
                                        .isEmpty
                                    ? 'يرجى إدخال البريد الإلكتروني أو رقم الجوال.'
                                    : null,
                                decoration: inputDecoration(
                                  context,
                                  isError: _showErrors &&
                                      _bothContactsEmpty &&
                                      _model.emailTextController!.text
                                          .trim()
                                          .isEmpty,
                                ),
                              ),

                              // Buttons
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding:
                                    const EdgeInsetsDirectional
                                        .fromSTEB(
                                      0,
                                      16,
                                      0,
                                      24,
                                    ),
                                    child: FFButtonWidget(
                                      onPressed: () async {
                                        context.pushNamed(
                                          InfluncerProfileWidget
                                              .routeName,
                                        );
                                      },
                                      text: 'إلغاء',
                                      options: FFButtonOptions(
                                        width: 90,
                                        height: 40,
                                        color: t.secondary,
                                        textStyle:
                                        t.titleMedium.override(
                                          fontFamily: 'Inter Tight',
                                          color: t.containers,
                                          fontSize: 18,
                                        ),
                                        elevation: 2,
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                    const EdgeInsetsDirectional
                                        .fromSTEB(
                                      0,
                                      16,
                                      0,
                                      24,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _shakeCtrl,
                                      builder: (context, child) =>
                                          Transform.translate(
                                            offset: Offset(
                                              _shakeOffset(),
                                              0,
                                            ),
                                            child: child,
                                          ),
                                      child: FFButtonWidget(
                                        onPressed: _saveAll,
                                        text: 'تحديث',
                                        options: FFButtonOptions(
                                          width: 200,
                                          height: 40,
                                          color: t
                                              .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                          textStyle:
                                          t.titleMedium.override(
                                            fontFamily: 'Inter',
                                            color: t.containers,
                                          ),
                                          elevation: 2,
                                          borderRadius:
                                          BorderRadius.circular(
                                              12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'تعديل الملف الشخصي',
      textAlign: TextAlign.center,
      style: FlutterFlowTheme.of(context).headlineSmall.override(
        fontFamily: 'Inter Tight',
        color: FlutterFlowTheme.of(context).primaryText,
        letterSpacing: 0.0,
        fontWeight:
        FlutterFlowTheme.of(context).headlineSmall.fontWeight,
        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
      ),
    );
  }
}

class _SocialRow {
  DropDownList? platform;
  final TextEditingController usernameCtrl;

  _SocialRow({this.platform, TextEditingController? usernameCtrl})
      : usernameCtrl = usernameCtrl ?? TextEditingController();

  void dispose() {
    usernameCtrl.dispose();
  }
}