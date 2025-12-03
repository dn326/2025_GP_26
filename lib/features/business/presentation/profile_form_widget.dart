import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/features/business/models/profile_data_model.dart';
import 'package:elan_flutterproject/features/business/models/profile_form_model.dart';
import 'package:elan_flutterproject/features/business/presentation/profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/utils/enum_profile_mode.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../main_screen.dart';
import '../../../features/login_and_signup/user_login.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

InputDecoration businessInputDecoration(BuildContext context, {bool isError = false}) {
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

InputDecoration businessPlatformInputDecoration(BuildContext context, {bool isError = false}) {
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

class BusinessProfileFormWidget extends StatefulWidget {
  final ProfileMode mode;

  const BusinessProfileFormWidget({super.key, this.mode = ProfileMode.edit});

  static const String routeNameEdit = 'business-profile-edit';
  static const String routePathEdit = '/$routeNameEdit';

  @override
  State<BusinessProfileFormWidget> createState() => _BusinessProfileFormWidgetState();
}

class _BusinessProfileFormWidgetState extends State<BusinessProfileFormWidget> with SingleTickerProviderStateMixin {
  late BusinessProfileFormModel _model;
  
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Firestore doc id
  String? _profileDocId;
  String? commercialRegisterNumber;
  String? commercialRegisterExpiry;
  String? commercialRegisterStatus;

  bool commercialRegisterRequiredError = false;
  bool commercialRegisterFormatError = false;
  bool commercialRegisterFetchingError = false;
  bool commercialRegisterFetched = false;
  bool commercialRegisterIsExpiringSoon = false;
  bool isCommercialRegisterVerified = false;
  bool _showLicenseErrors = false;

  File? pickedImage;
  Uint8List? pickedBytes;
  String? _imageUrl;

  bool _loading = true;
  bool _uploadingImage = false;
  String? _error;

  // Social rows
  List<_SocialRow> _socialRows = [_SocialRow()];

  bool _initialized = false;
  String _initialSnapshot = '';
  bool dirty = false;
  String _userEmail = '';

  bool _nameEmpty = false;
  bool _industryEmpty = false;
  bool _contactsEmpty = false;
  bool _socialsRequireError = false;
  bool _showErrors = false;

  late AnimationController _shakeCtrl;

  PhoneOwner _phoneOwner = PhoneOwner.personal;
  EmailOwner _emailOwner = EmailOwner.personal;

  bool _useCustomEmail = false;
  final TextEditingController _customEmailController = TextEditingController();

  late List<FeqDropDownList> _businessIndustries;
  late List<FeqDropDownList> _socialPlatforms;

  FeqDropDownList? _selectedBusinessIndustry;

  bool get isSetupMode => widget.mode == ProfileMode.setup;
  bool get isEditMode => widget.mode == ProfileMode.edit;

  @override
  void initState() {
    super.initState();
      _model = createModel(context, () => BusinessProfileFormModel());

    _businessIndustries = FeqDropDownListLoader.instance.businessIndustries;
    _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;

    _model.businessNameTextController ??= TextEditingController();
    _model.businessNameFocusNode ??= FocusNode();

    _model.businessDescreptionTextController ??= TextEditingController();
    _model.businessDescreptionFocusNode ??= FocusNode();

    _model.businessWebsiteTextController ??= TextEditingController();
    _model.businessWebsiteFocusNode ??= FocusNode();

    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.commercialRegisterTextController ??= TextEditingController();
    _model.commercialRegisterFocusNode ??= FocusNode();

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
      _model.businessNameTextController,
      _model.businessDescreptionTextController,
      _model.businessWebsiteTextController,
      _model.phoneNumberTextController,
      _model.emailTextController,
      _model.commercialRegisterTextController,
      _customEmailController,
    ]) {
      c?.addListener(_onAnyFieldChanged);
    }
  }

  void _attachSocialRowListeners(_SocialRow row) {
    row.usernameCtrl.addListener(_onAnyFieldChanged);
  }

  String _currentSnapshot() {
    final socials = _socialRows
        .map((r) => {
              'p': r.platform?.id ?? '',
              'u': r.usernameCtrl.text.trim(),
            })
        .toList();

    return {
      'name': _model.businessNameTextController?.text.trim() ?? '',
      'content_id': _selectedBusinessIndustry?.id ?? 0,
      'desc': _model.businessDescreptionTextController?.text.trim() ?? '',
      'phone': _model.phoneNumberTextController?.text.trim() ?? '',
      'phone_owner': _phoneOwner.name,
      'email': _model.emailTextController?.text.trim() ?? '',
      'email_owner': _emailOwner.name,
      'website': _model.businessWebsiteTextController?.text.trim() ?? '',
      'img': _imageUrl ?? '',
      'socials': socials,
    }.toString();
  }

  void _recomputeValidation() {
    final name = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _useCustomEmail
        ? _customEmailController.text.trim()
        : _userEmail;

    _nameEmpty = name.isEmpty;
    _industryEmpty = _selectedBusinessIndustry == null;
    _contactsEmpty = phone.isEmpty && email.isEmpty;

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

    final license = _model.commercialRegisterTextController?.text.trim() ?? '';
    commercialRegisterRequiredError = license.isEmpty;
    commercialRegisterFormatError =
        license.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(license);

  }
  

  bool get _isFormValid {
    final name = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _useCustomEmail
        ? _customEmailController.text.trim()
        : _userEmail;

    if (name.isEmpty) return false;
    if (_selectedBusinessIndustry == null) return false;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e')));
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
      if (userType != 'business') {
        setState(() {
          _loading = false;
          _error = 'الحساب ليس من نوع صاحب عمل.';
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

        BusinessProfileDataModel userProfileModel = BusinessProfileDataModel.fromJson(profileDoc.data());

        _model.businessNameTextController!.text = userProfileModel.name;
        _model.businessDescreptionTextController!.text = userProfileModel.description!;

        final savedPhone = userProfileModel.phoneNumber;

        final phoneOwnerStr = profileDoc.data()['phone_owner'] ?? 'personal';
        _phoneOwner = phoneOwnerStr == 'assistant' ? PhoneOwner.assistant : PhoneOwner.personal;

        _model.phoneNumberTextController!.text = savedPhone!;

        final emailOwnerStr = profileDoc.data()['email_owner'] ?? 'personal';
        _emailOwner = emailOwnerStr == 'assistant' ? EmailOwner.assistant : EmailOwner.personal;

        final useCustomEmail = profileDoc.data()['use_custom_email'] as bool? ?? false;
        _useCustomEmail = useCustomEmail;

        if (_useCustomEmail) {
          final savedEmail = userProfileModel.contactEmail;
          _customEmailController.text = savedEmail!;
        } else {
          _emailOwner = EmailOwner.personal;
          _userEmail = firebaseAuth.currentUser?.email ?? '';
        }

        final rawImageUrl = userProfileModel.profileImageUrl;
        if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
          _imageUrl = rawImageUrl.contains('?')
              ? '${rawImageUrl.split('?').first}?alt=media'
              : '$rawImageUrl?alt=media';
        }


          final industryTypeRaw = profileDoc.data()['business_industry_id'];
          int industrytId = 0;

          if (industryTypeRaw is int) {
            industrytId = industryTypeRaw;
          }

          _selectedBusinessIndustry = _businessIndustries.firstWhere(
            (c) => c.id == industrytId,
            orElse: () => _businessIndustries.first,
          );

        _model.businessWebsiteTextController!.text = userProfileModel.website ?? '';

        // Social media array
        final socials = (profileDoc.data()['social_media'] as List?) ?? [];
        final rows = socials.map<_SocialRow>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final platformStr = (m['platform'] ?? '').toString();
          final usernameStr = (m['username'] ?? '').toString();

          final plat = _socialPlatforms.firstWhere(
            (p) => p.nameEn.toLowerCase() == platformStr.toLowerCase(),
            orElse: () => _socialPlatforms.first,
          );

          final row = _SocialRow(
            platform: plat,
            usernameCtrl: TextEditingController(text: usernameStr),
          );
          _attachSocialRowListeners(row);
          return row;
        }).toList();

        if (rows.isNotEmpty) {
          _socialRows = rows;
        } else {
          _attachSocialRowListeners(_socialRows.first);
        }
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
    Navigator.of(context)
        .pushNamedAndRemoveUntil(UserLoginPage.routeName, (route) => false);
  }

  Future<void> _saveAll() async {
    _recomputeValidation();

    final phoneError = _validatePhone(_model.phoneNumberTextController?.text);
    final emailError = _validateEmail(_useCustomEmail ? _customEmailController.text : _userEmail);
    final websiteError = _validateWebsite(_model.businessWebsiteTextController?.text);

    if (_nameEmpty ||
        _industryEmpty ||
        _contactsEmpty ||
        _socialsRequireError ||
        phoneError != null ||
        emailError != null ||
        websiteError != null) {
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

      if (websiteError != null) {
        errors.add(
          TextSpan(
            text: '$websiteError\n',
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
        profileRef = firebaseFirestore
            .collection('profiles')
            .doc(_profileDocId);
      } else {
        profileRef =
            firebaseFirestore.collection('profiles').doc();
        _profileDocId = profileRef.id;
      }

      final updates = <String, dynamic>{
        'profile_id': uid,
        'name': _model.businessNameTextController!.text.trim(),
        'business_industry_id': _selectedBusinessIndustry?.id,
        'business_industry_name': _selectedBusinessIndustry?.nameAr,
        'website': _model.businessWebsiteTextController!.text.trim(),
        'description': _model.businessDescreptionTextController!.text.trim(),
        'contact_email': _useCustomEmail? _customEmailController.text.trim() : _userEmail,
        'phone_number': _model.phoneNumberTextController!.text.trim(),
        'phone_owner': _phoneOwner.name,
        'email_owner': _useCustomEmail ? _emailOwner.name : 'personal',
        'use_custom_email': _useCustomEmail,
      };

      if (isSetupMode) {
        final usersRef = firebaseFirestore.collection('users').doc(uid);
        
        await usersRef.set({
          'commercial_register_expiry_date': commercialRegisterExpiry ?? '',
          'commercial_register_number': commercialRegisterNumber ?? '',
          'verified': isCommercialRegisterVerified,
          'commercial_register_is_expiring': commercialRegisterIsExpiringSoon,
        }, SetOptions(merge: true));
      }

      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final cleanUrl =
            _imageUrl!.contains('?') ? _imageUrl!.split('?').first : _imageUrl!;
        updates['profile_image'] = cleanUrl;
      } else {
        updates['profile_image'] = null;
      }

      final socialList = <Map<String, dynamic>>[];
      for (final row in _socialRows) {
        final platform = row.platform;
        final username = row.usernameCtrl.text.trim();

        final platformEmpty =
            platform == null || platform.id.toString().isEmpty;
        if (platformEmpty && username.isEmpty) continue;

        socialList.add({
          'platform': (platform?.nameEn ?? '').toString().toLowerCase(),
          'username': username,
        });
      }
      updates['social_media'] = socialList;

      await profileRef.set(updates, SetOptions(merge: true));

      if (mounted) {
        _initialSnapshot = _currentSnapshot();
        dirty = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSetupMode ? 'تم الحفظ بنجاح' : 'تم التحديث بنجاح'),
          ),
        );

        if (isSetupMode) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, UserLoginPage.routeName);
          }
        } else {
          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        }

      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
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
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  String? _validateWebsite(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return null;

    final urlPattern = r'^(https?:\/\/)[\w\-\.]+\.\w{2,}.*$';

    if (!RegExp(urlPattern).hasMatch(v)) {
      return 'رابط الموقع الإلكتروني غير صحيح. يرجى إدخال رابط يبدأ بـ http أو https.';
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
        title: isSetupMode ? 'إنشاء الملف التعريفي' : 'تعديل الملف التعريفي',
        showBack: true,
        backRoute: BusinessProfileScreen.routeName,
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
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                    child: Container(
                      decoration: BoxDecoration(color: t.backgroundElan),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0, 16, 0, 0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        16, 16, 16, 16),
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
                                            0, 16, 0, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  20, 5, 20, 0),
                                          child: FeqLabeledTextField(
                                            label: 'اسم الشركة',
                                            controller:
                                                _model.businessNameTextController,
                                            focusNode: _model.businessNameFocusNode,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            width: double.infinity,
                                            isError: _showErrors &&
                                                _nameEmpty,
                                            errorText: _showErrors &&
                                                    _nameEmpty
                                                ? 'يرجى إدخال الاسم.'
                                                : null,
                                            decoration:
                                                businessInputDecoration(
                                              context,
                                              isError: _showErrors &&
                                                  _nameEmpty,
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  20, 5, 20, 0),
                                          child: FeqLabeled(
                                            'نوع المجال',
                                            errorText: _showErrors &&
                                                    _industryEmpty
                                                ? 'يرجى اختيار نوع المجال.'
                                                : null,
                                            child: FeqSearchableDropdown<
                                                FeqDropDownList>(
                                              items: _businessIndustries,
                                              value:
                                                  _selectedBusinessIndustry,
                                              onChanged: (v) {
                                                setState(() =>
                                                    _selectedBusinessIndustry =
                                                        v);
                                                _onAnyFieldChanged();
                                              },
                                              hint: 'اختر أو ابحث...',
                                              isError: _showErrors &&
                                                  _industryEmpty,
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  20, 5, 20, 0),
                                          child: FeqLabeledTextField(
                                            label: 'الموقع الإلكتروني',
                                            required: false,
                                            controller: _model.businessWebsiteTextController,
                                            focusNode: _model.businessWebsiteFocusNode,
                                            textCapitalization:
                                                TextCapitalization.none,
                                            width: double.infinity,
                                            decoration:
                                                businessInputDecoration(
                                              context,
                                              isError: false,
                                            ).copyWith(
                                              hintText:
                                                  'مثال: https://example.com',
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  20, 20, 20, 20),
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
                                                          0, 0, 0, 16),
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
                                                                1, 0),
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
                                                                  r);
                                                              _socialRows
                                                                  .add(r);
                                                            });
                                                            _onAnyFieldChanged();
                                                          },
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment:
                                                            const AlignmentDirectional(
                                                                1, -1),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                  0, 0, 20, 0),
                                                          child: Text(
                                                            'منصاتك في مواقع التواصل الاجتماعي',
                                                            textAlign:
                                                                TextAlign.end,
                                                            style: t
                                                                .bodyMedium
                                                                .override(
                                                              fontFamily:
                                                                  'Inter',
                                                              color: t
                                                                  .primaryText,
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
                                                          35, 0, 20, 5),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                0, 0, 10, 0),
                                                        child: FeqLabeled(
                                                          'اسم الحساب في المنصة',
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment:
                                                            const AlignmentDirectional(
                                                                1, -1),
                                                        child: FeqLabeled(
                                                          'اسم المنصة',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0, 0, 0, 16),
                                                  child: Column(
                                                    children: List.generate(
                                                        _socialRows.length,
                                                        (i) {
                                                      final row =
                                                          _socialRows[i];
                                                      final isFirstRow =
                                                          i == 0;
                                                      final platformEmpty =
                                                          row.platform?.id ==
                                                                  null ||
                                                              row
                                                                  .platform!.id
                                                                  .toString()
                                                                  .isEmpty;
                                                      final usernameEmpty = row
                                                          .usernameCtrl.text
                                                          .trim()
                                                          .isEmpty;
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
                                                                    1, 0),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                      0,
                                                                      0,
                                                                      0,
                                                                      16),
                                                              child:
                                                                  FlutterFlowIconButton(
                                                                borderRadius:
                                                                    8,
                                                                buttonSize: 50,
                                                                icon: Icon(
                                                                  Icons
                                                                      .minimize_outlined,
                                                                  color: t
                                                                      .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                                  size: 20,
                                                                ),
                                                                onPressed:
                                                                    () {
                                                                  setState(
                                                                      () {
                                                                    _socialRows
                                                                        .removeAt(
                                                                            i);
                                                                    if (_socialRows
                                                                        .isEmpty) {
                                                                      final r =
                                                                          _SocialRow();
                                                                      _attachSocialRowListeners(
                                                                          r);
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
                                                                      0),
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
                                                                        businessPlatformInputDecoration(
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
                                                                      row.usernameCtrl
                                                                          .text
                                                                          .trim()
                                                                          .isNotEmpty)
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              4),
                                                                      child:
                                                                          InkWell(
                                                                        onTap:
                                                                            () {
                                                                          final url =
                                                                              'https://${row.platform!.domain}/${row.usernameCtrl.text.trim()}';
                                                                          launchUrl(
                                                                            Uri.parse(url),
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
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0,
                                                                          6,
                                                                          4,
                                                                          0),
                                                                      child:
                                                                          Text(
                                                                        'يرجى إدخال اسم الحساب.',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red,
                                                                            fontSize: 12),
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
                                                                      0),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  FeqSearchableDropdown<
                                                                      FeqDropDownList>(
                                                                    items:
                                                                        _socialPlatforms,
                                                                    value: row
                                                                        .platform,
                                                                    onChanged:
                                                                        (v) {
                                                                      setState(
                                                                          () =>
                                                                              row.platform = v);
                                                                      _onAnyFieldChanged();
                                                                    },
                                                                    hint:
                                                                        'اختر المنصة',
                                                                    isError:
                                                                        showPlatformErr,
                                                                  ),
                                                                  if (showPlatformErr)
                                                                    const Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0,
                                                                          6,
                                                                          4,
                                                                          0),
                                                                      child:
                                                                          Text(
                                                                        'يرجى اختيار المنصة.',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red,
                                                                            fontSize: 12),
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
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  20, 5, 20, 0),
                                          child: FeqLabeledTextField(
                                            label: 'نبذة تعريفية',
                                            required: false,
                                            controller:
                                                _model.businessDescreptionTextController,
                                            focusNode: _model.businessDescreptionFocusNode,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            width: double.infinity,
                                            maxLines: 3,
                                            decoration:
                                                businessInputDecoration(
                                              context,
                                              isError: false,
                                            ),
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
                                            decoration: businessInputDecoration(
                                              context,
                                              isError: _showErrors && _contactsEmpty,
                                            ).copyWith(hintText: '05XXXXXXXX'),
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
                                              decoration: businessInputDecoration(
                                                context,
                                                isError: _showErrors && _contactsEmpty,
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
                                    if (_showErrors && _contactsEmpty)
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 24, 10),
                                        child: Text(
                                          'يرجى إدخال رقم الجوال أو البريد الإلكتروني.',
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),

                                    if(isSetupMode) ...[                     
                                    FeqLabeled(
                                      'رقم السجل التجاري الموحد',
                                      required: true,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // ===== TextField =====
                                                TextFormField(
                                                  controller: _model.commercialRegisterTextController,
                                                  focusNode: _model.commercialRegisterFocusNode,
                                                  keyboardType: TextInputType.number,
                                                  textInputAction: TextInputAction.done,
                                                  decoration: businessInputDecoration(
                                                    context,
                                                    isError: _showLicenseErrors &&
                                                        (commercialRegisterRequiredError ||
                                                        commercialRegisterFormatError ||
                                                        commercialRegisterFetchingError),
                                                  ),
                                                  style: t.bodyLarge.copyWith(color: t.primaryText),
                                                  textAlign: TextAlign.start,
                                                ),

                                                // ===== Error: Required =====
                                                if (_showLicenseErrors && commercialRegisterRequiredError)
                                                  const Padding(
                                                    padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                                    child: Text(
                                                      'يرجى إدخال الرقم الموحد للسجل التجاري.',
                                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                                    ),
                                                  ),

                                                // ===== Error: Format (must be 10 digits) =====
                                                if (_showLicenseErrors && commercialRegisterFormatError)
                                                  const Padding(
                                                    padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                                    child: Text(
                                                      'رقم السجل يجب أن يكون 10 أرقام صحيحة.',
                                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                                    ),
                                                  ),

                                                // ===== Error: Could not fetch / invalid =====
                                                if (_showLicenseErrors && commercialRegisterFetchingError)
                                                  const Padding(
                                                    padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                                    child: Text(
                                                      'رقم السجل غير صحيح أو غير موجود.',
                                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // ===== Verify Button =====
                                          ElevatedButton(
                                            onPressed: _fetchLicenseData,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: t.secondaryButtonsOnLight,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'تحقق',
                                              style: TextStyle(color: t.primaryText, fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ===== SHOW Fetched License Data =====
                                    if (commercialRegisterFetched) ...[
                                      const SizedBox(height: 12),

                                      // License Status
                                      FeqLabeled(
                                        'حالة السجل',
                                        required: false,
                                        child: TextFormField(
                                          initialValue: commercialRegisterStatus ?? '',
                                          enabled: false,
                                          decoration:businessInputDecoration(context).copyWith(
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: t.secondary),
                                            ),
                                          ),
                                          style: t.bodyLarge.copyWith(color: t.tertiaryText),
                                          textAlign: TextAlign.start,
                                        ),
                                      ),

                                      // License Expiry Date
                                      FeqLabeled(
                                        'تاريخ انتهاء السجل',
                                        required: false,
                                        child: TextFormField(
                                          initialValue: commercialRegisterExpiry ?? '',
                                          enabled: false,
                                          decoration: businessInputDecoration(context).copyWith(
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: t.secondary),
                                            ),
                                          ),
                                          style: t.bodyLarge.copyWith(color: t.tertiaryText),
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                    ],
                                  ],
                                    // Buttons
                                    if (isEditMode)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(0, 40, 0, 24),
                                            child: AnimatedBuilder(
                                              animation: _shakeCtrl,
                                              builder: (context, child) =>
                                                  Transform.translate(offset: Offset(_shakeOffset(), 0), child: child),
                                              child: FFButtonWidget(
                                                onPressed: _isFormValid ? () => _saveAll() : null,
                                                text: 'تحديث',
                                                options: FFButtonOptions(
                                                  width: 430,
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
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 40, 0, 24),
                                          child: AnimatedBuilder(
                                            animation: _shakeCtrl,
                                            builder: (context, child) =>
                                                Transform.translate(offset: Offset(_shakeOffset(), 0), child: child),
                                            child: FFButtonWidget(
                                              onPressed: _isFormValid ? () => _saveAll() : null,
                                              text: 'إنشاء',
                                              options: FFButtonOptions(
                                                width: 430,
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
                                      )
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

  Future<void> _fetchLicenseData() async {
    setState(() {
      _showLicenseErrors = true; 
      commercialRegisterRequiredError = false;
      commercialRegisterFormatError = false;
      commercialRegisterFetchingError = false;
      commercialRegisterFetched = false;
    });

    final num = _model.commercialRegisterTextController?.text.trim() ?? '';

    if (num.isEmpty) {
      commercialRegisterRequiredError = true;
      setState(() {});
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(num)) {
      commercialRegisterFormatError = true;
      setState(() {});
      return;
    }

    // === Wathq API URL ===
    final url = Uri.parse(
      "https://api.wathq.sa/commercial-registration/fullinfo/$num?language=ar",
    );

    // === Send GET request with API KEY ===
    http.Response response;
    try {
      response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "apikey": "uebLqRQ4P80TeVa6iCGPb9oQN25FRavD",
        },
      );
    } catch (e) {
      commercialRegisterFetchingError = true;
      setState(() {});
      return;
    }

    print("Wathq Response: ${response.body}");

    // === Decode JSON ===
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      commercialRegisterFetchingError = true;
      setState(() {});
      return;
    }

    final fetchedCrNumber = data["crNationalNumber"] ?? "";
    final fetchedStatus = data["status"]?["name"] ?? "";
    final fetchedConfirmationDate = data["status"]?["confirmationDate"]?["gregorian"] ?? "";

    if (fetchedCrNumber.isEmpty ||
        fetchedStatus.isEmpty ||
        fetchedConfirmationDate.isEmpty) {
      commercialRegisterFetchingError = true;
      setState(() {});
      return;
    }

    commercialRegisterNumber = fetchedCrNumber;
    commercialRegisterStatus = fetchedStatus;
    commercialRegisterExpiry = fetchedConfirmationDate;

    isCommercialRegisterVerified = fetchedStatus == "نشط";

    try {
      final expDate = DateTime.parse(fetchedConfirmationDate.replaceAll('/', '-'));
      final now = DateTime.now();
      commercialRegisterIsExpiringSoon = expDate.difference(now).inDays <= 30;
    } catch (_) {
      commercialRegisterIsExpiringSoon = false;
    }

    commercialRegisterFetched = true;
    setState(() {});
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

//7016798154