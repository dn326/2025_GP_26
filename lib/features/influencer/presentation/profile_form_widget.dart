import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/features/influencer/presentation/profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/utils/enum_profile_mode.dart';
import '../../../core/utils/ext_navigation.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../main_screen.dart';
import '../../../pages/login_and_signup/user_login.dart';
import '../data/models/influencer_profile_model.dart';
import '../data/models/profile_form_model.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide createModel;
import '/flutter_flow/flutter_flow_widgets.dart';

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
        color: isError ? Colors.red : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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

InputDecoration platformInputDecoration(BuildContext context, {bool isError = false}) {
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
        color: isError ? Colors.red : t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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

enum PhoneOwner { personal, assistant }

enum EmailOwner { personal, assistant }

class InfluencerProfileFormWidget extends StatefulWidget {
  final ProfileMode mode;

  const InfluencerProfileFormWidget({super.key, this.mode = ProfileMode.edit});

  // Routes for Edit mode
  static const String routeNameEdit = 'influencer-profile-edit';
  static const String routePathEdit = '/$routeNameEdit';

  // Routes for Setup mode
  // static const String routeNameSetup = 'influencer-profile-setup';
  // static const String routePathSetup = '/$routeNameSetup';

  @override
  State<InfluencerProfileFormWidget> createState() => _InfluencerProfileFormWidgetState();
}

class _InfluencerProfileFormWidgetState extends State<InfluencerProfileFormWidget> with SingleTickerProviderStateMixin {
  late InfluencerProfileFormModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _profileDocId;
  String? _influencerSubDocId;

  File? pickedImage;
  Uint8List? pickedBytes;
  String? _imageUrl;

  bool _loading = true;
  bool _uploadingImage = false;
  String? _error;

  List<_SocialRow> _socialRows = [_SocialRow()];

  bool _initialized = false;
  String _initialSnapshot = '';
  late bool dirty = false;
  late String _userEmail = '';
  bool _nameEmpty = false;
  bool _contentEmpty = false;
  bool _bothContactsEmpty = false;
  bool _socialsRequireError = false;
  bool _showErrors = false;

  PhoneOwner _phoneOwner = PhoneOwner.personal;
  EmailOwner _emailOwner = EmailOwner.personal;

  bool _useCustomEmail = false;
  final TextEditingController _customEmailController = TextEditingController();

  late AnimationController _shakeCtrl;

  late List<FeqDropDownList> _influencerContentTypes;
  late List<FeqDropDownList> _socialPlatforms;

  FeqDropDownList? _selectedInfluencerContentType;

  bool get isSetupMode => widget.mode == ProfileMode.setup;
  bool get isEditMode => widget.mode == ProfileMode.edit;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfluencerProfileFormModel());

    _influencerContentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;

    _model.influncerNameTextController ??= TextEditingController();
    _model.influncerNameFocusNode ??= FocusNode();

    _model.influncerDescreptionTextController ??= TextEditingController();
    _model.influncerDescreptionFocusNode ??= FocusNode();

    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _attachFieldListeners();
    _attachSocialRowListeners(_socialRows.first);

    if (isSetupMode) {
      _initSetupMode();
    } else {
      _prefillFromDb();
    }
  }

  void _initSetupMode() {
    _userEmail = firebaseAuth.currentUser?.email ?? '';
    setState(() {
      _loading = false;
      _initialized = true;
      _initialSnapshot = _currentSnapshot();
    });
  }

  void _attachFieldListeners() {
    for (final c in [
      _model.influncerNameTextController,
      _model.influncerDescreptionTextController,
      _model.phoneNumberTextController,
      _model.emailTextController,
      _customEmailController,
    ]) {
      c?.addListener(_onAnyFieldChanged);
    }
  }

  void _attachSocialRowListeners(_SocialRow row) {
    row.usernameCtrl.addListener(_onAnyFieldChanged);
  }

  String _currentSnapshot() {
    final socials = _socialRows.map((r) => {'p': r.platform?.id ?? '', 'u': r.usernameCtrl.text.trim()}).toList();
    return {
      'name': _model.influncerNameTextController?.text.trim() ?? '',
      'content_id': _selectedInfluencerContentType?.id ?? 0,
      'desc': _model.influncerDescreptionTextController?.text.trim() ?? '',
      'phone': _model.phoneNumberTextController?.text.trim() ?? '',
      'phone_owner': _phoneOwner.name,
      'email': _model.emailTextController?.text.trim() ?? '',
      'email_owner': _emailOwner.name,
      'img': _imageUrl ?? '',
      'socials': socials,
    }.toString();
  }

  void _recomputeValidation() {
    final name = _model.influncerNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _useCustomEmail
        ? _customEmailController.text.trim()
        : _userEmail;

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

  bool get _isFormValid {
    final name = _model.influncerNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _useCustomEmail
        ? _customEmailController.text.trim()
        : _userEmail;

    if (name.isEmpty) return false;
    if (_selectedInfluencerContentType == null) return false;

    if (phone.isEmpty && email.isEmpty) return false;

    if (phone.isNotEmpty && !RegExp(r'^05[0-9]{8}$').hasMatch(phone)) {
      return false;
    }

    if (email.isNotEmpty && !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
      return false;
    }

    bool hasCompletePair = false;
    for (final r in _socialRows) {
      final p = r.platform?.id.toString() ?? '';
      final u = r.usernameCtrl.text.trim();
      if (p.isNotEmpty && u.isNotEmpty) {
        hasCompletePair = true;
        break;
      }
    }
    if (!hasCompletePair) return false;

    return true;
  }

  void _onAnyFieldChanged() {
    if (!_initialized) return;
    _recomputeValidation();
    final now = _currentSnapshot();
    final changed = now != _initialSnapshot;
    if (isEditMode) {
      setState(() => dirty = changed);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_loading) return;

    try {
      setState(() => _uploadingImage = true);

      final result = await FeqImagePickerService.pickAndUploadImage(
        userId: firebaseAuth.currentUser!.uid,
        storagePath: 'profiles',
      );

      if (result == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      debugPrint('Feq - URL: ${result.downloadUrl}');
      setState(() {
        _imageUrl = result.downloadUrl;
        pickedImage = result.file;
        pickedBytes = result.bytes;
        _uploadingImage = false;
      });

      _onAnyFieldChanged();
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e')));
      }
    }
  }

  Future<void> _prefillFromDb() async {
    try {
      final uid = firebaseAuth.currentUser?.uid;
      if (uid == null) {
        _redirectToLogin();
        return;
      }

      _userEmail = firebaseAuth.currentUser?.email ?? '';

      final usersSnap = await firebaseFirestore.collection('users').where('user_id', isEqualTo: uid).limit(1).get();

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

      final profilesSnap = await firebaseFirestore
          .collection('profiles')
          .where('profile_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (profilesSnap.docs.isNotEmpty) {
        final profileDoc = profilesSnap.docs.first;
        _profileDocId = profileDoc.id;

        InfluencerProfileModel userProfileModel = InfluencerProfileModel.fromJson(profileDoc.data());
        _model.influncerNameTextController!.text = userProfileModel.name;
        _model.influncerDescreptionTextController!.text = userProfileModel.description;

        final savedPhone = userProfileModel.phoneNumber;

        final phoneOwnerStr = profileDoc.data()['phone_owner'] ?? 'personal';
        _phoneOwner = phoneOwnerStr == 'assistant' ? PhoneOwner.assistant : PhoneOwner.personal;

        _model.phoneNumberTextController!.text = savedPhone;

        final emailOwnerStr = profileDoc.data()['email_owner'] ?? 'personal';
        _emailOwner = emailOwnerStr == 'assistant' ? EmailOwner.assistant : EmailOwner.personal;

        final useCustomEmail = profileDoc.data()['use_custom_email'] as bool? ?? false;
        _useCustomEmail = useCustomEmail;

        if (_useCustomEmail) {
          final savedEmail = userProfileModel.contactEmail;
          _customEmailController.text = savedEmail;
        } else {
          _emailOwner = EmailOwner.personal;
          _userEmail = firebaseAuth.currentUser?.email ?? '';
        }

        final rawImageUrl = userProfileModel.profileImage;
        if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
          _imageUrl = rawImageUrl.contains('?')
              ? '${rawImageUrl.split('?').first}?alt=media'
              : '$rawImageUrl?alt=media';
        }

        final influencerSnap = await profileDoc.reference.collection('influencer_profile').limit(1).get();

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
      } else {
        _model.emailTextController!.text = _userEmail;
      }

      final usersRef = firebaseFirestore.collection('users').doc(uid);
      final snapString = await firebaseFirestore
          .collection('social_account')
          .where('influencer_id', isEqualTo: uid)
          .get();
      final snapRef = await firebaseFirestore
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
          usernameCtrl: TextEditingController(text: (m['username'] ?? '').toString()),
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
        dirty = false;
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
    Navigator.of(context).pushNamedAndRemoveUntil(UserLoginPage.routeName, (route) => false);
  }

  Future<void> _saveAll() async {
    _recomputeValidation();

    final phoneError = _validatePhone(_model.phoneNumberTextController?.text);
    final emailError = _validateEmail(null); // Pass null since we check inside the method

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
      final uid = firebaseAuth.currentUser?.uid;
      if (uid == null) return;

      DocumentReference profileRef;
      if (_profileDocId != null) {
        profileRef = firebaseFirestore.collection('profiles').doc(_profileDocId);
      } else {
        profileRef = firebaseFirestore.collection('profiles').doc();
        _profileDocId = profileRef.id;
      }

      final updates = {
        'profile_id': uid,
        'name': _model.influncerNameTextController!.text.trim(),
        'description': _model.influncerDescreptionTextController!.text.trim(),
        'contact_email': _useCustomEmail
            ? _customEmailController.text.trim()
            : _userEmail,
        'phone_number': _model.phoneNumberTextController!.text.trim(),
        'phone_owner': _phoneOwner.name,
        'email_owner': _useCustomEmail ? _emailOwner.name : 'personal',
        'use_custom_email': _useCustomEmail,
      };

      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final cleanUrl = _imageUrl!.contains('?') ? _imageUrl!.split('?').first : _imageUrl!;
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

      final socialCol = firebaseFirestore.collection('social_account');
      final usersRef = firebaseFirestore.collection('users').doc(uid);

      final oldSnapString = await socialCol.where('influencer_id', isEqualTo: uid).get();
      final oldSnapRef = await socialCol.where('influencer_id', isEqualTo: usersRef).get();

      final batch = firebaseFirestore.batch();
      for (final d in [...oldSnapString.docs, ...oldSnapRef.docs]) {
        batch.delete(d.reference);
      }

      for (final row in _socialRows) {
        final platformId = row.platform?.id ?? '';
        final platformEmpty = row.platform?.id == null || row.platform!.id.toString().isEmpty;
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
        dirty = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSetupMode ? 'تم الحفظ بنجاح' : 'تم التحديث بنجاح')),
        );

        if (isSetupMode) {
          final user = firebaseAuth.currentUser!;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', uid);
          await prefs.setString('user_type', 'influencer');
          await prefs.setString('email', user.email!);
          await prefs.setString('account_status', 'active');
          if (mounted) {
            Navigator.pushReplacementNamed(context, MainScreen.routeName);
          }
        } else {
          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
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

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^05[0-9]{8}$').hasMatch(v)) {
      return 'رقم الجوال يجب أن يكون 05XXXXXXXX';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = _useCustomEmail
        ? _customEmailController.text.trim()
        : _userEmail;

    if (v.isEmpty) return null;
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
      appBar: FeqAppBar(
        title: isSetupMode ? 'إنشاء الملف الشخصي' : 'تعديل الملف الشخصي',
        showBack: isEditMode,
        backRoute: InfluncerProfileWidget.routeName,
      ),
      body: SafeArea(
        top: true,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: t.bodyMedium.copyWith(color: t.primaryText)),
              )
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
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: t.containers,
                                boxShadow: const [
                                  BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2)),
                                ],
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: const AlignmentDirectional(0, -1),
                                            child: FeqImagePickerWidget(
                                              initialImageUrl: _imageUrl,
                                              isUploading: _uploadingImage,
                                              onTap: _pickAndUploadImage,
                                              size: 100,
                                              onImagePicked: (url, file, bytes) {
                                                setState(() {
                                                  _imageUrl = url;
                                                  pickedImage = file;
                                                  pickedBytes = bytes;
                                                });
                                              },
                                            ),
                                          ),
                                          Align(
                                            alignment: const AlignmentDirectional(0, -1),
                                            child: Padding(
                                              padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 40),
                                              child: Opacity(
                                                opacity: (_uploadingImage || _loading) ? 0.5 : 1,
                                                child: GestureDetector(
                                                  onTap: (_uploadingImage || _loading) ? null : _pickAndUploadImage,
                                                  child: Text(
                                                    'تغيير صورة الحساب',
                                                    style: t.bodyMedium.override(
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
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                                      child: FeqLabeledTextField(
                                        label: 'الاسم ',
                                        controller: _model.influncerNameTextController,
                                        focusNode: _model.influncerNameFocusNode,
                                        textCapitalization: TextCapitalization.words,
                                        width: double.infinity,
                                        isError: _showErrors && _nameEmpty,
                                        errorText: _showErrors && _nameEmpty ? 'يرجى إدخال الاسم.' : null,
                                        decoration: inputDecoration(context, isError: _showErrors && _nameEmpty),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                                      child: FeqLabeled(
                                        'نوع المحتوى',
                                        errorText: _showErrors && _contentEmpty ? 'يرجى اختيار نوع المحتوى.' : null,
                                        child: FeqSearchableDropdown<FeqDropDownList>(
                                          items: _influencerContentTypes,
                                          value: _selectedInfluencerContentType,
                                          onChanged: (v) {
                                            setState(() => _selectedInfluencerContentType = v);
                                            _onAnyFieldChanged();
                                          },
                                          hint: 'اختر أو ابحث...',
                                          isError: _showErrors && _contentEmpty,
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                                          border: Border.all(color: t.secondary),
                                        ),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Align(
                                                    alignment: const AlignmentDirectional(1, 0),
                                                    child: FlutterFlowIconButton(
                                                      borderRadius: 8,
                                                      buttonSize: 50,
                                                      icon: Icon(
                                                        Icons.add_circle,
                                                        color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          final r = _SocialRow();
                                                          _attachSocialRowListeners(r);
                                                          _socialRows.add(r);
                                                        });
                                                        _onAnyFieldChanged();
                                                      },
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment: const AlignmentDirectional(1, -1),
                                                    child: Padding(
                                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 20, 0),
                                                      child: Text(
                                                        'منصاتك في مواقع التواصل الاجتماعي',
                                                        textAlign: TextAlign.end,
                                                        style: t.bodyMedium.override(
                                                          fontFamily: 'Inter',
                                                          color: t.primaryText,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsetsDirectional.fromSTEB(35, 0, 20, 5),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 0),
                                                    child: FeqLabeled('اسم الحساب في المنصة'),
                                                  ),
                                                  Align(
                                                    alignment: const AlignmentDirectional(1, -1),
                                                    child: FeqLabeled('اسم المنصة'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                              child: Column(
                                                children: List.generate(_socialRows.length, (i) {
                                                  final row = _socialRows[i];
                                                  final isFirstRow = i == 0;
                                                  final platformEmpty =
                                                      row.platform?.id == null || row.platform!.id.toString().isEmpty;
                                                  final usernameEmpty = row.usernameCtrl.text.trim().isEmpty;
                                                  final showPlatformErr =
                                                      _showErrors &&
                                                      isFirstRow &&
                                                      _socialsRequireError &&
                                                      platformEmpty;
                                                  final showUsernameErr =
                                                      _showErrors &&
                                                      isFirstRow &&
                                                      _socialsRequireError &&
                                                      usernameEmpty;

                                                  return Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Align(
                                                        alignment: const AlignmentDirectional(1, 0),
                                                        child: Padding(
                                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                                          child: FlutterFlowIconButton(
                                                            borderRadius: 8,
                                                            buttonSize: 50,
                                                            icon: Icon(
                                                              Icons.minimize_outlined,
                                                              color: t
                                                                  .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                              size: 20,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                _socialRows.removeAt(i);
                                                                if (_socialRows.isEmpty) {
                                                                  final r = _SocialRow();
                                                                  _attachSocialRowListeners(r);
                                                                  _socialRows.add(r);
                                                                }
                                                              });
                                                              _onAnyFieldChanged();
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 20, 0),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              TextFormField(
                                                                controller: row.usernameCtrl,
                                                                textCapitalization: TextCapitalization.none,
                                                                decoration: platformInputDecoration(
                                                                  context,
                                                                  isError: showUsernameErr,
                                                                ),
                                                                style: t.bodyMedium.copyWith(color: t.primaryText),
                                                                textAlign: TextAlign.end,
                                                              ),
                                                              if (row.platform != null &&
                                                                  row.usernameCtrl.text.trim().isNotEmpty)
                                                                Padding(
                                                                  padding: const EdgeInsets.only(top: 4),
                                                                  child: InkWell(
                                                                    onTap: () {
                                                                      final url =
                                                                          'https://${row.platform!.domain}${row.usernameCtrl.text.trim()}';
                                                                      launchUrl(Uri.parse(url));
                                                                    },
                                                                    child: Text(
                                                                      '${row.platform!.domain}${row.usernameCtrl.text.trim()}',
                                                                      style: const TextStyle(
                                                                        color: Colors.blue,
                                                                        decoration: TextDecoration.underline,
                                                                      ),
                                                                      textAlign: TextAlign.end,
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (showUsernameErr)
                                                                const Padding(
                                                                  padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                                                  child: Text(
                                                                    'يرجى إدخال اسم الحساب.',
                                                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 20, 0),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              FeqSearchableDropdown<FeqDropDownList>(
                                                                items: _socialPlatforms,
                                                                value: row.platform,
                                                                onChanged: (v) {
                                                                  setState(() => row.platform = v);
                                                                  _onAnyFieldChanged();
                                                                },
                                                                hint: 'اختر المنصة',
                                                                isError: showPlatformErr,
                                                              ),
                                                              if (showPlatformErr)
                                                                const Padding(
                                                                  padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                                                  child: Text(
                                                                    'يرجى اختيار المنصة.',
                                                                    style: TextStyle(color: Colors.red, fontSize: 12),
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

                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                                      child: FeqLabeledTextField(
                                        label: 'النبذة الشخصية',
                                        controller: _model.influncerDescreptionTextController,
                                        focusNode: _model.influncerDescreptionFocusNode,
                                        textCapitalization: TextCapitalization.sentences,
                                        width: double.infinity,
                                        maxLines: 3,
                                        decoration: inputDecoration(context),
                                      ),
                                    ),

                                    // Contact Information Section
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                                      child: FeqLabeled('معلومات التواصل'),
                                    ),

                                    // Phone Section
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          FeqLabeledTextField(
                                            label: 'رقم الجوال ',
                                            required: false,
                                            controller: _model.phoneNumberTextController,
                                            focusNode: _model.phoneNumberFocusNode,
                                            keyboardType: TextInputType.phone,
                                            decoration: inputDecoration(
                                              context,
                                              isError: _showErrors && _bothContactsEmpty,
                                            ).copyWith(hintText: 'رقم الجوال'),
                                          ),
                                          // Phone Radio Buttons
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() => _phoneOwner = PhoneOwner.personal);
                                                    _onAnyFieldChanged();
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'رقم الجوال الخاص بي',
                                                        style: t.bodyMedium.override(
                                                          fontFamily: 'Inter',
                                                          color: t.primaryText,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      RadioMenuButton<PhoneOwner>(
                                                        value: PhoneOwner.personal,
                                                        groupValue: _phoneOwner,
                                                        onChanged: (value) {
                                                          setState(() => _phoneOwner = value!);
                                                          _onAnyFieldChanged();
                                                        },
                                                        child: const SizedBox.shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() => _phoneOwner = PhoneOwner.assistant);
                                                    _onAnyFieldChanged();
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'رقم الجوال الخاص بمنسق أعمالي',
                                                        style: t.bodyMedium.override(
                                                          fontFamily: 'Inter',
                                                          color: t.primaryText,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      RadioMenuButton<PhoneOwner>(
                                                        value: PhoneOwner.assistant,
                                                        groupValue: _phoneOwner,
                                                        onChanged: (value) {
                                                          setState(() => _phoneOwner = value!);
                                                          _onAnyFieldChanged();
                                                        },
                                                        child: const SizedBox.shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ==================== EMAIL SECTION ====================
                                    // Email Section
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // Display field (changes based on selection)
                                          if (!_useCustomEmail)
                                            // Show logged-in email as read-only
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                FeqLabeled('البريد الإلكتروني', required: false),
                                                Padding(
                                                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                                                  child: Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: t.containers,
                                                        border: Border.all(color: t.secondary, width: 2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        _userEmail,
                                                        textDirection: TextDirection.rtl,
                                                        style: FlutterFlowTheme.of(context)
                                                            .bodyMedium
                                                            .override(fontFamily: 'Inter', color: FlutterFlowTheme.of(context).primaryText),
                                                      )
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                          // Show input field for custom email
                                            FeqLabeledTextField(
                                              label: 'البريد الإلكتروني',
                                              required: false,
                                              controller: _customEmailController,
                                              focusNode: _model.emailFocusNode,
                                              keyboardType: TextInputType.emailAddress,
                                              decoration: inputDecoration(
                                                context,
                                                isError: _showErrors && _bothContactsEmpty,
                                              ).copyWith(hintText: 'أدخل البريد الإلكتروني'),
                                            ),

                                          // Email Radio Buttons
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _useCustomEmail = false;
                                                      _emailOwner = EmailOwner.personal;
                                                      _customEmailController.clear();
                                                    });
                                                    _onAnyFieldChanged();
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'البريد الإلكتروني الخاص بي',
                                                        style: t.bodyMedium.override(
                                                          fontFamily: 'Inter',
                                                          color: t.primaryText,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      RadioMenuButton<bool>(
                                                        value: false,
                                                        groupValue: _useCustomEmail,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _useCustomEmail = value ?? false;
                                                            _emailOwner = EmailOwner.personal;
                                                            _customEmailController.clear();
                                                          });
                                                          _onAnyFieldChanged();
                                                        },
                                                        child: const SizedBox.shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _useCustomEmail = true;
                                                      _customEmailController.clear();
                                                    });
                                                    _onAnyFieldChanged();
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'إضافة بريد إلكتروني مختلف',
                                                        style: t.bodyMedium.override(
                                                          fontFamily: 'Inter',
                                                          color: t.primaryText,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      RadioMenuButton<bool>(
                                                        value: true,
                                                        groupValue: _useCustomEmail,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _useCustomEmail = value ?? false;
                                                            _customEmailController.clear();
                                                          });
                                                          _onAnyFieldChanged();
                                                        },
                                                        child: const SizedBox.shrink(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (_useCustomEmail) ...[
                                                  const SizedBox(height: 12),
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 32),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() => _emailOwner = EmailOwner.personal);
                                                            _onAnyFieldChanged();
                                                          },
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                'الخاص بي',
                                                                style: t.bodySmall.override(
                                                                  fontFamily: 'Inter',
                                                                  color: t.primaryText,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              RadioMenuButton<EmailOwner>(
                                                                value: EmailOwner.personal,
                                                                groupValue: _emailOwner,
                                                                onChanged: (value) {
                                                                  setState(() => _emailOwner = value!);
                                                                  _onAnyFieldChanged();
                                                                },
                                                                child: const SizedBox.shrink(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() => _emailOwner = EmailOwner.assistant);
                                                            _onAnyFieldChanged();
                                                          },
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                'الخاص بمنسق أعمالي',
                                                                style: t.bodySmall.override(
                                                                  fontFamily: 'Inter',
                                                                  color: t.primaryText,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              RadioMenuButton<EmailOwner>(
                                                                value: EmailOwner.assistant,
                                                                groupValue: _emailOwner,
                                                                onChanged: (value) {
                                                                  setState(() => _emailOwner = value!);
                                                                  _onAnyFieldChanged();
                                                                },
                                                                child: const SizedBox.shrink(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Error message for contact info
                                    if (_showErrors && _bothContactsEmpty)
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 24, 10),
                                        child: Text(
                                          'يرجى إدخال رقم الجوال أو البريد الإلكتروني.',
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),

                                    // Buttons
                                    if (isEditMode)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
                                            child: FFButtonWidget(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                              },
                                              text: 'إلغاء',
                                              options: FFButtonOptions(
                                                width: 90,
                                                height: 40,
                                                color: t.secondary,
                                                textStyle: t.titleMedium.override(
                                                  fontFamily: 'Inter Tight',
                                                  color: t.containers,
                                                  fontSize: 18,
                                                ),
                                                elevation: 2,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
                                            child: AnimatedBuilder(
                                              animation: _shakeCtrl,
                                              builder: (context, child) =>
                                                  Transform.translate(offset: Offset(_shakeOffset(), 0), child: child),
                                              child: FFButtonWidget(
                                                onPressed: _isFormValid ? () => _saveAll() : null,
                                                text: 'تحديث',
                                                options: FFButtonOptions(
                                                  width: 200,
                                                  height: 40,
                                                  color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                  textStyle: t.titleMedium.override(
                                                    fontFamily: 'Inter',
                                                    color: t.containers,
                                                  ),
                                                  elevation: 2,
                                                  borderRadius: BorderRadius.circular(12),
                                                  disabledColor: Colors.grey,
                                                  disabledTextColor: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
                                        child: AnimatedBuilder(
                                          animation: _shakeCtrl,
                                          builder: (context, child) =>
                                              Transform.translate(offset: Offset(_shakeOffset(), 0), child: child),
                                          child: FFButtonWidget(
                                            onPressed: _isFormValid ? () => _saveAll() : null,
                                            text: 'إنشاء',
                                            options: FFButtonOptions(
                                              width: 200,
                                              height: 40,
                                              color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                              textStyle: t.titleMedium.override(
                                                fontFamily: 'Inter',
                                                color: t.containers,
                                              ),
                                              elevation: 2,
                                              borderRadius: BorderRadius.circular(12),
                                              disabledColor: Colors.grey,
                                              disabledTextColor: Colors.white70,
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
  FeqDropDownList? platform;
  final TextEditingController usernameCtrl;

  _SocialRow({this.platform, TextEditingController? usernameCtrl})
    : usernameCtrl = usernameCtrl ?? TextEditingController();

  void dispose() {
    usernameCtrl.dispose();
  }
}
