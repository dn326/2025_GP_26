import 'dart:math' as math;

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../models/experience_add_model.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// ===================== Helpers محلية =====================
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
      dialogTheme: DialogThemeData(backgroundColor: pickerBg, surfaceTintColor: Colors.transparent),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: actionFg)),
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: headerBg,
        headerForegroundColor: headerFg,
        headerHeadlineStyle: GoogleFonts.interTight(
          textStyle: t.displayLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 32, color: headerFg),
        ),
      ),
      iconTheme: theme.iconTheme.copyWith(size: iconSize ?? theme.iconTheme.size),
    ),
    child: child,
  );
}

extension FFValidatorAdapter on String? Function(BuildContext, String?)? {
  FormFieldValidator<String>? asValidator(BuildContext context) {
    final fn = this;
    if (fn == null) return null;
    return (val) => fn(context, val);
  }
}

extension DivideExtension on List<Widget> {
  List<Widget> divide(Widget gap) {
    if (isEmpty) return this;
    final out = <Widget>[];
    for (var i = 0; i < length; i++) {
      out.add(this[i]);
      if (i != length - 1) out.add(gap);
    }
    return out;
  }
}

/// =========================================================

class InfluncerAddExperienceWidget extends StatefulWidget {
  const InfluncerAddExperienceWidget({super.key});

  static String routeName = 'influncer_add_experience';
  static String routePath = '/influncerAddExperience';

  @override
  State<InfluncerAddExperienceWidget> createState() => _InfluncerAddExperienceWidgetState();
}

class _InfluncerAddExperienceWidgetState extends State<InfluncerAddExperienceWidget>
    with SingleTickerProviderStateMixin {
  late InfluncerAddExperienceModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // فورم + تحقّق
  final _formKey = GlobalKey<FormState>();
  bool _showErrors = false; // لإظهار الأخطاء بعد الضغط فقط
  bool _nameEmpty = false;
  bool _showDateErrors = false; // رسائل التاريخ تحت الأزرار

  // أنيميشن هزّة زر الإضافة عند الفشل
  late AnimationController _shakeCtrl;

  late List<FeqDropDownList> _saudiCompanies;
  FeqDropDownList? _selectedSaudiCompany;

  late List<FeqDropDownList> _socialPlatforms;
  late List<FeqDropDownList> _socialPlatformsSelected = [];
  FeqDropDownList? _selectedPlatform;
  bool _sameDayCompletion = true;
  bool _useCustomCompany = false;
  final TextEditingController _customCompanyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfluncerAddExperienceModel());
    _saudiCompanies = FeqDropDownListLoader.instance.saudiCompanies;
    _socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;
    _model.campaignTitleTextController ??= TextEditingController();
    _model.campaignTitleFocusNode ??= FocusNode();

    _model.detailsTextController ??= TextEditingController();
    _model.detailsFocusNode ??= FocusNode();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _loadUserSocialPlatforms();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadUserSocialPlatforms() async {
    final socials = await loadSocials();

    _socialPlatformsSelected = socials.map((e) {
      return _socialPlatforms.firstWhere(
            (p) => p.id.toString() == e['platform'],
        orElse: () => FeqDropDownList(id: 0, nameEn: '', nameAr: '', domain: ''),
      );
    }).toList();

    setState(() {});
  }

  Future<List<Map<String, String>>> loadSocials() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('No logged-in user');
    final usersRef = firebaseFirestore.collection('users').doc(uid);

    // Run both queries in parallel
    final results = await Future.wait([
      firebaseFirestore
          .collection('social_account')
          .where('influencer_id', isEqualTo: uid)
          .get(),
      firebaseFirestore
          .collection('social_account')
          .where('influencer_id', isEqualTo: usersRef)
          .get(),
    ]);

    // Combine both snapshots
    final allDocs = {
      for (var doc in [...results[0].docs, ...results[1].docs]) doc.id: doc
    }.values.toList(); // remove duplicates by using doc.id as key

    // Convert to simple map models
    return allDocs
        .map((d) {
      final m = d.data();
      return {
        'platform': (m['platform'] ?? m['platform_name'] ?? '').toString(),
        'username': (m['username'] ?? '').toString(),
      };
    })
        .where((e) =>
    (e['platform'] ?? '').isNotEmpty ||
        (e['username'] ?? '').isNotEmpty)
        .toList();
  }

  void _syncEndDateWithStartDate() {
    if (_sameDayCompletion && _model.datePicked2 != null) {
      setState(() => _model.datePicked1 = _model.datePicked2);
    }
  }

  bool get _datesValid {
    if (_model.datePicked1 == null || _model.datePicked2 == null) return false;
    // end >= start
    final start = _model.datePicked2!;
    final end = _model.datePicked1!;
    return !end.isBefore(start);
  }

  bool get _fieldsFilled {
    // Check company: either select from list OR enter custom company
    final companySelected = _useCustomCompany
        ? (_customCompanyController.text.trim().isNotEmpty)
        : (_selectedSaudiCompany != null);
    _nameEmpty = !companySelected;

    // Check other required fields
    final campaignTitle = _model.campaignTitleTextController?.text.trim().isNotEmpty ?? false;
    final details = _model.detailsTextController?.text.trim().isNotEmpty ?? false;
    final startDatePicked = _model.datePicked2 != null;
    final endDatePicked = _model.datePicked1 != null;
    final platformSelected = _selectedPlatform != null;

    return companySelected && campaignTitle && details && startDatePicked && endDatePicked && platformSelected;
  }

  Future<void> _saveExperience() async {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على جلسة مستخدم.')),
      );
      return;
    }

    try {
      final companyId = _useCustomCompany ? null : _selectedSaudiCompany!.id;
      final companyName = _useCustomCompany
          ? _customCompanyController.text.trim()
          : _selectedSaudiCompany!.nameAr;

      final data = {
        'company_name': companyName,
        'campaign_title': _model.campaignTitleTextController!.text.trim(),
        'details': _model.detailsTextController!.text.trim(),
        'start_date': Timestamp.fromDate(_model.datePicked2!),
        'end_date': Timestamp.fromDate(_model.datePicked1!),
        'influencer_id': uid,
        'platform_id': _selectedPlatform?.id,
        'platform_name': _selectedPlatform?.nameAr,
      };

      if (!_useCustomCompany) {
        data['company_id'] = companyId;
      } else {
        data['company_other'] = companyName;
      }

      final ref = await firebaseFirestore.collection('experiences').add(data);
      await ref.update({'experience_id': ref.id});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الخبرة بنجاح')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    }
  }

  String _fmtChosen(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    // دالة هزّة خفيفة بالـ X
    double shakeOffset() {
      if (!_shakeCtrl.isAnimating) return 0;
      final v = _shakeCtrl.value; // 0..1
      return math.sin(v * 10 * math.pi) * 8;
      // سعة 8 بكسل
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(
        title: 'إضافة عمل إعلاني',
        showBack: true,
      ),
      body: SafeArea(
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
                  autovalidateMode: _showErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.containers,
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // الشركة / المنظمة
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 20, 5),
                                  child: FeqLabeled('الشركة / المنظمة'),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!_useCustomCompany)
                                        FeqSearchableDropdown<FeqDropDownList>(
                                          items: _saudiCompanies,
                                          value: _selectedSaudiCompany,
                                          onChanged: (v) {
                                            setState(() => _selectedSaudiCompany = v);
                                          },
                                          hint: 'اختر أو ابحث...',
                                          isError: _showErrors && _nameEmpty,
                                        )
                                      else
                                        TextFormField(
                                          controller: _customCompanyController,
                                          textCapitalization: TextCapitalization.words,
                                          style: t.bodyMedium.copyWith(color: t.primaryText),
                                          decoration: InputDecoration(
                                            enabledBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(color: t.primaryBackground, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: t.primary, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            errorBorder: const OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.red, width: 2),
                                            ),
                                            filled: true,
                                            fillColor: t.primaryBackground,
                                            hintText: 'أدخل اسم الشركة',
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: InkWell(
                                          onTap: () {
                                            setState(
                                                  () {
                                                _useCustomCompany = !_useCustomCompany;
                                                if (!_useCustomCompany) {
                                                  _customCompanyController.clear();
                                                } else {
                                                  _selectedSaudiCompany = null;
                                                }
                                              },
                                            );
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                _useCustomCompany
                                                    ? 'اختر من قائمة الشركات'
                                                    : 'أضف شركة جديدة',
                                                style: t.bodySmall.copyWith(
                                                  color: t.primary,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // عنوان الحملة
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                  child: FeqLabeled('عنوان الحملة'),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                  child: TextFormField(
                                    controller: _model.campaignTitleTextController,
                                    focusNode: _model.campaignTitleFocusNode,
                                    textCapitalization: TextCapitalization.words,
                                    style: t.bodyMedium.copyWith(color: t.primaryText),
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: t.primaryBackground, width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: t.primary, width: 2),
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

                                // التاريخان
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          // End Date
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 8),
                                                child: FFButtonWidget(
                                                  onPressed: _sameDayCompletion
                                                      ? null
                                                      : () async {
                                                    final picked = await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                      _model.datePicked1 ?? DateTime.now(),
                                                      firstDate: DateTime(1900),
                                                      lastDate: DateTime(2050),
                                                      builder: (context, child) =>
                                                          wrapInMaterialDatePickerTheme(
                                                            context,
                                                            child!,
                                                            headerBackgroundColor: t.primary,
                                                            headerForegroundColor: Colors.white,
                                                            pickerBackgroundColor: t.secondaryBackground,
                                                            actionButtonForegroundColor: t.primaryText,
                                                            iconSize: 24,
                                                          ),
                                                    );
                                                    if (picked != null) {
                                                      setState(
                                                            () => _model.datePicked1 = DateTime(
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
                                                    color: _sameDayCompletion
                                                        ? t.tertiary.withValues(alpha: 0.5)
                                                        : t.tertiary,
                                                    textStyle: GoogleFonts.inter(
                                                      textStyle: t.bodyMedium.copyWith(
                                                        color: t.primaryText,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    elevation: 0,
                                                    borderSide: BorderSide(
                                                      color: _sameDayCompletion
                                                          ? t.tertiary.withValues(alpha: 0.5)
                                                          : t.tertiary,
                                                      width: 2,
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              ),
                                              if (_model.datePicked1 != null)
                                                Text(
                                                  'تم اختيار ${_fmtChosen(_model.datePicked1)}',
                                                  style: t.labelMedium.copyWith(color: t.primaryText),
                                                )
                                              else if (_showDateErrors)
                                                const Text(
                                                  'يرجى اختيار تاريخ الإنتهاء',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                            ],
                                          ),
                                          // Start Date
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 8),
                                                child: FFButtonWidget(
                                                  onPressed: () async {
                                                    final picked = await showDatePicker(
                                                      context: context,
                                                      initialDate: _model.datePicked2 ?? DateTime.now(),
                                                      firstDate: DateTime(1900),
                                                      lastDate: DateTime.now(),
                                                      builder: (context, child) =>
                                                          wrapInMaterialDatePickerTheme(
                                                            context,
                                                            child!,
                                                            headerBackgroundColor: t.primary,
                                                            headerForegroundColor: Colors.white,
                                                            pickerBackgroundColor: t.secondaryBackground,
                                                            actionButtonForegroundColor: t.primaryText,
                                                            iconSize: 24,
                                                          ),
                                                    );
                                                    if (picked != null) {
                                                      setState(
                                                            () => _model.datePicked2 = DateTime(
                                                          picked.year,
                                                          picked.month,
                                                          picked.day,
                                                        ),
                                                      );
                                                      _syncEndDateWithStartDate();
                                                    }
                                                  },
                                                  text: 'تاريخ البدء',
                                                  options: FFButtonOptions(
                                                    width: 140,
                                                    height: 50,
                                                    color: t.tertiary,
                                                    textStyle: GoogleFonts.inter(
                                                      textStyle: t.bodyMedium.copyWith(
                                                        color: t.primaryText,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    elevation: 0,
                                                    borderSide: BorderSide(
                                                      color: t.tertiary,
                                                      width: 2,
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              ),
                                              if (_model.datePicked2 != null)
                                                Text(
                                                  'تم اختيار ${_fmtChosen(_model.datePicked2)}',
                                                  style: t.labelMedium.copyWith(color: t.primaryText),
                                                )
                                              else if (_showDateErrors)
                                                const Text(
                                                  'يرجى اختيار تاريخ البدء',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Same Day Checkbox
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 10, 0),
                                                child: Text(
                                                  'انتهى العمل الإعلاني في نفس اليوم',
                                                  style: t.bodyMedium.copyWith(color: t.primaryText),
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ),
                                            Checkbox(
                                              value: _sameDayCompletion,
                                              onChanged: (val) {
                                                setState(() {
                                                  _sameDayCompletion = val ?? true;
                                                  if (_sameDayCompletion) {
                                                    _syncEndDateWithStartDate();
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_showErrors &&
                                          _model.datePicked1 != null &&
                                          _model.datePicked2 != null &&
                                          !_datesValid)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            'ادخل تواريخ صحيحة',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // تفاصيل العمل الإعلاني
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                  child: FeqLabeled('تفاصيل العمل الإعلاني'),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                  child: TextFormField(
                                    controller: _model.detailsTextController,
                                    focusNode: _model.detailsFocusNode,
                                    maxLines: 3,
                                    style: t.bodyMedium.copyWith(color: t.primaryText),
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: t.primaryBackground, width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: t.primary, width: 2),
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
                                        (v == null || v.trim().isEmpty) ? 'يرجى إدخال تفاصيل العمل الإعلاني' : null,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                  child: FeqLabeled('المنصة التي نشر فيها العمل الإعلاني'),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                  child: FeqSearchableDropdown<FeqDropDownList>(
                                    items: _socialPlatformsSelected,
                                    value: _selectedPlatform,
                                    onChanged: (v) {
                                      setState(() => _selectedPlatform = v);
                                    },
                                    hint: 'اختر المنصة',
                                    isError: false,
                                  ),
                                ),

                                // الأزرار السفلية
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
                                      child: FFButtonWidget(
                                        onPressed: () => Navigator.of(context).pop(),
                                        text: 'إلغاء',
                                        options: FFButtonOptions(
                                          width: 90,
                                          height: 40,
                                          color: t.secondary,
                                          textStyle: GoogleFonts.interTight(
                                            textStyle: t.titleMedium.copyWith(
                                              color: t.secondaryBackground,
                                              fontSize: 20,
                                            ),
                                          ),
                                          elevation: 2,
                                          borderSide: const BorderSide(color: Colors.transparent, width: 1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    // زر الإضافة — مفعّل دائمًا + يهتز عند الفشل
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
                                      child: AnimatedBuilder(
                                        animation: _shakeCtrl,
                                        builder: (context, child) =>
                                            Transform.translate(offset: Offset(shakeOffset(), 0), child: child),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            setState(() {
                                              _showErrors = true;
                                              _showDateErrors = true;
                                            });

                                            // أولاً: لو في حقول ناقصة -> اهتز + فعّل الأخطاء
                                            if (!_fieldsFilled) {
                                              _formKey.currentState!.validate();
                                              _shakeCtrl.forward(from: 0);
                                              return;
                                            }

                                            // ثانياً: حقول كاملة لكن التواريخ غير منطقية -> دايلوق
                                            if (!_datesValid) {
                                              await showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('تصحيح التواريخ'),
                                                  content: const Text('تاريخ الانتهاء يجب ألا يكون قبل تاريخ البدء.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(ctx).pop(),
                                                      child: const Text('حسنًا'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }

                                            // كل شيء سليم -> احفظ
                                            await _saveExperience();
                                          },
                                          text: 'إضافة',
                                          options: FFButtonOptions(
                                            width: 200,
                                            height: 40,
                                            color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                            textStyle: GoogleFonts.interTight(
                                              textStyle: t.titleMedium.copyWith(color: t.containers, fontSize: 20),
                                            ),
                                            elevation: 2,
                                            borderSide: const BorderSide(color: Colors.transparent, width: 1),
                                            borderRadius: BorderRadius.circular(12),
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
