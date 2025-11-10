import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../../../components/feq_components.dart';
import '../../../models/dropdown_list.dart';
import '../../../services/dropdown_list_loader.dart';
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
  bool _influencerContentTypeEmpty = false;
  bool _showDateErrors = false;

  late AnimationController _shakeCtrl;

  late List<DropDownList> _influencerContentTypes;
  DropDownList? _selectedInfluencerContentType;

  bool get _isEdit => widget.campaignId != null;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CampaignModel());
    _model.campaignTitleTextController ??= TextEditingController();
    _model.campaignTitleFocusNode ??= FocusNode();
    _model.detailsTextController ??= TextEditingController();
    _model.detailsFocusNode ??= FocusNode();
    _model.budgetMinTextController ??= TextEditingController();
    _model.budgetMinFocusNode ??= FocusNode();
    _model.budgetMaxTextController ??= TextEditingController();
    _model.budgetMaxFocusNode ??= FocusNode();
    _influencerContentTypes =
        DropDownListLoader.instance.influencerContentTypes;
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (_isEdit) {
      _loadCampaign();
    }
  }

  bool get _datesValid {
    if (_model.datePicked1 == null || _model.datePicked2 == null) return false;
    final start = _model.datePicked2!;
    final end = _model.datePicked1!;
    return !end.isBefore(start);
  }

  bool get _fieldsFilled {
    _influencerContentTypeEmpty = _selectedInfluencerContentType == null;
    final b =
        _model.campaignTitleTextController?.text.trim().isNotEmpty ?? false;
    final c = _model.detailsTextController?.text.trim().isNotEmpty ?? false;
    final d1 = _model.datePicked2 != null;
    final d2 = _model.datePicked1 != null;
    return !_influencerContentTypeEmpty && b && c && d1 && d2;
  }

  Future<void> _saveCampaign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على جلسة مستخدم.')),
      );
      return;
    }

    try {
      final budgetMin = int.tryParse(_model.budgetMinTextController?.text ?? '0') ?? 0;
      final budgetMax = int.tryParse(_model.budgetMaxTextController?.text ?? '0') ?? 0;

      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(widget.campaignId)
            .update({
          'title': _model.campaignTitleTextController!.text.trim(),
          'description': _model.detailsTextController!.text.trim(),
          'budget_min': budgetMin,
          'budget_max': budgetMax,
          'influencer_content_type_id': _selectedInfluencerContentType!.id,
          'start_date': Timestamp.fromDate(_model.datePicked2!),
          'end_date': Timestamp.fromDate(_model.datePicked1!),
          'active': _model.isActive,
          'visible': _model.isVisible,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الحملة بنجاح')),
        );
      } else {
        final ref = await FirebaseFirestore.instance.collection('campaigns').add({
          'business_id': uid,
          'title': _model.campaignTitleTextController!.text.trim(),
          'description': _model.detailsTextController!.text.trim(),
          'budget_min': budgetMin,
          'budget_max': budgetMax,
          'influencer_content_type_id': _selectedInfluencerContentType!.id,
          'start_date': Timestamp.fromDate(_model.datePicked2!),
          'end_date': Timestamp.fromDate(_model.datePicked1!),
          'active': _model.isActive,
          'visible': _model.isVisible,
        });

        await ref.update({'campaign_id': ref.id});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الحملة بنجاح')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحفظ: $e')),
        );
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
      _model.budgetMinTextController!.text = (m['budget_min'] ?? '0').toString();
      _model.budgetMaxTextController!.text = (m['budget_max'] ?? '0').toString();
      _model.isActive = m['active'] ?? true;
      _model.isVisible = m['visible'] ?? true;

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
            decoration: BoxDecoration(color: t.backgroundElan),
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
                                Padding(
                                  padding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                    0,
                                    5,
                                    20,
                                    5,
                                  ),
                                  child: Text(
                                    'عنوان الحملة',
                                    style: GoogleFonts.inter(
                                      textStyle: t.bodyMedium.copyWith(
                                        color: t.primaryText,
                                        fontSize: 16,
                                      ),
                                    ),
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
                                  child: TextFormField(
                                    controller: _model
                                        .campaignTitleTextController,
                                    focusNode:
                                    _model.campaignTitleFocusNode,
                                    textCapitalization:
                                    TextCapitalization.words,
                                    style: t.bodyMedium.copyWith(
                                      color: t.primaryText,
                                    ),
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: t.primaryBackground,
                                          width: 2,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: t.primary,
                                          width: 2,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(12),
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
                                      fillColor: t.primaryBackground,
                                    ),
                                    textAlign: TextAlign.end,
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'يرجى إدخال عنوان الحملة'
                                        : null,
                                  ),
                                ),

                                Padding(
                                  padding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                    0,
                                    5,
                                    20,
                                    5,
                                  ),
                                  child: Text(
                                    'تفاصيل الحملة',
                                    style: GoogleFonts.inter(
                                      textStyle: t.bodyMedium.copyWith(
                                        color: t.primaryText,
                                        fontSize: 16,
                                      ),
                                    ),
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
                                  child: TextFormField(
                                    controller:
                                    _model.detailsTextController,
                                    focusNode: _model.detailsFocusNode,
                                    maxLines: 3,
                                    style: t.bodyMedium.copyWith(
                                      color: t.primaryText,
                                    ),
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: t.primaryBackground,
                                          width: 2,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: t.primary,
                                          width: 2,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(12),
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
                                      fillColor: t.primaryBackground,
                                    ),
                                    textAlign: TextAlign.end,
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'يرجى إدخال تفاصيل الحملة'
                                        : null,
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

                                FeqLabeled(
                                  'نوع المحتوى',
                                  errorText:
                                  _showErrors && _influencerContentTypeEmpty
                                      ? 'يرجى اختيار نوع المحتوى.'
                                      : null,
                                  child: FeqSearchableDropdown<DropDownList>(
                                    items: _influencerContentTypes,
                                    value: _selectedInfluencerContentType,
                                    onChanged: (v) {
                                      setState(
                                            () =>
                                        _selectedInfluencerContentType = v,
                                      );
                                    },
                                    hint: 'اختر أو ابحث...',
                                    isError:
                                    _showErrors &&
                                        _influencerContentTypeEmpty,
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
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              Padding(
                                                padding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                  0,
                                                  16,
                                                  0,
                                                  8,
                                                ),
                                                child: FFButtonWidget(
                                                  onPressed: () async {
                                                    final picked =
                                                    await showDatePicker(
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
                                                      builder: (context,
                                                          child) =>
                                                          wrapInMaterialDatePickerTheme(
                                                            context,
                                                            child!,
                                                            headerBackgroundColor:
                                                            t.primary,
                                                            headerForegroundColor:
                                                            Colors.white,
                                                            pickerBackgroundColor:
                                                            t
                                                                .secondaryBackground,
                                                            actionButtonForegroundColor:
                                                            t.primaryText,
                                                            iconSize: 24,
                                                          ),
                                                    );
                                                    if (picked != null) {
                                                      setState(() =>
                                                      _model.datePicked1 =
                                                          DateTime(
                                                            picked.year,
                                                            picked.month,
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
                                                        color:
                                                        t.primaryText,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    elevation: 0,
                                                    borderSide: BorderSide(
                                                      color: t.tertiary,
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
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                  0,
                                                  16,
                                                  0,
                                                  8,
                                                ),
                                                child: FFButtonWidget(
                                                  onPressed: () async {
                                                    final picked =
                                                    await showDatePicker(
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
                                                      builder: (context,
                                                          child) =>
                                                          wrapInMaterialDatePickerTheme(
                                                            context,
                                                            child!,
                                                            headerBackgroundColor:
                                                            t.primary,
                                                            headerForegroundColor:
                                                            Colors.white,
                                                            pickerBackgroundColor:
                                                            t
                                                                .secondaryBackground,
                                                            actionButtonForegroundColor:
                                                            t.primaryText,
                                                            iconSize: 24,
                                                          ),
                                                    );
                                                    if (picked != null) {
                                                      setState(() =>
                                                      _model.datePicked2 =
                                                          DateTime(
                                                            picked.year,
                                                            picked.month,
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
                                                        color:
                                                        t.primaryText,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    elevation: 0,
                                                    borderSide: BorderSide(
                                                      color: t.tertiary,
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
                                                    () =>
                                                _model.isVisible = val,
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
                                          onPressed: () async {
                                            setState(() {
                                              _showErrors = true;
                                              _showDateErrors = true;
                                            });

                                            if (!_fieldsFilled) {
                                              _formKey.currentState!
                                                  .validate();
                                              _shakeCtrl.forward(from: 0);
                                              return;
                                            }

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
                                                      child: const Text(
                                                        'حسنًا',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }

                                            await _saveCampaign();
                                          },
                                          text: _isEdit ? 'تحديث' : 'إضافة',
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
                                            BorderRadius.circular(
                                              12,
                                            ),
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
}