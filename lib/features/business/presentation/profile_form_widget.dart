import 'dart:core';
import 'dart:math' as math;

import 'package:elan_flutterproject/core/services/firebase_service_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/utils/enum_profile_mode.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../main_screen.dart';
import '../data/models/profile_data_model.dart';
import '../data/models/profile_form_model.dart';
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

class BusinessProfileFormWidget extends StatefulWidget {
  final ProfileMode mode;

  const BusinessProfileFormWidget({
    super.key,
    this.mode = ProfileMode.edit,
  });

  static const String routeNameEdit = 'business-profile-edit';
  static const String routePathEdit = '/$routeNameEdit';

  // static const String routeNameSetup = 'business-profile-setup';
  // static const String routePathSetup = '/$routeNameSetup';

  @override
  State<BusinessProfileFormWidget> createState() =>
      _BusinessProfileFormWidgetState();
}

class _BusinessProfileFormWidgetState extends State<BusinessProfileFormWidget>
    with SingleTickerProviderStateMixin {
  late BusinessProfileFormModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _imageUrl;
  bool _uploadingImage = false;
  bool _loading = true;
  bool _showErrors = false;

  late AnimationController _shakeCtrl;
  late List<FeqDropDownList> _businessIndustries;
  FeqDropDownList? _selectedBusinessIndustry;

  bool _nameEmpty = false;
  bool _industryEmpty = false;
  bool _bothContactsEmpty = false;

  bool get isSetupMode => widget.mode == ProfileMode.setup;
  bool get isEditMode => widget.mode == ProfileMode.edit;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessProfileFormModel());

    _businessIndustries = FeqDropDownListLoader.instance.businessIndustries;

    _model.businessNameTextController ??= TextEditingController();
    _model.businessDescreptionTextController ??= TextEditingController();
    _model.businessDescreptionFocusNode ??= FocusNode();
    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (isSetupMode) {
      _initSetupMode();
    } else {
      _loadProfileData();
    }
  }

  void _initSetupMode() {
    setState(() => _loading = false);
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await FeqFirebaseServiceUtils().fetchBusinessProfileData();
      if (profile != null && mounted) {
        setState(() {
          _model.businessNameTextController?.text = profile.businessNameAr;
          _model.businessDescreptionTextController?.text =
              profile.description ?? '';
          _model.phoneNumberTextController?.text = profile.phoneNumber ?? '';
          _model.emailTextController?.text = profile.email ?? '';
          if (profile.profileImageUrl != null) {
            _imageUrl = profile.profileImageUrl;
          }
          if (profile.businessIndustryId > 0) {
            _selectedBusinessIndustry = _businessIndustries.firstWhere(
                  (i) => i.id == profile.businessIndustryId,
              orElse: () => _businessIndustries.first,
            );
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل البيانات: $e')),
      );
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _model.dispose();
    super.dispose();
  }

  double _shakeOffset() {
    if (!_shakeCtrl.isAnimating) return 0;
    return math.sin(_shakeCtrl.value * 10 * math.pi) * 8;
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

      setState(() {
        _imageUrl = result.downloadUrl;
        _uploadingImage = false;
      });

    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e')),
        );
      }
    }
  }


  void _recomputeValidation() {
    final name = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';

    _nameEmpty = name.isEmpty;
    _industryEmpty = _selectedBusinessIndustry == null;
    _bothContactsEmpty = phone.isEmpty && email.isEmpty;
  }

  bool get _isFormValid {
    final name = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';

    if (name.isEmpty) return false;
    if (_selectedBusinessIndustry == null) return false;

    // At least one contact must be filled
    if (phone.isEmpty && email.isEmpty) return false;
    // Validate phone format if provided
    if (phone.isNotEmpty && !RegExp(r'^05[0-9]{8}$').hasMatch(phone)) {
      return false;
    }

    // Validate email format if provided
    if (email.isNotEmpty &&
        !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
      return false;
    }

    return true;
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

  Future<void> _saveAll() async {
    _recomputeValidation();

    final phoneError = _validatePhone(_model.phoneNumberTextController?.text);
    final emailError = _validateEmail(_model.emailTextController?.text);

    if (_nameEmpty ||
        _industryEmpty ||
        _bothContactsEmpty ||
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
      final profile = BusinessProfileDataModel(
        businessId: 0,
        businessNameAr: _model.businessNameTextController?.text.trim() ?? '',
        businessIndustryId: _selectedBusinessIndustry?.id ?? 0,
        businessIndustryNameAr: _selectedBusinessIndustry?.nameAr ?? '',
        description: _model.businessDescreptionTextController?.text.trim(),
        phoneNumber: _model.phoneNumberTextController?.text.trim(),
        email: _model.emailTextController?.text.trim(),
        profileImageUrl: _imageUrl,
      );

      await FeqFirebaseServiceUtils().saveProfileData(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(isSetupMode ? 'تم الحفظ بنجاح' : 'تم التحديث بنجاح')),
        );

        if (isSetupMode) {
          final user = firebaseAuth.currentUser!;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', user.uid);
          await prefs.setString('user_type', 'business');
          await prefs.setString('email', user.email!);
          await prefs.setString('account_status', 'active');
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e')),
      );
    }
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
        backRoute: MainScreen.routeName,
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
                          padding:
                          const EdgeInsetsDirectional.fromSTEB(
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
                                      child: FeqImagePickerWidget(
                                        initialImageUrl: _imageUrl,
                                        isUploading: false,
                                        onTap: () {},
                                        size: 100,
                                        onImagePicked: (url, file, bytes) {},
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
                                              style:
                                              t.bodyMedium.override(
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

                              // Company Name
                              FeqLabeledTextField(
                                label: 'اسم الشركة',
                                controller:
                                _model.businessNameTextController,
                                textCapitalization:
                                TextCapitalization.words,
                                width: double.infinity,
                                isError: _showErrors && _nameEmpty,
                                errorText: _showErrors && _nameEmpty
                                    ? 'يرجى إدخال اسم الشركة.'
                                    : null,
                                decoration: inputDecoration(
                                  context,
                                  isError: _showErrors && _nameEmpty,
                                ),
                              ),

                              // Industry
                              FeqLabeled(
                                'نوع الصناعة',
                                errorText: _showErrors && _industryEmpty
                                    ? 'يرجى اختيار نوع الصناعة.'
                                    : null,
                                child:
                                FeqSearchableDropdown<FeqDropDownList>(
                                  items: _businessIndustries,
                                  value: _selectedBusinessIndustry,
                                  onChanged: (v) {
                                    setState(() =>
                                    _selectedBusinessIndustry = v);
                                  },
                                  hint: 'اختر أو ابحث...',
                                  isError:
                                  _showErrors && _industryEmpty,
                                ),
                              ),

                              // Description
                              FeqLabeledTextField(
                                label: 'النبذة الشخصية',
                                controller: _model
                                    .businessDescreptionTextController,
                                focusNode:
                                _model.businessDescreptionFocusNode,
                                textCapitalization:
                                TextCapitalization.sentences,
                                width: double.infinity,
                                maxLines: 3,
                                decoration: inputDecoration(context),
                              ),

                              // Contact Information Section
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                                child: FeqLabeled('معلومات التواصل'),
                              ),

                              // Phone
                              Padding(
                                padding:
                                const EdgeInsetsDirectional.fromSTEB(
                                    20, 0, 20, 6),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    FeqLabeledTextField(
                                      label: 'رقم الجوال',
                                      required: false,
                                      controller: _model.phoneNumberTextController,
                                      focusNode: _model.phoneNumberFocusNode,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: inputDecoration(
                                        context,
                                        isError: _showErrors && _bothContactsEmpty,
                                      ).copyWith(hintText: 'رقم الجوال'),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),

                              // Email
                              Padding(
                                padding:
                                const EdgeInsetsDirectional.fromSTEB(
                                    20, 0, 20, 6),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    FeqLabeledTextField(
                                      label: 'البريد الإلكتروني',
                                      required: false,
                                      controller:
                                      _model.emailTextController,
                                      focusNode: _model.emailFocusNode,
                                      keyboardType:
                                      TextInputType.emailAddress,
                                      decoration: inputDecoration(
                                        context,
                                        isError: _showErrors &&
                                            _bothContactsEmpty,
                                      ).copyWith(
                                        hintText: 'البريد الإلكتروني',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Error message for contact info
                              if (_showErrors && _bothContactsEmpty)
                                Padding(
                                  padding: const EdgeInsetsDirectional
                                      .fromSTEB(0, 6, 24, 10),
                                  child: Text(
                                    'يرجى إدخال رقم الجوال أو البريد الإلكتروني.',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ),

                              // Buttons
                              if (isEditMode)
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional
                                          .fromSTEB(
                                        0,
                                        16,
                                        0,
                                        24,
                                      ),
                                      child: FFButtonWidget(
                                        onPressed: () =>
                                            Navigator.pushReplacementNamed(
                                              context,
                                              MainScreen.routeName,
                                            ),
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
                                      padding: const EdgeInsetsDirectional
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
                                          onPressed: _isFormValid
                                              ? () => _saveAll()
                                              : null,
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
                                            BorderRadius.circular(12),
                                            disabledColor: Colors.grey,
                                            disabledTextColor:
                                            Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
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
                                          offset: Offset(
                                            _shakeOffset(),
                                            0,
                                          ),
                                          child: child,
                                        ),
                                    child: FFButtonWidget(
                                      onPressed: _isFormValid
                                          ? () => _saveAll()
                                          : null,
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
                                        borderRadius:
                                        BorderRadius.circular(12),
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