import 'dart:convert';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/core/components/feq_components.dart';
import 'package:elan_flutterproject/core/services/user_session.dart';
import 'package:elan_flutterproject/flutter_flow/flutter_flow_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/flutter_flow/flutter_flow_theme.dart';
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

class AccountUpdateCertificatePage extends StatefulWidget {
  const AccountUpdateCertificatePage({super.key});

  static String routeName = 'account_update_certificate';
  static String routePath = '/accountUpdateCertificate';

  @override
  State<AccountUpdateCertificatePage> createState() =>
      _AccountUpdateCertificatePageState();
}

class _AccountUpdateCertificatePageState
    extends State<AccountUpdateCertificatePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ======= COMMON =======
  String userType = '';
  bool _initialLoading = true;

  // ======= BUSINESS (Commercial Register) =======
  final TextEditingController _crController = TextEditingController();
  final FocusNode _crFocusNode = FocusNode();

  String? commercialRegisterNumber;
  String? commercialRegisterExpiry; // yyyy-MM-dd
  String? commercialRegisterStatus;

  bool _crVerifyLoading = false;
  bool _crUpdateLoading = false;

  bool _showCrErrors = false;
  bool commercialRegisterRequiredError = false;
  bool commercialRegisterFormatError = false;
  bool commercialRegisterFetchingError = false;
  bool commercialRegisterFetched = false;
  bool commercialRegisterIsExpiringSoon = false;
  bool isCommercialRegisterVerified = false;

  bool get isBusinessUpdateButtonEnabled =>
      userType == 'business' &&
      commercialRegisterFetched &&
      !commercialRegisterFetchingError &&
      (commercialRegisterStatus ?? '').isNotEmpty &&
      (commercialRegisterExpiry ?? '').isNotEmpty &&
      !_crUpdateLoading;

  // ======= INFLUENCER (Media License) =======
  final TextEditingController _mediaController = TextEditingController();
  final FocusNode _mediaFocusNode = FocusNode();

  String? mediaLicenseNumber;
  String? mediaLicenseExpiry; // yyyy-MM-dd
  String? mediaLicenseStatus;

  bool _mediaVerifyLoading = false;
  bool _mediaUpdateLoading = false;

  bool _showMediaErrors = false;
  bool mediaLicenseRequiredError = false;
  bool mediaLicenseFormatError = false;
  bool mediaLicenseFetchingError = false;
  bool mediaLicenseFetched = false;
  bool mediaLicenseIsExpiringSoon = false;
  bool isMediaLicenseVerified = false;

  bool get isInfluencerUpdateButtonEnabled =>
      userType == 'influencer' &&
      mediaLicenseFetched &&
      !mediaLicenseFetchingError &&
      (mediaLicenseStatus ?? '').isNotEmpty &&
      (mediaLicenseExpiry ?? '').isNotEmpty &&
      !_mediaUpdateLoading;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _crController.dispose();
    _crFocusNode.dispose();
    _mediaController.dispose();
    _mediaFocusNode.dispose();
    super.dispose();
  }

  // ======= INITIAL DATA (for both user types) =======
  Future<void> _loadInitialData() async {
    final userTypeValue = (await UserSession.getUserType()) ?? '';
    userType = userTypeValue;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        if (userType == 'business') {
          final cr = (data['commercial_register_number'] ?? '') as String;
          _crController.text = cr;
        } else if (userType == 'influencer') {
          final ml = (data['media_license_number'] ?? '') as String;
          _mediaController.text = ml;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _initialLoading = false;
    });
  }

  // ================= BUSINESS: VERIFY (Wathq) =================
  Future<void> _fetchBusinessLicenseData() async {
    setState(() {
      _showCrErrors = true;
      commercialRegisterRequiredError = false;
      commercialRegisterFormatError = false;
      commercialRegisterFetchingError = false;
      commercialRegisterFetched = false;
      _crVerifyLoading = true;
    });

    final num = _crController.text.trim();

    if (num.isEmpty) {
      commercialRegisterRequiredError = true;
      _crVerifyLoading = false;
      setState(() {});
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(num)) {
      commercialRegisterFormatError = true;
      _crVerifyLoading = false;
      setState(() {});
      return;
    }

    final url = Uri.parse(
      'https://api.wathq.sa/commercial-registration/fullinfo/$num?language=ar',
    );

    http.Response response;
    try {
      response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'apikey': 'EbPA2zkAKF1aECW42BDvjd7fP8w0o1Mp',
        },
      );
    } catch (e) {
      commercialRegisterFetchingError = true;
      _crVerifyLoading = false;
      setState(() {});
      return;
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      commercialRegisterFetchingError = true;
      _crVerifyLoading = false;
      setState(() {});
      return;
    }

    final fetchedCrNumber = (data['crNationalNumber'] ?? '') as String;
    final fetchedStatus = (data['status']?['name'] ?? '') as String;
    final fetchedConfirmationDate =
        (data['status']?['confirmationDate']?['gregorian'] ?? '') as String;

    if (fetchedCrNumber.isEmpty ||
        fetchedStatus.isEmpty ||
        fetchedConfirmationDate.isEmpty) {
      commercialRegisterFetchingError = true;
      _crVerifyLoading = false;
      setState(() {});
      return;
    }

    // Save values
    commercialRegisterNumber = fetchedCrNumber;
    commercialRegisterStatus = fetchedStatus;

    isCommercialRegisterVerified = fetchedStatus == 'نشط';

    try {
      // Normalize string to yyyy-MM-dd for parse
      final raw = fetchedConfirmationDate.trim();
      final normalized =
          raw.contains('/') ? raw.replaceAll('/', '-') : raw; // yyyy-MM-dd
      final expDate = DateTime.parse(normalized);
      final now = DateTime.now();
      commercialRegisterIsExpiringSoon =
          expDate.difference(now).inDays <= 390;

      // Store as yyyy-MM-dd
      commercialRegisterExpiry =
          '${expDate.year.toString().padLeft(4, '0')}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}';
    } catch (_) {
      commercialRegisterIsExpiringSoon = false;
      commercialRegisterExpiry = '';
    }

    _crVerifyLoading = false;
    commercialRegisterFetched = true;
    setState(() {});
  }

  // ================= BUSINESS: UPDATE (Firestore) =================
  Future<void> _updateBusinessCertificate() async {
    if (!isBusinessUpdateButtonEnabled) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final t = FlutterFlowTheme.of(context);

    setState(() {
      _crUpdateLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'commercial_register_number':
              commercialRegisterNumber ?? _crController.text.trim(),
          'commercial_register_expiry_date': commercialRegisterExpiry ?? '',
          'verified': isCommercialRegisterVerified,
          'commercial_register_is_expiring':
              commercialRegisterIsExpiringSoon,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: t.success,
          content: const Text('تم تحديث بيانات السجل التجاري بنجاح'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('فشل تحديث البيانات، حاول مرة أخرى'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _crUpdateLoading = false;
        });
      }
    }
  }

  // ================= INFLUENCER: VERIFY (Mawthoq / Elaam) =================
  Future<void> _fetchMediaLicenseData() async {
    setState(() {
      _showMediaErrors = true;
      mediaLicenseRequiredError = false;
      mediaLicenseFormatError = false;
      mediaLicenseFetchingError = false;
      mediaLicenseFetched = false;
      _mediaVerifyLoading = true;
    });

    final num = _mediaController.text.trim();

    if (num.isEmpty) {
      mediaLicenseRequiredError = true;
      _mediaVerifyLoading = false;
      setState(() {});
      return;
    }

    // 6 digits
    if (!RegExp(r'^[0-9]{6}$').hasMatch(num)) {
      mediaLicenseFormatError = true;
      _mediaVerifyLoading = false;
      setState(() {});
      return;
    }

    final url =
        "https://elaam.gmedia.gov.sa/gcam-licenses/gcam-celebrity-check/$num";

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200 ||
          res.body.contains("بيانات الرخصة غير صحيحة")) {
        mediaLicenseFetchingError = true;
        _mediaVerifyLoading = false;
        setState(() {});
        return;
      }

      final body = res.body;

      // Extract values using regex from HTML
      final numReg = RegExp(
          r'<th>\s*رقم الرخصة\s*<\/th>\s*<td>\s*(.*?)\s*<\/td>');
      final statusReg = RegExp(
        r'<th>\s*حالة الرخصة\s*<\/th>.*?<span[^>]*>\s*(.*?)\s*<\/span>',
        dotAll: true,
      );
      final expReg = RegExp(
          r'<th>\s*تاريخ الإنتهاء\s*<\/th>\s*<td>\s*(.*?)\s*<\/td>');

      mediaLicenseExpiry = expReg.firstMatch(body)?.group(1) ?? '';
      mediaLicenseStatus = statusReg.firstMatch(body)?.group(1) ?? '';
      mediaLicenseNumber = numReg.firstMatch(body)?.group(1) ?? '';

      if (mediaLicenseExpiry!.isEmpty || mediaLicenseStatus!.isEmpty) {
        mediaLicenseFetchingError = true;
        _mediaVerifyLoading = false;
        setState(() {});
        return;
      }

      // Determine verified
      isMediaLicenseVerified = mediaLicenseStatus!.contains("سارية");

      // Expiry in yyyy-MM-dd
      try {
        final cleaned = mediaLicenseExpiry!.trim(); // expected yyyy/MM/dd
        final parts = cleaned.split('/'); // [yyyy, MM, dd]

        final expDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        mediaLicenseExpiry =
            '${expDate.year.toString().padLeft(4, '0')}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}';

        final now = DateTime.now();
        mediaLicenseIsExpiringSoon =
            expDate.difference(now).inDays <= 30;
      } catch (e) {
        mediaLicenseIsExpiringSoon = false;
        mediaLicenseExpiry = '';
      }

      mediaLicenseFetched = true;
      _mediaVerifyLoading = false;
      setState(() {});
    } catch (e) {
      mediaLicenseFetchingError = true;
      _mediaVerifyLoading = false;
      setState(() {});
    }
  }

  // ================= INFLUENCER: UPDATE (Firestore) =================
  Future<void> _updateMediaCertificate() async {
    if (!isInfluencerUpdateButtonEnabled) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final t = FlutterFlowTheme.of(context);

    setState(() {
      _mediaUpdateLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'media_license_number':
              mediaLicenseNumber ?? _mediaController.text.trim(),
          'media_license_expiry_date': mediaLicenseExpiry ?? '',
          'verified': isMediaLicenseVerified,
          'media_license_is_expiring': mediaLicenseIsExpiringSoon,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: t.success,
          content:
              const Text('تم تحديث بيانات الرخصة الإعلامية بنجاح'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('فشل تحديث البيانات، حاول مرة أخرى'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mediaUpdateLoading = false;
        });
      }
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
        backgroundColor: t.primaryBackground,

        appBar: FeqAppBar(
          title: 'تحديث الوثيقة',
          showBack: true,
          backRoute: null,
        ),

        body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            top: true,
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                    child: Container(
                      decoration: BoxDecoration(color: t.backgroundElan),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
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
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(16)),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 16, 0, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // BUSINESS SECTION
                                    if (userType == 'business') ...[
                                      FeqLabeled(
                                        'رقم السجل التجاري الموحد',
                                        required: true,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  TextFormField(
                                                    controller: _crController,
                                                    focusNode: _crFocusNode,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textInputAction:
                                                        TextInputAction.done,
                                                    decoration: inputDecoration(
                                                      context,
                                                      isError: _showCrErrors &&
                                                          (commercialRegisterRequiredError ||
                                                              commercialRegisterFormatError ||
                                                              commercialRegisterFetchingError),
                                                    ),
                                                    style:
                                                        t.bodyLarge.copyWith(
                                                      color: t.primaryText,
                                                    ),
                                                    textAlign: TextAlign.start,
                                                  ),
                                                  if (_showCrErrors &&
                                                      commercialRegisterRequiredError)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 6, 4, 0),
                                                      child: Text(
                                                        'يرجى إدخال الرقم الموحد للسجل التجاري.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  if (_showCrErrors &&
                                                      commercialRegisterFormatError)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 6, 4, 0),
                                                      child: Text(
                                                        'رقم السجل يجب أن يكون 10 أرقام صحيحة.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  if (_showCrErrors &&
                                                      commercialRegisterFetchingError)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 6, 4, 0),
                                                      child: Text(
                                                        'رقم السجل غير صحيح أو غير موجود.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: _crVerifyLoading
                                                  ? null
                                                  : _fetchBusinessLicenseData,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: t
                                                    .secondaryButtonsOnLight,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: _crVerifyLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      'تحقق',
                                                      style: TextStyle(
                                                        color: t.primaryText,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (commercialRegisterFetched) ...[
                                        const SizedBox(height: 12),
                                        FeqLabeled(
                                          'حالة السجل',
                                          required: false,
                                          child: TextFormField(
                                            initialValue:
                                                commercialRegisterStatus ?? '',
                                            enabled: false,
                                            decoration:
                                                inputDecoration(context)
                                                    .copyWith(
                                              disabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: t.secondary,
                                                ),
                                              ),
                                            ),
                                            style: t.bodyLarge.copyWith(
                                              color: t.tertiaryText,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                        FeqLabeled(
                                          'تاريخ انتهاء السجل',
                                          required: false,
                                          child: TextFormField(
                                            initialValue:
                                                commercialRegisterExpiry ?? '',
                                            enabled: false,
                                            decoration:
                                                inputDecoration(context)
                                                    .copyWith(
                                              disabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: t.secondary,
                                                ),
                                              ),
                                            ),
                                            style: t.bodyLarge.copyWith(
                                              color: t.tertiaryText,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ],
                                      Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                            0,
                                            40,
                                            0,
                                            24,
                                          ),
                                          child: FFButtonWidget(
                                            onPressed:
                                                isBusinessUpdateButtonEnabled
                                                    ? _updateBusinessCertificate
                                                    : null,
                                            text: _crUpdateLoading
                                                ? 'جاري التحديث...'
                                                : 'تحديث',
                                            options: FFButtonOptions(
                                              width: 430,
                                              height: 40,
                                              color: isBusinessUpdateButtonEnabled
                                                  ? t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
                                                  : Colors.grey.shade400,
                                              textStyle:
                                                  t.titleMedium.override(
                                                fontFamily: 'Inter',
                                                color: t.containers,
                                              ),
                                              elevation: 2,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              disabledColor:
                                                  Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    // INFLUENCER SECTION
                                    if (userType == 'influencer') ...[
                                      FeqLabeled(
                                        'رقم الرخصة الإعلامية (موثوق)',
                                        required: true,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  TextFormField(
                                                    controller: _mediaController,
                                                    focusNode: _mediaFocusNode,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textInputAction:
                                                        TextInputAction.done,
                                                    decoration: inputDecoration(
                                                      context,
                                                      isError: _showMediaErrors &&
                                                          (mediaLicenseRequiredError ||
                                                              mediaLicenseFormatError ||
                                                              mediaLicenseFetchingError),
                                                    ),
                                                    style:
                                                        t.bodyLarge.copyWith(
                                                      color: t.primaryText,
                                                    ),
                                                    textAlign: TextAlign.start,
                                                  ),
                                                  if (_showMediaErrors &&
                                                      mediaLicenseRequiredError)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 6, 4, 0),
                                                      child: Text(
                                                        'يرجى إدخال رقم الرخصة.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  if (_showMediaErrors &&
                                                      mediaLicenseFormatError)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 6, 4, 0),
                                                      child: Text(
                                                        'رقم الرخصة يجب أن يكون 6 أرقام صحيحة.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  if (_showMediaErrors &&
                                                      mediaLicenseFetchingError)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 6, 4, 0),
                                                      child: Text(
                                                        'رقم الرخصة غير صحيح أو غير موجود.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: _mediaVerifyLoading
                                                  ? null
                                                  : _fetchMediaLicenseData,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: t
                                                    .secondaryButtonsOnLight,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: _mediaVerifyLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      'تحقق',
                                                      style: TextStyle(
                                                        color: t.primaryText,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (mediaLicenseFetched) ...[
                                        const SizedBox(height: 12),
                                        FeqLabeled(
                                          'حالة الرخصة',
                                          required: false,
                                          child: TextFormField(
                                            initialValue:
                                                mediaLicenseStatus ?? '',
                                            enabled: false,
                                            decoration:
                                                inputDecoration(context)
                                                    .copyWith(
                                              disabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: t.secondary,
                                                ),
                                              ),
                                            ),
                                            style: t.bodyLarge.copyWith(
                                              color: t.tertiaryText,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                        FeqLabeled(
                                          'تاريخ انتهاء الرخصة',
                                          required: false,
                                          child: TextFormField(
                                            initialValue:
                                                mediaLicenseExpiry ?? '',
                                            enabled: false,
                                            decoration:
                                                inputDecoration(context)
                                                    .copyWith(
                                              disabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: t.secondary,
                                                ),
                                              ),
                                            ),
                                            style: t.bodyLarge.copyWith(
                                              color: t.tertiaryText,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ],
                                      Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                            0,
                                            40,
                                            0,
                                            24,
                                          ),
                                          child: FFButtonWidget(
                                            onPressed:
                                                isInfluencerUpdateButtonEnabled
                                                    ? _updateMediaCertificate
                                                    : null,
                                            text: _mediaUpdateLoading
                                                ? 'جاري التحديث...'
                                                : 'تحديث',
                                            options: FFButtonOptions(
                                              width: 430,
                                              height: 40,
                                              color:
                                                  isInfluencerUpdateButtonEnabled
                                                      ? t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
                                                      : Colors.grey.shade400,
                                              textStyle:
                                                  t.titleMedium.override(
                                                fontFamily: 'Inter',
                                                color: t.containers,
                                              ),
                                              elevation: 2,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              disabledColor:
                                                  Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    if (userType != 'business' &&
                                        userType != 'influencer')
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                16, 8, 16, 16),
                                        child: Text(
                                          'نوع الحساب غير مدعوم لتحديث الوثائق حالياً.',
                                          style: t.bodyMedium,
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
                  ),
          ),
      ),
    );
  }
}
