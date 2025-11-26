import 'dart:core';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'package:elan_flutterproject/pages/profile/business_profile_model.dart';
import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as oauth1;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart' hide createModel;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:elan_flutterproject/core/services/firebase_service_utils.dart';

import '../../flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../../../main_screen.dart';
//import '../../../models/dropdown_list.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/elan_storage.dart';
import '../../features/business/data/models/profile_form_model.dart';
import '../../features/business/data/models/profile_data_model.dart';
import '../../core/components/feq_components.dart';
import '../../features/influencer/presentation/profile_form_widget.dart';

InputDecoration inputDecoration(BuildContext context, {bool isError = false}) {
  final t = FlutterFlowTheme.of(context);

  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: t.secondary),
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
    
    errorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),

    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),

    filled: true,
    fillColor: t.backgroundElan,
  );
}

class BusinessSetupProfilePage extends StatefulWidget {
  const BusinessSetupProfilePage({super.key});

  static String routeName = 'business_setup';

  @override
  State<BusinessSetupProfilePage> createState() =>
      _BusinessSetupProfilePageState();
}

class _BusinessSetupProfilePageState extends State<BusinessSetupProfilePage>
    with SingleTickerProviderStateMixin {
  late BusinessProfileFormModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  File? _pickedImage;
  Uint8List? _pickedBytes;

  String? _imageUrl;
  String? commercialRegisterNumber;
  String? commercialRegisterExpiry;
  String? commercialRegisterStatus;

  final bool _loading = false;
  bool _uploadingImage = false;

  bool _nameEmpty = false;
  bool _contentEmpty = false;
  bool _bothContactsEmpty = false;

  bool _showErrors = false;
  bool _socialsRequireError = false;
  bool _showLicenseErrors = false;

  bool commercialRegisterRequiredError = false;
  bool commercialRegisterFormatError = false;
  bool commercialRegisterFetchingError = false;
  bool commercialRegisterFetched = false; // determines if we should save
  bool commercialRegisterIsExpiringSoon = false;
  bool isCommercialRegisterVerified = false;

  late AnimationController _shakeCtrl;

  late List<FeqDropDownList> _socialPlatforms;
  final List<_SocialRow> _socialRows = [_SocialRow()];

    late List<FeqDropDownList> _businessIndustries;
  FeqDropDownList? _selectedBusinessIndustry;

  final platform = oauth1.Platform( 
    'https://api.wathq.sa/v4/token/request', // request token URL 
    'https://api.wathq.sa/v4/token/authorize', // authorization URL 
    'https://api.wathq.sa/v4/token/access', // access token URL 
    oauth1.SignatureMethods.hmacSha1, // OAuth method required by Wathq 
  );

  @override
  void initState() {
    super.initState();
    _model = BusinessProfileFormModel();

    _businessIndustries = FeqDropDownListLoader.instance.businessIndustries;
    _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;

    _model.businessNameTextController ??= TextEditingController();
    _model.businessNameFocusNode ??= FocusNode();

    _model.businessDescreptionTextController ??= TextEditingController();
    _model.businessDescreptionFocusNode ??= FocusNode();

    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.commercialRegisterController ??= TextEditingController();
    _model.commercialRegisterFocusNode ??= FocusNode();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _attachSocialRowListeners(_socialRows.first);
  }

  void _attachSocialRowListeners(_SocialRow row) {
    row.usernameCtrl.addListener(_onAnyFieldChanged);
  }

  void _onAnyFieldChanged() {
    // Recompute validation if needed
    setState(() {});
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
    Widget imageWidget;

    if (bytes != null && bytes.isNotEmpty) {
      imageWidget = Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (file != null) {
      imageWidget = Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
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
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(child: imageWidget),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (_loading) return;
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
    if (x.mimeType != null && x.mimeType!.contains('png')) extension = 'png';

    final storage = await ElanStorage.storage;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = storage.ref().child('profiles').child(uid).child(fileName);

    if (kIsWeb) {
      final bytes = await x.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
        _pickedImage = null;
      });
      await ref.putData(bytes);
      _imageUrl = await ref.getDownloadURL();
    } else {
      final file = File(x.path);
      setState(() {
        _pickedImage = file;
        _pickedBytes = null;
      });
      await ref.putFile(file);
      _imageUrl = await ref.getDownloadURL();
    }
    setState(() => _uploadingImage = false);
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
    final name = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';
    final license = _model.commercialRegisterController?.text.trim() ?? '';
    
    _nameEmpty = name.isEmpty;
    _contentEmpty = _selectedBusinessIndustry == null;
    _bothContactsEmpty = phone.isEmpty && email.isEmpty;
    commercialRegisterRequiredError = license.isEmpty;

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

  String? _validateSocialUsername(String? username) {
    if (_socialsRequireError && (username?.trim().isEmpty ?? true)) return 'يرجى إدخال اسم الحساب';
    return null;
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

    if (commercialRegisterRequiredError || commercialRegisterFormatError  || commercialRegisterFetchingError) {
      setState(() => _showErrors = true);
      _shakeCtrl.forward(from: 0);
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final socialMedia = _socialRows
        .where((row) => row.platform != null && row.usernameCtrl.text.trim().isNotEmpty)
        .map(
          (row) => {'platform': row.platform!.nameEn, 'username': row.usernameCtrl.text.trim()},
        )
        .toList();

      final profile = BusinessProfileModel(
        businessId: 0,
        businessNameAr: _model.businessNameTextController?.text.trim() ?? '',
        businessIndustryId: _selectedBusinessIndustry?.id ?? 0,
        businessIndustryNameAr: _selectedBusinessIndustry?.nameAr ?? '',
        description: _model.businessDescreptionTextController?.text.trim(),
        phoneNumber: _model.phoneNumberTextController?.text.trim(),
        email: _model.emailTextController?.text.trim(),
        profileImageUrl: _imageUrl,
        //socialMedia: socialMedia,
      );

      final profileSnap = await FirebaseFirestore.instance
    .collection('profiles')
    .where('profile_id', isEqualTo: uid)
    .limit(1)
    .get();

      if (profileSnap.docs.isNotEmpty) {
        final docRef = profileSnap.docs.first.reference;

        await docRef.update({
          'social_media': socialMedia,
        });
      }

      await FeqFirebaseServiceUtils().saveProfile(profile);

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef.set({
        'commercial_register_expiry_date': commercialRegisterExpiry ?? '',
        'commercial_register_number': commercialRegisterNumber ?? '',
        'verified': isCommercialRegisterVerified,
        'commercial_register_is_expiring': commercialRegisterIsExpiringSoon,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
        final user = FirebaseAuth.instance.currentUser!;
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.uid);
        await prefs.setString('user_type', 'business');
        await prefs.setString('email', user.email!);
        await prefs.setString('account_status', 'active');
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {

    final t = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x33000000),
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              elevation: 0,
              // set to 0 so the custom shadow is visible
              titleSpacing: 0,
              title: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 40.0,
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 6, // move title slightly lower
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'إعداد الملف الشخصي',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).headlineSmall
                                .copyWith(fontWeight: FontWeight.w600),
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
        body: SafeArea(
          top: true,
          child: _loading? const Center(child: CircularProgressIndicator())
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
                                  // Avatar
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment: const AlignmentDirectional(0, -1),
                                          child: GestureDetector(
                                            onTap: (_uploadingImage || _loading) ? null : _pickAndUploadImage,
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
                                                    child: CircularProgressIndicator(strokeWidth: 3),
                                                  ),
                                              ],
                                            ),
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
                                /// All your fields here

                                FeqLabeled(
                                  'الاسم الشركة',
                                  errorText: _showErrors && _nameEmpty ? 'يرجى إدخال اسم الشركة' : null,
                                  child: TextFormField(
                                    controller: _model.businessNameTextController,
                                    focusNode: _model.businessNameFocusNode,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: inputDecoration(context, isError: _showErrors && _nameEmpty),
                                    style: t.bodyLarge.copyWith(color: t.primaryText),
                                    textAlign: TextAlign.end,
                                  ),
                                ),

                                FeqLabeled(
                                  'نوع المجال',
                                  errorText: _showErrors && _contentEmpty ? 'يرجى اختيار المجال' : null,
                                  child: FeqSearchableDropdown<FeqDropDownList>(
                                    items: _businessIndustries,
                                    value: _selectedBusinessIndustry,
                                    onChanged: (v) {
                                      setState(() => _selectedBusinessIndustry = v);
                                    },
                                    hint: 'اختر أو ابحث...',
                                    isError: _showErrors && _contentEmpty,
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
                                                    style: t.bodyMedium.copyWith(
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
                                                child: Text(
                                                  'اسم الحساب في المنصة',
                                                  style: t.bodyMedium.copyWith(
                                                    fontFamily: 'Inter',
                                                    color: t.primaryText,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: const AlignmentDirectional(1, -1),
                                                child: Text(
                                                  'اسم المنصة ',
                                                  textAlign: TextAlign.end,
                                                  style: t.bodyMedium.copyWith(
                                                    fontFamily: 'Inter',
                                                    color: t.primaryText,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                          child: Column(
                                            children: List.generate(_socialRows.length, (i) {
                                              final row = _socialRows[i];
                                              final platformEmpty =
                                                  row.platform?.id == null ||
                                                  row.platform!.id.toString().isEmpty;
                                              final usernameEmpty = row.usernameCtrl.text.trim().isEmpty;
                                              final showPlatformErr = _socialsRequireError && platformEmpty;
                                              final showUsernameErr = _socialsRequireError && usernameEmpty;

                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Align(
                                                    alignment: const AlignmentDirectional(1, 0),
                                                    child: Padding(
                                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                                        0,
                                                        0,
                                                        0,
                                                        16,
                                                      ),
                                                      child: FlutterFlowIconButton(
                                                        borderRadius: 8,
                                                        buttonSize: 50,
                                                        icon: Icon(
                                                          Icons.minimize_outlined,
                                                          color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
                                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                                        0,
                                                        0,
                                                        20,
                                                        0,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          TextFormField(
                                                            validator: _validateSocialUsername,
                                                            controller: row.usernameCtrl,
                                                            textCapitalization: TextCapitalization.none,
                                                            decoration: platformInputDecoration(
                                                              context,
                                                              isError: showUsernameErr,
                                                            ),
                                                            style: t.bodyMedium.copyWith(
                                                              color: t.primaryText,
                                                            ),
                                                            textAlign: TextAlign.end,
                                                          ),
                                                          if (row.platform != null &&
                                                              row.usernameCtrl.text.trim().isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4),
                                                              child: InkWell(
                                                                onTap: () {
                                                                  final url =
                                                                      'https://${row.platform!.domain}/${row.usernameCtrl.text.trim()}';
                                                                  launchUrl(Uri.parse(url));
                                                                },
                                                                child: Text(
                                                                  '${row.platform!.domain}/${row.usernameCtrl.text.trim()}',
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
                                                              padding: EdgeInsetsDirectional.fromSTEB(
                                                                0,
                                                                6,
                                                                4,
                                                                0,
                                                              ),
                                                              child: Text(
                                                                'يرجى إدخال اسم الحساب.',
                                                                style: TextStyle(
                                                                  color: Colors.red,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                                        0,
                                                        0,
                                                        20,
                                                        0,
                                                      ),
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
                                                              padding: EdgeInsetsDirectional.fromSTEB(
                                                                0,
                                                                6,
                                                                4,
                                                                0,
                                                              ),
                                                              child: Text(
                                                                'يرجى اختيار المنصة.',
                                                                style: TextStyle(
                                                                  color: Colors.red,
                                                                  fontSize: 12,
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
                                FeqLabeled(
                                  'النبذة الشخصية',
                                  child: TextFormField(
                                    controller: _model.businessDescreptionTextController,
                                    focusNode: _model.businessDescreptionFocusNode,
                                    textCapitalization: TextCapitalization.sentences,
                                    maxLines: 3,
                                    decoration: inputDecoration(context),
                                    style: t.bodyLarge.copyWith(color: t.primaryText),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                
                                // Phone
                                FeqLabeled(
                                  'رقم الجوال',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextFormField(
                                        controller: _model.phoneNumberTextController,
                                        focusNode: _model.phoneNumberFocusNode,
                                        keyboardType: TextInputType.phone,
                                        decoration: inputDecoration(
                                          context,
                                          isError:
                                              _showErrors &&
                                              _bothContactsEmpty &&
                                              _model.phoneNumberTextController!.text.trim().isEmpty,
                                        ),
                                        style: t.bodyLarge.copyWith(color: t.primaryText),
                                        textAlign: TextAlign.end,
                                      ),
                                      if (_showErrors &&
                                          _bothContactsEmpty &&
                                          _model.phoneNumberTextController!.text.trim().isEmpty)
                                        const Padding(
                                          padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                          child: Text(
                                            'يرجى إدخال رقم الجوال أو البريد الإلكتروني.',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Email
                                FeqLabeled(
                                  'البريد الإلكتروني',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextFormField(
                                        controller: _model.emailTextController,
                                        focusNode: _model.emailFocusNode,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: inputDecoration(
                                          context,
                                          isError:
                                              _showErrors &&
                                              _bothContactsEmpty &&
                                              _model.emailTextController!.text.trim().isEmpty,
                                        ),
                                        style: t.bodyLarge.copyWith(color: t.primaryText),
                                        textAlign: TextAlign.end,
                                      ),
                                      if (_showErrors &&
                                          _bothContactsEmpty &&
                                          _model.emailTextController!.text.trim().isEmpty)
                                        const Padding(
                                          padding: EdgeInsetsDirectional.fromSTEB(0, 6, 4, 0),
                                          child: Text(
                                            'يرجى إدخال البريد الإلكتروني أو رقم الجوال.',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                FeqLabeled(
                                  'رقم السجل التجاري الموحد',
                                  errorText: _showLicenseErrors &&
                                          (commercialRegisterRequiredError ||
                                              commercialRegisterFormatError ||
                                              commercialRegisterFetchingError)
                                      ? (commercialRegisterRequiredError
                                          ? 'يرجى إدخال الرقم الموحد للسجل التجاري.'
                                          : commercialRegisterFormatError
                                              ? 'رقم السجل يجب أن يكون 10 أرقام صحيحة.'
                                              : 'رقم السجل غير صحيح أو غير موجود.')
                                      : null,
                                  child: Row(
                                    children: [
                                      // ==== CR TextField ====
                                      Expanded(
                                        child: TextFormField(
                                          controller: _model.commercialRegisterController,
                                          focusNode: _model.commercialRegisterFocusNode,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          decoration: inputDecoration(
                                            context,
                                            isError: _showLicenseErrors &&
                                                (commercialRegisterRequiredError ||
                                                    commercialRegisterFormatError ||
                                                    commercialRegisterFetchingError),
                                          ),
                                          style: t.bodyLarge.copyWith(color: t.primaryText),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // ==== Verify Button ====
                                      ElevatedButton(
                                        onPressed: _fetchLicenseData,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: t.secondaryButtonsOnLight,
                                          padding:
                                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    child: TextFormField(
                                      initialValue: commercialRegisterStatus ?? '',
                                      enabled: false,
                                      decoration: inputDecoration(context).copyWith(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      style: t.bodyLarge.copyWith(color: Colors.grey[700]),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),

                                  // License Expiry Date
                                  FeqLabeled(
                                    'تاريخ انتهاء السجل',
                                    child: TextFormField(
                                      initialValue: commercialRegisterExpiry ?? '',
                                      enabled: false,
                                      decoration: inputDecoration(context).copyWith(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      style: t.bodyLarge.copyWith(color: Colors.grey[700]),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],

                                Center(
                                  child: Padding(
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
                                        text: 'حفظ',
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

    final num = _model.commercialRegisterController?.text.trim() ?? '';

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

    final fetchedCrNumber = data["crNumber"] ?? "";
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

  _SocialRow({TextEditingController? usernameCtrl}) : usernameCtrl = usernameCtrl ?? TextEditingController();

  void dispose() {
    usernameCtrl.dispose();
  }
}

//7016798154

/*
Widget _buildFieldLabel(String label, FlutterFlowTheme theme) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: theme.bodyMedium.copyWith(fontFamily: GoogleFonts.inter().fontFamily, fontSize: 16),
      ),
    ),
  );

  Widget _buildTextField(
      TextEditingController? controller,
      String? Function(String?)? validator,
      {int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}
      ) {
    final errorText = validator?.call(controller?.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomTextFormField(
              controller: controller,
              validator: (_) => null,
              maxLines: maxLines,
              includeLabelAndHintStyle: true,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }*/