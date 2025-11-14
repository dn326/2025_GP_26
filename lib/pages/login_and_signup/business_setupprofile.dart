import 'dart:core';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/feq_components.dart';
import '../../components/searchable_dropdown.dart';

import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '../../../main_screen.dart';
import '../../../models/dropdown_list.dart';
import '../../../services/dropdown_list_loader.dart';
import '../../../services/elan_storage.dart';
import '../profile/business_edit_profile_model.dart';
import '../profile/business_profile_model.dart';
import '../../services/firebase_service.dart';

class BusinessSetupProfilePage extends StatefulWidget {
  const BusinessSetupProfilePage({super.key});

  static String routeName = 'business_setup';

  @override
  State<BusinessSetupProfilePage> createState() => _BusinessSetupProfilePageState();
}

class _BusinessSetupProfilePageState extends State<BusinessSetupProfilePage>
    with SingleTickerProviderStateMixin {
  late BusinessEditProfileModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  File? _pickedImage;
  Uint8List? _pickedBytes;
  String? _imageUrl;
  bool _uploadingImage = false;
  final bool _loading = false;
  bool _showErrors = false;

  late AnimationController _shakeCtrl;

  late List<DropDownList> _businessIndustries;
  DropDownList? _selectedBusinessIndustry;

  late List<DropDownList> _socialPlatforms;
  final List<_SocialRow> _socialRows = [_SocialRow()];
  bool _socialsRequireError = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessEditProfileModel());

    _businessIndustries = DropDownListLoader.instance.businessIndustries;
    _socialPlatforms = DropDownListLoader.instance.socialPlatforms;

    _model.businessNameTextController ??= TextEditingController();
    _model.businessDescreptionTextController ??= TextEditingController();
    _model.businessDescreptionFocusNode ??= FocusNode();
    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

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

  Widget _avatarWidget({String? imageUrl, Uint8List? bytes, File? file, double size = 100}) {
    Widget imageWidget;

    if (bytes != null && bytes.isNotEmpty) {
      imageWidget = Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    } else if (file != null) {
      imageWidget = Image.file(file, width: size, height: size, fit: BoxFit.cover);
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
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) {
      setState(() => _uploadingImage = false);
      return;
    }

    String extension = 'jpg';
    if (x.mimeType != null && x.mimeType!.contains('png')) extension = 'png';

    final storage = await ElanStorage.storage;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
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

  String? _validateCompanyName(String? value) {
    if (!_showErrors) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'يرجى إدخال اسم الشركة';
    return null;
  }

  String? _validateIndustry() {
    if (!_showErrors) return null;
    if (_selectedBusinessIndustry == null) return 'يرجى اختيار المجال';
    return null;
  }

  String? _validatePhone(String? value) {
    if (!_showErrors) return null;
    final v = value?.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';
    if (v.isEmpty && email.isEmpty) return 'يرجى إدخال رقم الجوال أو بريد التواصل';
    if (v.isNotEmpty && !RegExp(r'^05[0-9]{8}$').hasMatch(v)) {
      return 'رقم الجوال يجب أن يكون 05xxxxxxxx';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (!_showErrors) return null;
    final v = value?.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    if (v.isEmpty && phone.isEmpty) return 'يرجى إدخال رقم الجوال أو  بريد التواصل';
    if (v.isNotEmpty && !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
      return 'بريد التواصل غير صحيح';
    }
    return null;
  }

  bool _hasValidationErrors() {
    final companyName = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';

    if (companyName.isEmpty) return true;
    if (_selectedBusinessIndustry == null) return true;
    if (phone.isEmpty && email.isEmpty) return true;
    if (phone.isNotEmpty && !RegExp(r'^05[0-9]{8}$').hasMatch(phone)) return true;
    if (email.isNotEmpty && !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) return true;

    // Validate social media: at least one must be filled
    bool hasValidSocial = _socialRows.any(
      (row) => row.platform != null && row.usernameCtrl.text.trim().isNotEmpty,
    );
    if (!hasValidSocial) {
      _socialsRequireError = true;
      return true;
    }

    // Validate social media completeness
    for (final row in _socialRows) {
      if (row.platform != null && row.usernameCtrl.text.trim().isEmpty) {
        _socialsRequireError = true;
        return true;
      }
      if (row.platform == null && row.usernameCtrl.text.trim().isNotEmpty) {
        _socialsRequireError = true;
        return true;
      }
    }

    return false;
  }

  Future<void> _saveAll() async {
    setState(() => _showErrors = true);

    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    if (_hasValidationErrors()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    try {
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
        socialMedia: socialMedia,
      );
      await FirebaseService().saveProfileData(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
      final user = FirebaseAuth.instance.currentUser!;
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_type', 'business');
      await prefs.setString('email', user.email!);
      await prefs.setString('account_status', 'active');
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeFlutterFlow = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white70, // themeFlutterFlow.backgroundElan,
        appBar: AppBar(
          backgroundColor: themeFlutterFlow.secondaryBackground,
          centerTitle: true,
          title: const Text('إعداد الملف الشخصي'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _avatarWidget(
                              imageUrl: _imageUrl,
                              file: _pickedImage,
                              bytes: _pickedBytes,
                              size: 100,
                            ),
                            if (_uploadingImage) const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('اسم الشركة', themeFlutterFlow, isRequired: true),
                      _buildTextField(_model.businessNameTextController, _validateCompanyName),

                      const SizedBox(height: 16),

                      _buildFieldLabel('نوع المجال', themeFlutterFlow, isRequired: true),
                      _buildDropdownField(
                        validator: _validateIndustry,
                        value: _selectedBusinessIndustry,
                        items: _businessIndustries,
                        onChanged: (v) => setState(() => _selectedBusinessIndustry = v),
                      ),

                      const SizedBox(height: 16),

                      _buildFieldLabel('النبذة الشخصية', themeFlutterFlow),
                      _buildTextField(_model.businessDescreptionTextController, null, maxLines: 3),

                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                            border: Border.all(color: themeFlutterFlow.secondary),
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
                                          color: themeFlutterFlow
                                              .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
                                          style: themeFlutterFlow.bodyMedium.copyWith(
                                            fontFamily: 'Inter',
                                            color: themeFlutterFlow.primaryText,
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
                                        style: themeFlutterFlow.bodyMedium.copyWith(
                                          fontFamily: 'Inter',
                                          color: themeFlutterFlow.primaryText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: const AlignmentDirectional(1, -1),
                                      child: Text(
                                        'اسم المنصة ',
                                        textAlign: TextAlign.end,
                                        style: themeFlutterFlow.bodyMedium.copyWith(
                                          fontFamily: 'Inter',
                                          color: themeFlutterFlow.primaryText,
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
                                                color: themeFlutterFlow
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
                                                  style: themeFlutterFlow.bodyMedium.copyWith(
                                                    color: themeFlutterFlow.primaryText,
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
                                                FeqSearchableDropdown<DropDownList>(
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

                      _buildFieldLabel('رقم الجوال', themeFlutterFlow),
                      _buildTextField(
                        _model.phoneNumberTextController,
                        _validatePhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),

                      _buildFieldLabel('بريد التواصل', themeFlutterFlow),
                      _buildTextField(
                        _model.emailTextController,
                        _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                        child: AnimatedBuilder(
                          animation: _shakeCtrl,
                          builder: (ctx, child) =>
                              Transform.translate(offset: Offset(_shakeOffset(), 0), child: child),
                          child: FFButtonWidget(
                            onPressed: _saveAll,
                            text: 'حفظ',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 50,
                              color: themeFlutterFlow.primary,
                              textStyle: themeFlutterFlow.bodyMedium.copyWith(
                                fontFamily: 'Readex Pro',
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, FlutterFlowTheme theme, {bool isRequired = false}) =>
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            children: [
              Text(
                label,
                style: theme.bodyMedium.copyWith(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  fontSize: 16,
                ),
              ),
              if (isRequired == true)
                Expanded(
                  child: Row(
                    children: [
                      Spacer(flex: 1),
                      Expanded(
                        flex: 7,
                        child: Text(
                          '*',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildDropdownField({
    required String? Function() validator,
    required DropDownList? value,
    required List<DropDownList> items,
    required void Function(DropDownList?) onChanged,
  }) {
    final errorText = validator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DropdownButtonFormField<DropDownList>(
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: FlutterFlowTheme.of(context).primaryBackground,
                errorText: errorText,
              ),
              initialValue: value,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.nameAr))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  String? _validateSocialUsername(String? username) {
    if (_socialsRequireError && (username?.trim().isEmpty ?? true)) return 'يرجى إدخال اسم الحساب';
    return null;
  }

  Widget _buildTextField(
    TextEditingController? controller,
    String? Function(String?)? validator, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).primaryBackground,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: FlutterFlowTheme.of(context).primaryBackground,
          ),
        ),
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
