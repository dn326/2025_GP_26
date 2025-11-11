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

import '../../widgets/custom_text_form_field.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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
  State<BusinessSetupProfilePage> createState() =>
      _BusinessSetupProfilePageState();
}

class _BusinessSetupProfilePageState extends State<BusinessSetupProfilePage>
    with SingleTickerProviderStateMixin {
  late BusinessEditProfileModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  File? _pickedImage;
  Uint8List? _pickedBytes;
  String? _imageUrl;
  bool _uploadingImage = false;
  final bool _loading = false;
  bool _showErrors = false;

  late AnimationController _shakeCtrl;

  late List<DropDownList> _businessIndustries;
  DropDownList? _selectedBusinessIndustry;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessEditProfileModel());

    _businessIndustries = DropDownListLoader.instance.businessIndustries;

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

  String? _validateCompanyName(String? value) {
    if (!_showErrors) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'يرجى إدخال اسم الشركة';
    return null;
  }

  String? _validateIndustry() {
    if (!_showErrors) return null;
    if (_selectedBusinessIndustry == null) return 'يرجى اختيار الصناعة';
    return null;
  }

  String? _validatePhone(String? value) {
    if (!_showErrors) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'يرجى إدخال رقم الجوال';
    if (!RegExp(r'^05[0-9]{8}$').hasMatch(v)) {
      return 'رقم الجوال يجب أن يكون 05xxxxxxxx';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (!_showErrors) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  bool _hasValidationErrors() {
    final companyName = _model.businessNameTextController?.text.trim() ?? '';
    final phone = _model.phoneNumberTextController?.text.trim() ?? '';
    final email = _model.emailTextController?.text.trim() ?? '';

    if (companyName.isEmpty) return true;
    if (_selectedBusinessIndustry == null) return true;
    if (phone.isEmpty) return true;
    if (email.isEmpty) return true;
    if (!RegExp(r'^05[0-9]{8}$').hasMatch(phone)) return true;
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) return true;

    return false;
  }

  Future<void> _saveAll() async {
    setState(() => _showErrors = true);

    if (_hasValidationErrors()) {
      _shakeCtrl.forward(from: 0);
      return;
    }

    try {
      final profile = BusinessProfileModel(
        businessId: 0,
        businessNameAr: _model.businessNameTextController?.text.trim() ?? '',
        businessIndustryId: _selectedBusinessIndustry?.id ?? 0,
        businessIndustryNameAr: _selectedBusinessIndustry?.nameAr ?? '',
        description: _model.businessDescreptionTextController?.text.trim(),
        phoneNumber: _model.phoneNumberTextController?.text.trim(),
        email: _model.emailTextController?.text.trim(),
        profileImageUrl: _imageUrl,
      );
      await FirebaseService().saveProfileData(profile);
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
    final themeFlutterFlow = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white70,// themeFlutterFlow.backgroundElan,
        appBar: AppBar(
          backgroundColor: themeFlutterFlow.secondaryBackground,
          centerTitle: true,
          title: const Text('إعداد الملف الشخصي'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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

              _buildFieldLabel('اسم الشركة', themeFlutterFlow),
              _buildTextField(
                _model.businessNameTextController,
                _validateCompanyName,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<DropDownList>(
                decoration: InputDecoration(
                  labelText: 'نوع الصناعة',
                  border: const OutlineInputBorder(),
                  errorText: _validateIndustry(),
                ),
                initialValue: _selectedBusinessIndustry,
                items: _businessIndustries
                    .map(
                      (i) =>
                      DropdownMenuItem(value: i, child: Text(i.nameAr)),
                )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedBusinessIndustry = v),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('النبذة الشخصية', themeFlutterFlow),
              _buildTextField(
                _model.businessDescreptionTextController,
                null,
                maxLines: 3,
              ),

              _buildFieldLabel('رقم الجوال', themeFlutterFlow),
              _buildTextField(
                _model.phoneNumberTextController,
                _validatePhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              _buildFieldLabel('البريد الإلكتروني', themeFlutterFlow),
              _buildTextField(
                _model.emailTextController,
                _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),

              AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (ctx, child) => Transform.translate(
                  offset: Offset(_shakeOffset(), 0),
                  child: child,
                ),
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
            ],
          ),
        ),
      ),
    );
  }

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
      crossAxisAlignment: CrossAxisAlignment.start,
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
  }
}