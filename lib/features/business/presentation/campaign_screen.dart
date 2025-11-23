import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/features/business/presentation/subscription_info_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../../../services/subscription_service.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../data/models/campaign_model.dart';

Widget wrapInMaterialDatePickerTheme(
  BuildContext context,
  Widget child, {
  Color? headerBackgroundColor,
  Color? headerForegroundColor,
  TextStyle? headerTextStyle,
  Color? pickerBackgroundColor,
  Color? pickerForegroundColor,
  Color? selectedDateTimeBackgroundColor,
  Color? selectedDateTimeForegroundColor,
  Color? actionButtonForegroundColor,
  double? iconSize,
}) {
  final theme = Theme.of(context);
  final t = FlutterFlowTheme.of(context);

  final headerBg = headerBackgroundColor ?? t.primary;
  final headerFg = headerForegroundColor ?? Colors.white;
  final pickerBg = pickerBackgroundColor ?? t.secondaryBackground;
  final actionFg = actionButtonForegroundColor ?? t.primaryText;

  return Theme(
    data: theme.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: pickerBg,
        surfaceTintColor: Colors.transparent,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: actionFg),
      ),
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: headerBg,
        headerForegroundColor: headerFg,
        headerHeadlineStyle: GoogleFonts.interTight(
          textStyle: t.displayLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 32,
            color: headerFg,
          ),
        ),
      ),
      iconTheme: theme.iconTheme.copyWith(
        size: iconSize ?? theme.iconTheme.size,
      ),
    ),
    child: child,
  );
}

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key, this.campaignId});

  static const String routeName = 'business-campaign';
  static const String routePath = '/$routeName';

  final String? campaignId;

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen>
    with SingleTickerProviderStateMixin {
  late CampaignModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showErrors = false;
  final bool _influencerContentTypeEmpty = false;
  bool _showDateErrors = false;

  late AnimationController _shakeCtrl;

  late List<FeqDropDownList> _influencerContentTypes;
  FeqDropDownList? _selectedInfluencerContentType;

  late List<FeqDropDownList> _socialPlatforms;
  FeqDropDownList? _selectedPlatform;

  bool get _isEdit => widget.campaignId != null;

  /*
  String _convertFromArabicNumbers(String input) {
    const Map<String, String> englishMap = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    return input.split('').map((char) => englishMap[char] ?? char).join('');
  }
  */

  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _canEditExpiredCampaign = false; // Check subscription allows editing
  String _editRestrictionMessage = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CampaignModel());
    _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;
    _model.campaignTitleTextController ??= TextEditingController();
    _model.campaignTitleFocusNode ??= FocusNode();
    _model.detailsTextController ??= TextEditingController();
    _model.detailsFocusNode ??= FocusNode();
    /*
    _model.budgetMinTextController ??= TextEditingController();
    _model.budgetMinFocusNode ??= FocusNode();
    _model.budgetMaxTextController ??= TextEditingController();
    _model.budgetMaxFocusNode ??= FocusNode();
    */
    _influencerContentTypes =
        FeqDropDownListLoader.instance.influencerContentTypes;
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (_isEdit) {
      _loadCampaign();
      _checkSubscriptionForExpiredEdit();
    }
  }

  bool get _datesValid {
    if (_model.datePicked1 == null || _model.datePicked2 == null) return false;
    final start = _model.datePicked2!;
    final end = _model.datePicked1!;
    return !end.isBefore(start);
  }

  /*
  bool get _budgetValid {
    final minStr = _convertFromArabicNumbers(_model.budgetMinTextController?.text ?? '0');
    final maxStr = _convertFromArabicNumbers(_model.budgetMaxTextController?.text ?? '0');

    final min = int.tryParse(minStr) ?? 0;
    final max = int.tryParse(maxStr) ?? 0;

    return max >= min;
  }
  */

  Future<void> _saveCampaign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على جلسة مستخدم.')),
      );
      return;
    }

    try {
      /*
      final budgetMinStr = _convertFromArabicNumbers(_model.budgetMinTextController?.text ?? '0');
      final budgetMaxStr = _convertFromArabicNumbers(_model.budgetMaxTextController?.text ?? '0');
      final budgetMin = int.tryParse(budgetMinStr) ?? 0;
      final budgetMax = int.tryParse(budgetMaxStr) ?? 0;
      */

      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(widget.campaignId)
            .update({
              'title': _model.campaignTitleTextController!.text.trim(),
              'description': _model.detailsTextController!.text.trim(),
              // 'budget_min': budgetMin,
              // 'budget_max': budgetMax,
              'platform_id': _selectedPlatform?.id,
              'platform_name': _selectedPlatform?.nameAr,
              'influencer_content_type_id': _selectedInfluencerContentType!.id,
              'start_date': Timestamp.fromDate(_model.datePicked2!),
              'end_date': Timestamp.fromDate(_model.datePicked1!),
              'active': _model.isActive,
              'visible': _model.isVisible,
            });

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث الحملة بنجاح')));
      } else {
        final ref = await FirebaseFirestore.instance
            .collection('campaigns')
            .add({
              'business_id': uid,
              'title': _model.campaignTitleTextController!.text.trim(),
              'description': _model.detailsTextController!.text.trim(),
              // 'budget_min': budgetMin,
              // 'budget_max': budgetMax,
              'platform_id': _selectedPlatform?.id,
              'platform_name': _selectedPlatform?.nameAr,
              'influencer_content_type_id': _selectedInfluencerContentType!.id,
              'start_date': Timestamp.fromDate(_model.datePicked2!),
              'end_date': Timestamp.fromDate(_model.datePicked1!),
              'active': _model.isActive,
              'visible': _model.isVisible,
            });

        await ref.update({'campaign_id': ref.id});

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة الحملة بنجاح')));
      }

      Navigator.of(
        context,
      ).pop(true); // Return true for successful creation/update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
      }
    }
  }

  String _fmtChosen(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  double _shakeOffset() {
    if (!_shakeCtrl.isAnimating) return 0;
    return math.sin(_shakeCtrl.value * 10 * math.pi) * 8;
  }

  Future<void> _loadCampaign() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .get();

      if (!doc.exists) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على هذه الحملة')),
          );
        }
        return;
      }

      final m = doc.data()!;
      final influencerContentTypeIdRaw = m['influencer_content_type_id'];
      int influencerContentTypeId = 0;
      if (influencerContentTypeIdRaw is int) {
        influencerContentTypeId = influencerContentTypeIdRaw;
      } else if (influencerContentTypeIdRaw is String &&
          influencerContentTypeIdRaw.isNotEmpty) {
        influencerContentTypeId = int.tryParse(influencerContentTypeIdRaw) ?? 0;
      }
      _selectedInfluencerContentType = _influencerContentTypes.firstWhere(
        (c) => c.id == influencerContentTypeId,
        orElse: () => _influencerContentTypes.first,
      );
      _model.campaignTitleTextController!.text = (m['title'] ?? '').toString();
      _model.detailsTextController!.text = (m['description'] ?? '').toString();

      /*
      final minBudget = (m['budget_min'] ?? 0).toString();
      final maxBudget = (m['budget_max'] ?? 0).toString();
      _model.budgetMinTextController!.text = (minBudget);
      _model.budgetMaxTextController!.text = (maxBudget);
      */

      _model.isActive = m['active'] ?? true;
      _model.isVisible = m['visible'] ?? true;

      // Load platform
      final platformIdRaw = m['platform_id'];
      int platformId = 0;
      if (platformIdRaw is int) {
        platformId = platformIdRaw;
      } else if (platformIdRaw is String && platformIdRaw.isNotEmpty) {
        platformId = int.tryParse(platformIdRaw) ?? 0;
      }
      if (platformId > 0) {
        _selectedPlatform = _socialPlatforms.firstWhere(
              (p) => p.id == platformId,
          orElse: () => _socialPlatforms.first,
        );
      }

      final s = m['start_date'];
      final e = m['end_date'];
      if (s is Timestamp) _model.datePicked2 = s.toDate();
      if (e is Timestamp) _model.datePicked1 = e.toDate();

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل جلب البيانات: $e')));
      }
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _model.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final title = _model.campaignTitleTextController?.text.trim() ?? '';
    final details = _model.detailsTextController?.text.trim() ?? '';
    final platformSelected = _selectedPlatform != null;

    if (title.isEmpty) return false;
    if (details.isEmpty) return false;
    if (!platformSelected) return false;
    if (_selectedInfluencerContentType == null) return false;
    if (!_datesValid) return false;

    return true;
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
          _isEdit ? 'تحديث الحملة' : 'إضافة حملة',
          style: GoogleFonts.interTight(
            textStyle: t.headlineSmall.copyWith(color: t.primaryText),
          ),
        ),
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
                    size: 22,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isEdit && _model.datePicked1 != null
                        ? (_model.datePicked1!.isBefore(DateTime.now())
                        ? Color(0xFFFEE2E2)  // Light red if campaign expired
                        : t.backgroundElan)  // Normal background if not expired
                        : t.backgroundElan,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _showErrors
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SubscriptionInfoWidget(
                              isEditMode: _isEdit,
                              currentCampaignExpiryDate: _model.datePicked1,
                            ),

                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                16,
                                16,
                                0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: t.containers,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    0,
                                    16,
                                    0,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // ... rest of your existing form fields ...
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                16,
                                16,
                                0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: t.containers,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    0,
                                    16,
                                    0,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // TITLE FIELD - Show disabled if expired campaign and can't edit
                                      if (_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) ...[
                                        _buildDisabledTextField(
                                          'عنوان الحملة',
                                          _model.campaignTitleTextController?.text ?? 'غير محدد',
                                        ),
                                      ] else ...[
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                          child: FeqLabeled('عنوان الحملة'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                          child: TextFormField(
                                            controller: _model.campaignTitleTextController,
                                            focusNode: _model.campaignTitleFocusNode,
                                            enabled: !(_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign),
                                            textCapitalization: TextCapitalization.words,
                                            style: t.bodyMedium.copyWith(color: t.primaryText),
                                            decoration: InputDecoration(
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: t.primaryBackground,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              disabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFFE5E7EB),
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: t.primary,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              errorBorder: const OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.red, width: 2),
                                              ),
                                              focusedErrorBorder: const OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.red, width: 2),
                                              ),
                                              filled: true,
                                              fillColor: t.primaryBackground,
                                            ),
                                            textAlign: TextAlign.end,
                                            validator: (v) =>
                                            (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان الحملة' : null,
                                          ),
                                        ),
                                      ],

// DETAILS FIELD - Same disabled logic
                                      if (_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) ...[
                                        _buildDisabledTextField(
                                          'تفاصيل الحملة',
                                          _model.detailsTextController?.text ?? 'غير محدد',
                                        ),
                                      ] else ...[
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                          child: FeqLabeled('تفاصيل الحملة'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                          child: TextFormField(
                                            controller: _model.detailsTextController,
                                            focusNode: _model.detailsFocusNode,
                                            enabled: !(_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign),
                                            maxLines: 3,
                                            style: t.bodyMedium.copyWith(color: t.primaryText),
                                            decoration: InputDecoration(
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: t.primaryBackground,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              disabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFFE5E7EB),
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: t.primary,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              errorBorder: const OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.red, width: 2),
                                              ),
                                              focusedErrorBorder: const OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.red, width: 2),
                                              ),
                                              filled: true,
                                              fillColor: t.primaryBackground,
                                            ),
                                            textAlign: TextAlign.end,
                                            validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? 'يرجى إدخال تفاصيل الحملة'
                                                : null,
                                          ),
                                        ),
                                      ],

// PLATFORM FIELD - Same disabled logic
                                      if (_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) ...[
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                          child: FeqLabeled('اختر المنصة'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Color(0xFFE5E7EB),
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _selectedPlatform?.nameAr ?? 'غير محدد',
                                                  style: t.bodyMedium.copyWith(
                                                    color: Color(0xFF9CA3AF),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                Icon(Icons.lock, color: Color(0xFF9CA3AF), size: 18),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                          child: FeqLabeled('اختر المنصة'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                          child: FeqSearchableDropdown<FeqDropDownList>(
                                            items: _socialPlatforms,
                                            value: _selectedPlatform,
                                            onChanged: (v) {
                                              setState(() => _selectedPlatform = v);
                                            },
                                            hint: 'اختر المنصة',
                                            isError: false,
                                          ),
                                        ),
                                      ],

// CONTENT TYPE - Same disabled logic
                                      if (_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) ...[
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Color(0xFFE5E7EB),
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _selectedInfluencerContentType?.nameAr ?? 'غير محدد',
                                                  style: t.bodyMedium.copyWith(
                                                    color: Color(0xFF9CA3AF),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                Icon(Icons.lock, color: Color(0xFF9CA3AF), size: 18),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        FeqLabeled(
                                          'نوع المحتوى',
                                          errorText: _showErrors && _influencerContentTypeEmpty
                                              ? 'يرجى اختيار نوع المحتوى.'
                                              : null,
                                          child: FeqSearchableDropdown<FeqDropDownList>(
                                            items: _influencerContentTypes,
                                            value: _selectedInfluencerContentType,
                                            onChanged: (v) {
                                              setState(() => _selectedInfluencerContentType = v);
                                            },
                                            hint: 'اختر أو ابحث...',
                                            isError: _showErrors && _influencerContentTypeEmpty,
                                          ),
                                        ),
                                      ],

                                      /*
                                Padding(
                                  padding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                    20,
                                    0,
                                    20,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'الحد الأقصى للميزانية',
                                              style: GoogleFonts.inter(
                                                textStyle: t.bodyMedium
                                                    .copyWith(
                                                  color: t.primaryText,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _model
                                                  .budgetMaxTextController,
                                              focusNode:
                                              _model.budgetMaxFocusNode,
                                              keyboardType:
                                              TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(
                                                  RegExp(r'[0-9]'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {});
                                              },
                                              style: t.bodyMedium.copyWith(
                                                color: t.primaryText,
                                              ),
                                              decoration: InputDecoration(
                                                enabledBorder:
                                                OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: t
                                                        .primaryBackground,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                                ),
                                                focusedBorder:
                                                OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: t.primary,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                                ),
                                                errorBorder:
                                                const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                                focusedErrorBorder:
                                                const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                                filled: true,
                                                fillColor:
                                                t.primaryBackground,
                                              ),
                                              textAlign: TextAlign.end,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'الحد الأدنى للميزانية',
                                              style: GoogleFonts.inter(
                                                textStyle: t.bodyMedium
                                                    .copyWith(
                                                  color: t.primaryText,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _model
                                                  .budgetMinTextController,
                                              focusNode:
                                              _model.budgetMinFocusNode,
                                              keyboardType:
                                              TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(
                                                  RegExp(r'[0-9]'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {});
                                              },
                                              style: t.bodyMedium.copyWith(
                                                color: t.primaryText,
                                              ),
                                              decoration: InputDecoration(
                                                enabledBorder:
                                                OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: t
                                                        .primaryBackground,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                                ),
                                                focusedBorder:
                                                OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: t.primary,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                                ),
                                                errorBorder:
                                                const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                                focusedErrorBorder:
                                                const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                ),
                                                filled: true,
                                                fillColor:
                                                t.primaryBackground,
                                              ),
                                              textAlign: TextAlign.end,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (_showErrors && !_budgetValid)
                                  Padding(
                                    padding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                      20,
                                      0,
                                      20,
                                      16,
                                    ),
                                    child: const Text(
                                      'الحد الأقصى يجب أن يكون أكبر من أو يساوي الحد الأدنى',
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                */

                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              0,
                                              0,
                                              0,
                                              16,
                                            ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Column(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional.fromSTEB(
                                                            0,
                                                            16,
                                                            0,
                                                            8,
                                                          ),
                                                      child: FFButtonWidget(
                                                        onPressed: () async {
                                                          final picked = await showDatePicker(
                                                            context: context,
                                                            initialDate:
                                                                _model
                                                                    .datePicked1 ??
                                                                DateTime.now(),
                                                            firstDate: DateTime(
                                                              1900,
                                                            ),
                                                            lastDate: DateTime(
                                                              2050,
                                                            ),
                                                            builder: (context, child) => wrapInMaterialDatePickerTheme(
                                                              context,
                                                              child!,
                                                              headerBackgroundColor:
                                                                  t.primary,
                                                              headerForegroundColor:
                                                                  Colors.white,
                                                              pickerBackgroundColor:
                                                                  t.secondaryBackground,
                                                              actionButtonForegroundColor:
                                                                  t.primaryText,
                                                              iconSize: 24,
                                                            ),
                                                          );
                                                          if (picked != null) {
                                                            setState(
                                                              () => _model.datePicked1 =
                                                                  DateTime(
                                                                    picked.year,
                                                                    picked
                                                                        .month,
                                                                    picked.day,
                                                                  ),
                                                            );
                                                          }
                                                        },
                                                        text: 'تاريخ الإنتهاء',
                                                        options: FFButtonOptions(
                                                          width: 140,
                                                          height: 50,
                                                          color: t.tertiary,
                                                          textStyle:
                                                              GoogleFonts.inter(
                                                                textStyle: t
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                      color: t
                                                                          .primaryText,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                              ),
                                                          elevation: 0,
                                                          borderSide:
                                                              BorderSide(
                                                                color:
                                                                    t.tertiary,
                                                                width: 2,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (_model.datePicked1 !=
                                                        null)
                                                      Text(
                                                        'تم اختيار ${_fmtChosen(_model.datePicked1)}',
                                                        style: t.labelMedium
                                                            .copyWith(
                                                              color:
                                                                  t.primaryText,
                                                            ),
                                                      )
                                                    else if (_showDateErrors)
                                                      const Text(
                                                        'يرجى اختيار تاريخ الإنتهاء',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                  ],
                                                ),

                                                Column(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional.fromSTEB(
                                                            0,
                                                            16,
                                                            0,
                                                            8,
                                                          ),
                                                      child: FFButtonWidget(
                                                        onPressed: () async {
                                                          final picked = await showDatePicker(
                                                            context: context,
                                                            initialDate:
                                                                _model
                                                                    .datePicked2 ??
                                                                DateTime.now(),
                                                            firstDate: DateTime(
                                                              1900,
                                                            ),
                                                            lastDate:
                                                                DateTime.now(),
                                                            builder: (context, child) => wrapInMaterialDatePickerTheme(
                                                              context,
                                                              child!,
                                                              headerBackgroundColor:
                                                                  t.primary,
                                                              headerForegroundColor:
                                                                  Colors.white,
                                                              pickerBackgroundColor:
                                                                  t.secondaryBackground,
                                                              actionButtonForegroundColor:
                                                                  t.primaryText,
                                                              iconSize: 24,
                                                            ),
                                                          );
                                                          if (picked != null) {
                                                            setState(
                                                              () => _model.datePicked2 =
                                                                  DateTime(
                                                                    picked.year,
                                                                    picked
                                                                        .month,
                                                                    picked.day,
                                                                  ),
                                                            );
                                                          }
                                                        },
                                                        text: 'تاريخ البدء',
                                                        options: FFButtonOptions(
                                                          width: 140,
                                                          height: 50,
                                                          color: t.tertiary,
                                                          textStyle:
                                                              GoogleFonts.inter(
                                                                textStyle: t
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                      color: t
                                                                          .primaryText,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                              ),
                                                          elevation: 0,
                                                          borderSide:
                                                              BorderSide(
                                                                color:
                                                                    t.tertiary,
                                                                width: 2,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (_model.datePicked2 !=
                                                        null)
                                                      Text(
                                                        'تم اختيار ${_fmtChosen(_model.datePicked2)}',
                                                        style: t.labelMedium
                                                            .copyWith(
                                                              color:
                                                                  t.primaryText,
                                                            ),
                                                      )
                                                    else if (_showDateErrors)
                                                      const Text(
                                                        'يرجى اختيار تاريخ البدء',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            if (_showErrors &&
                                                _model.datePicked1 != null &&
                                                _model.datePicked2 != null &&
                                                !_datesValid)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  'ادخل تواريخ صحيحة',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              20,
                                              0,
                                              20,
                                              16,
                                            ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Switch(
                                                  value: _model.isVisible,
                                                  onChanged: (val) {
                                                    setState(
                                                      () => _model.isVisible =
                                                          val,
                                                    );
                                                  },
                                                  activeThumbColor: t.primary,
                                                ),
                                                Text(
                                                  'ظاهر',
                                                  style: GoogleFonts.inter(
                                                    textStyle: t.bodyMedium
                                                        .copyWith(
                                                          color: t.primaryText,
                                                          fontSize: 14,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Switch(
                                                  value: _model.isActive,
                                                  onChanged: (val) {
                                                    setState(
                                                      () =>
                                                          _model.isActive = val,
                                                    );
                                                  },
                                                  activeThumbColor: t.primary,
                                                ),
                                                Text(
                                                  'نشط',
                                                  style: GoogleFonts.inter(
                                                    textStyle: t.bodyMedium
                                                        .copyWith(
                                                          color: t.primaryText,
                                                          fontSize: 14,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign)
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Color(0xFFFCA5A5), width: 1),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'الحملة منتهية الصلاحية',
                                                        style: t.bodySmall.copyWith(
                                                          color: Color(0xFFDC2626),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _editRestrictionMessage,
                                                        style: t.bodySmall.copyWith(
                                                          color: Color(0xFFDC2626),
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 20),
                                              ],
                                            ),
                                          ),
                                        ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsetsDirectional.fromSTEB(
                                                  0,
                                                  16,
                                                  0,
                                                  24,
                                                ),
                                            child: FFButtonWidget(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              text: 'إلغاء',
                                              options: FFButtonOptions(
                                                width: 90,
                                                height: 40,
                                                color: t.secondary,
                                                textStyle: GoogleFonts.interTight(
                                                  textStyle: t.titleMedium
                                                      .copyWith(
                                                        color: t
                                                            .secondaryBackground,
                                                        fontSize: 20,
                                                      ),
                                                ),
                                                elevation: 2,
                                                borderSide: const BorderSide(
                                                  color: Colors.transparent,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
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
                                                    ? () async {
                                                        setState(() {
                                                          _showErrors = true;
                                                          _showDateErrors =
                                                              true;
                                                        });

                                                        if (!_datesValid) {
                                                          await showDialog(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              title: const Text(
                                                                'تصحيح التواريخ',
                                                              ),
                                                              content: const Text(
                                                                'تاريخ الانتهاء يجب ألا يكون قبل تاريخ البدء.',
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                        ctx,
                                                                      ).pop(),
                                                                  child:
                                                                      const Text(
                                                                        'حسنًا',
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          return;
                                                        }

                                                        /*
                                            if (!_budgetValid) {
                                              await showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'تصحيح الميزانية',
                                                  ),
                                                  content: const Text(
                                                    'الحد الأقصى للميزانية يجب أن يكون أكبر من أو يساوي الحد الأدنى.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                      child: const Text(
                                                        'حسنًا',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }
                                            */

                                                        await _saveCampaign();
                                                      }
                                                    : null,
                                                text: _isEdit
                                                    ? 'تحديث'
                                                    : 'إضافة',
                                                options: FFButtonOptions(
                                                  width: 200,
                                                  height: 40,
                                                  color: t
                                                      .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                  textStyle:
                                                      GoogleFonts.interTight(
                                                        textStyle: t.titleMedium
                                                            .copyWith(
                                                              color:
                                                                  t.containers,
                                                              fontSize: 20,
                                                            ),
                                                      ),
                                                  elevation: 2,
                                                  borderSide: const BorderSide(
                                                    color: Colors.transparent,
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
            ),
    );
  }

  // Check if subscription allows editing an expired campaign
  Future<void> _checkSubscriptionForExpiredEdit() async {
    try {
      final canEdit = await _subscriptionService.canCreateCampaign();
      setState(() async {
        _canEditExpiredCampaign = canEdit;
        if (!canEdit) {
          final subscription = await _subscriptionService.getSubscription();
          if (subscription == null) {
            _editRestrictionMessage = 'لا توجد باقة اشتراك. لا يمكنك تعديل الحملات.';
          } else {
            final planType = subscription['plan_type'] as String? ?? '';
            if (planType == 'premium') {
              _editRestrictionMessage = 'انتهت صلاحية الاشتراك. لا يمكنك تعديل الحملات.';
            } else if (planType == 'basic') {
              _editRestrictionMessage = 'لم تعد لديك حملات متاحة. لا يمكنك تعديل الحملات.';
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _canEditExpiredCampaign = false;
        _editRestrictionMessage = 'فشل التحقق من الاشتراك.';
      });
    }
  }

// Check if campaign is expired
  bool _isCampaignExpired() {
    return _model.datePicked1 != null &&
        _model.datePicked1!.isBefore(DateTime.now());
  }

// Build a disabled text field widget
  Widget _buildDisabledTextField(String label, String value) {
    final t = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
          child: FeqLabeled(label),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: t.bodyMedium.copyWith(
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Icon(Icons.lock, color: Color(0xFF9CA3AF), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
