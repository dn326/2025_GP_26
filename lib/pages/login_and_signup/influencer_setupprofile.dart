import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
// ======== Firebase & media
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/models/dropdown_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main_screen.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide createModel;
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/elan_storage.dart';
import '../../components/labeled.dart';
import '../../components/searchable_dropdown.dart';
import '../../services/dropdown_list_loader.dart';

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

class InfluencerSetupProfileModel extends FlutterFlowModel {
  FocusNode? influncerNameFocusNode;
  TextEditingController? influncerNameTextController;
  FocusNode? influncerDescreptionFocusNode;
  TextEditingController? influncerDescreptionTextController;
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  @override
  void dispose() {
    influncerNameFocusNode?.dispose();
    influncerNameTextController?.dispose();
    influncerDescreptionFocusNode?.dispose();
    influncerDescreptionTextController?.dispose();
    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
  }
}

class InfluencerSetupProfilePage extends StatefulWidget {
  const InfluencerSetupProfilePage({super.key});

  static String routeName = 'influencer_setup_profile';
  static String routePath = '/influencerSetupProfile';

  @override
  State<InfluencerSetupProfilePage> createState() =>
      _InfluencerSetupProfilePageState();
}

class _InfluencerSetupProfilePageState extends State<InfluencerSetupProfilePage>
    with SingleTickerProviderStateMixin {
  late InfluencerSetupProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  File? _pickedImage;
  Uint8List? _pickedBytes;
  String? _imageUrl;

  final bool _loading = false;
  bool _uploadingImage = false;

  final List<_SocialRow> _socialRows = [_SocialRow()];

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
    _model = InfluencerSetupProfileModel();

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

      setState(() {
        _imageUrl = newUrl;
        _uploadingImage = false;
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

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^05[0-9]{8}$').hasMatch(v)) {
      return ' 05xxxxxxxx رقم الجوال يجب أن يكون';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
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

      if (errors.isNotEmpty) {
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
      }

      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      DocumentReference profileRef = FirebaseFirestore.instance
          .collection('profiles')
          .doc();

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
      await influencerCol.add({
        'content_type_id': _selectedInfluencerContentType?.id,
        'content_type': _selectedInfluencerContentType?.nameAr,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final socialCol = FirebaseFirestore.instance.collection('social_account');
      final batch = FirebaseFirestore.instance.batch();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
        final user = FirebaseAuth.instance.currentUser!;
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', uid);
        await prefs.setString('user_type', 'influencer');
        await prefs.setString('email', user.email!);
        await prefs.setString('account_status', 'active');
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
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
        title: Text(
          'إنشاء الملف الشخصي',
          textAlign: TextAlign.center,
          style: t.headlineSmall.override(
            fontFamily: 'Inter Tight',
            color: t.primaryText,
            letterSpacing: 0.0,
            fontWeight: t.headlineSmall.fontWeight,
            fontStyle: t.headlineSmall.fontStyle,
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                child: Container(
                  decoration: BoxDecoration(color: t.backgroundElan),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
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
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  0,
                                  16,
                                  0,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Avatar
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
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
                                              onTap:
                                                  (_uploadingImage || _loading)
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
                                                  const EdgeInsetsDirectional.fromSTEB(
                                                    0,
                                                    10,
                                                    0,
                                                    40,
                                                  ),
                                              child: Opacity(
                                                opacity:
                                                    (_uploadingImage ||
                                                        _loading)
                                                    ? 0.5
                                                    : 1,
                                                child: GestureDetector(
                                                  onTap:
                                                      (_uploadingImage ||
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
                                    Labeled(
                                      'الاسم ',
                                      errorText: _showErrors && _nameEmpty
                                          ? 'يرجى إدخال الاسم.'
                                          : null,
                                      child: TextFormField(
                                        controller:
                                            _model.influncerNameTextController,
                                        focusNode:
                                            _model.influncerNameFocusNode,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        decoration: inputDecoration(
                                          context,
                                          isError: _showErrors && _nameEmpty,
                                        ),
                                        style: t.bodyLarge.copyWith(
                                          color: t.primaryText,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),

                                    // Content Type Dropdown
                                    Labeled(
                                      'نوع المحتوى',
                                      errorText: _showErrors && _contentEmpty
                                          ? 'يرجى اختيار نوع المحتوى.'
                                          : null,
                                      child: SearchableDropdown<DropDownList>(
                                        items: _influencerContentTypes,
                                        value: _selectedInfluencerContentType,
                                        onChanged: (v) {
                                          setState(
                                            () =>
                                                _selectedInfluencerContentType =
                                                    v,
                                          );
                                        },
                                        hint: 'اختر أو ابحث...',
                                        isError: _showErrors && _contentEmpty,
                                      ),
                                    ),

                                    // Social Accounts
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                            20,
                                            20,
                                            20,
                                            20,
                                          ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
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
                                                  const EdgeInsetsDirectional.fromSTEB(
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
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        const AlignmentDirectional(
                                                          1,
                                                          0,
                                                        ),
                                                    child: FlutterFlowIconButton(
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
                                                          _socialRows.add(
                                                            _SocialRow(),
                                                          );
                                                        });
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
                                                          const EdgeInsetsDirectional.fromSTEB(
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
                                                  const EdgeInsetsDirectional.fromSTEB(
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
                                                        const EdgeInsetsDirectional.fromSTEB(
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
                                                      textAlign: TextAlign.end,
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
                                                  const EdgeInsetsDirectional.fromSTEB(
                                                    0,
                                                    0,
                                                    0,
                                                    16,
                                                  ),
                                              child: Column(
                                                children: List.generate(_socialRows.length, (
                                                  i,
                                                ) {
                                                  final row = _socialRows[i];
                                                  final platformEmpty =
                                                      row.platform?.id ==
                                                          null ||
                                                      row.platform!.id
                                                          .toString()
                                                          .isEmpty;
                                                  final usernameEmpty = row
                                                      .usernameCtrl
                                                      .text
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
                                                              const EdgeInsetsDirectional.fromSTEB(
                                                                0,
                                                                0,
                                                                0,
                                                                16,
                                                              ),
                                                          child: FlutterFlowIconButton(
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
                                                                  _socialRows.add(
                                                                    _SocialRow(),
                                                                  );
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsetsDirectional.fromSTEB(
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
                                                                controller: row
                                                                    .usernameCtrl,
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
                                                                      const EdgeInsets.only(
                                                                        top: 4,
                                                                      ),
                                                                  child: InkWell(
                                                                    onTap: () {
                                                                      final url =
                                                                          'https://${row.platform!.domain}/${row.usernameCtrl.text.trim()}';
                                                                      launchUrl(
                                                                        Uri.parse(
                                                                          url,
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      '${row.platform!.domain}/${row.usernameCtrl.text.trim()}',
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .blue,
                                                                        decoration:
                                                                            TextDecoration.underline,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (showUsernameErr)
                                                                const Padding(
                                                                  padding:
                                                                      EdgeInsetsDirectional.fromSTEB(
                                                                        0,
                                                                        6,
                                                                        4,
                                                                        0,
                                                                      ),
                                                                  child: Text(
                                                                    'يرجى إدخال اسم الحساب.',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .red,
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
                                                              const EdgeInsetsDirectional.fromSTEB(
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
                                                              SearchableDropdown<
                                                                DropDownList
                                                              >(
                                                                items:
                                                                    _socialPlatforms,
                                                                value: row
                                                                    .platform,
                                                                onChanged: (v) {
                                                                  setState(
                                                                    () =>
                                                                        row.platform =
                                                                            v,
                                                                  );
                                                                },
                                                                hint:
                                                                    'اختر المنصة',
                                                                isError:
                                                                    showPlatformErr,
                                                              ),
                                                              if (showPlatformErr)
                                                                const Padding(
                                                                  padding:
                                                                      EdgeInsetsDirectional.fromSTEB(
                                                                        0,
                                                                        6,
                                                                        4,
                                                                        0,
                                                                      ),
                                                                  child: Text(
                                                                    'يرجى اختيار المنصة.',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .red,
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
                                    Labeled(
                                      'النبذة الشخصية',
                                      child: TextFormField(
                                        controller: _model
                                            .influncerDescreptionTextController,
                                        focusNode: _model
                                            .influncerDescreptionFocusNode,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: inputDecoration(context),
                                        style: t.bodyLarge.copyWith(
                                          color: t.primaryText,
                                        ),
                                        textAlign: TextAlign.end,
                                        maxLines: 3,
                                      ),
                                    ),

                                    // Phone
                                    Labeled(
                                      'رقم الجوال',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          TextFormField(
                                            controller: _model
                                                .phoneNumberTextController,
                                            focusNode:
                                                _model.phoneNumberFocusNode,
                                            keyboardType: TextInputType.phone,
                                            decoration: inputDecoration(
                                              context,
                                              isError:
                                                  _showErrors &&
                                                  _bothContactsEmpty &&
                                                  _model
                                                      .phoneNumberTextController!
                                                      .text
                                                      .trim()
                                                      .isEmpty,
                                            ),
                                            style: t.bodyLarge.copyWith(
                                              color: t.primaryText,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                          if (_showErrors &&
                                              _bothContactsEmpty &&
                                              _model
                                                  .phoneNumberTextController!
                                                  .text
                                                  .trim()
                                                  .isEmpty)
                                            const Padding(
                                              padding:
                                                  EdgeInsetsDirectional.fromSTEB(
                                                    0,
                                                    6,
                                                    4,
                                                    0,
                                                  ),
                                              child: Text(
                                                'يرجى إدخال رقم الجوال أو البريد الإلكتروني.',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Email
                                    Labeled(
                                      'البريد الإلكتروني',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          TextFormField(
                                            controller:
                                                _model.emailTextController,
                                            focusNode: _model.emailFocusNode,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: inputDecoration(
                                              context,
                                              isError:
                                                  _showErrors &&
                                                  _bothContactsEmpty &&
                                                  _model
                                                      .emailTextController!
                                                      .text
                                                      .trim()
                                                      .isEmpty,
                                            ),
                                            style: t.bodyLarge.copyWith(
                                              color: t.primaryText,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                          if (_showErrors &&
                                              _bothContactsEmpty &&
                                              _model.emailTextController!.text
                                                  .trim()
                                                  .isEmpty)
                                            const Padding(
                                              padding:
                                                  EdgeInsetsDirectional.fromSTEB(
                                                    0,
                                                    6,
                                                    4,
                                                    0,
                                                  ),
                                              child: Text(
                                                'يرجى إدخال البريد الإلكتروني أو رقم الجوال.',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Button
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                            0,
                                            16,
                                            0,
                                            24,
                                          ),
                                      child: AnimatedBuilder(
                                        animation: _shakeCtrl,
                                        builder: (context, child) =>
                                            Transform.translate(
                                              offset: Offset(_shakeOffset(), 0),
                                              child: child,
                                            ),
                                        child: FFButtonWidget(
                                          onPressed: _saveAll,
                                          text: 'إنشاء',
                                          options: FFButtonOptions(
                                            width: 200,
                                            height: 40,
                                            color: t
                                                .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                            textStyle: t.titleMedium.override(
                                              fontFamily: 'Inter',
                                              color: t.containers,
                                            ),
                                            elevation: 2,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
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

class _SocialRow {
  DropDownList? platform;
  final TextEditingController usernameCtrl;

  _SocialRow({TextEditingController? usernameCtrl})
    : usernameCtrl = usernameCtrl ?? TextEditingController();

  void dispose() {
    usernameCtrl.dispose();
  }
}
