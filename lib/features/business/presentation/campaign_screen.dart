import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elan_flutterproject/features/business/presentation/subscription_info_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../../../core/services/subscription_service.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../models/campaign_model.dart';

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

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key, this.campaignId, this.isClone = false});

  static const String routeName = 'business-campaign';
  static const String routePath = '/$routeName';

  final String? campaignId;
  final bool isClone;

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> with SingleTickerProviderStateMixin {
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

  List<_PlatformRow> _platformRows = [_PlatformRow()];

  bool get _isEdit => widget.campaignId != null && !widget.isClone;

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
    _influencerContentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    // Add listeners to trigger validation on text changes
    _model.campaignTitleTextController?.addListener(() {
      setState(() {}); // Rebuild to re-evaluate _checkFormValid()
    });

    _model.detailsTextController?.addListener(() {
      setState(() {}); // Rebuild to re-evaluate _checkFormValid()
    });
    if (_isEdit) {
      _loadCampaign();
      _checkSubscriptionForExpiredEdit();
    } else if (widget.isClone && widget.campaignId != null) {
      _loadCampaignForClone();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على جلسة مستخدم.')));
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
        final platformNamesList = _platformRows
            .where((r) => r.platform != null)
            .map((r) => r.platform!.nameAr)
            .toList();

        await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).update({
          'title': _model.campaignTitleTextController!.text.trim(),
          'description': _model.detailsTextController!.text.trim(),
          'platform_names': platformNamesList,
          'influencer_content_type_id': _selectedInfluencerContentType!.id,
          'influencer_content_type_name': _selectedInfluencerContentType!.nameAr,
          'start_date': Timestamp.fromDate(_model.datePicked2!),
          'end_date': Timestamp.fromDate(_model.datePicked1!),
          // 'active': _model.isActive,
          'visible': _model.isVisible,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الحملة بنجاح')));
      } else {
        final platformNamesList = _platformRows
            .where((r) => r.platform != null)
            .map((r) => r.platform!.nameAr)
            .toList();

        final ref = await FirebaseFirestore.instance.collection('campaigns').add({
          'business_id': uid,
          'title': _model.campaignTitleTextController!.text.trim(),
          'description': _model.detailsTextController!.text.trim(),
          'platform_names': platformNamesList,
          'influencer_content_type_id': _selectedInfluencerContentType!.id,
          'influencer_content_type_name': _selectedInfluencerContentType!.nameAr,
          'start_date': Timestamp.fromDate(_model.datePicked2!),
          'end_date': Timestamp.fromDate(_model.datePicked1!),
          'date_added': Timestamp.fromDate(DateTime.now()),
          //'active': _model.isActive,
          'visible': _model.isVisible,
        });

        await ref.update({'campaign_id': ref.id});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الحملة بنجاح')));
      }

      Navigator.of(context).pop(true); // Return true for successful creation/update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
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
      final doc = await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).get();

      if (!doc.exists) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على هذه الحملة')));
        }
        return;
      }

      final m = doc.data()!;
      final influencerContentTypeIdRaw = m['influencer_content_type_id'];
      int influencerContentTypeId = 0;
      if (influencerContentTypeIdRaw is int) {
        influencerContentTypeId = influencerContentTypeIdRaw;
      } else if (influencerContentTypeIdRaw is String && influencerContentTypeIdRaw.isNotEmpty) {
        influencerContentTypeId = int.tryParse(influencerContentTypeIdRaw) ?? 0;
      }
      _selectedInfluencerContentType = _influencerContentTypes.firstWhere(
            (c) => c.id == influencerContentTypeId,
        orElse: () => _influencerContentTypes.first,
      );
      _model.campaignTitleTextController!.text = (m['title'] ?? '').toString();
      _model.detailsTextController!.text = (m['description'] ?? '').toString();

      //_model.isActive = m['active'] ?? true;
      _model.isVisible = m['visible'] ?? true;

      final s = m['start_date'];
      final e = m['end_date'];
      if (s is Timestamp) _model.datePicked2 = s.toDate();
      if (e is Timestamp) _model.datePicked1 = e.toDate();

      // Load platform names
      final platformNames = (m['platform_names'] as List?) ?? [];
      final rows = platformNames.map<_PlatformRow>((platformNameStr) {
        final plat = _socialPlatforms.firstWhere(
              (p) => p.nameAr == platformNameStr.toString(),
          orElse: () => _socialPlatforms.first,
        );
        return _PlatformRow(platform: plat);
      }).toList();

      if (rows.isNotEmpty) {
        _platformRows = rows;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل جلب البيانات: $e')));
      }
    }
  }

  Future<void> _loadCampaignForClone() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).get();

      if (!doc.exists) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على هذه الحملة')));
        }
        return;
      }

      final m = doc.data()!;

      // Clone all fields except: start_date, end_date
      _model.campaignTitleTextController!.text = (m['title'] ?? '').toString();
      _model.detailsTextController!.text = (m['description'] ?? '').toString();

      _model.isVisible = m['visible'] ?? true;

      // Clone content type
      final influencerContentTypeIdRaw = m['influencer_content_type_id'];
      int influencerContentTypeId = 0;
      if (influencerContentTypeIdRaw is int) {
        influencerContentTypeId = influencerContentTypeIdRaw;
      } else if (influencerContentTypeIdRaw is String && influencerContentTypeIdRaw.isNotEmpty) {
        influencerContentTypeId = int.tryParse(influencerContentTypeIdRaw) ?? 0;
      }
      if (influencerContentTypeId > 0) {
        _selectedInfluencerContentType = _influencerContentTypes.firstWhere(
              (c) => c.id == influencerContentTypeId,
          orElse: () => _influencerContentTypes.first,
        );
      }

      // Load platform names
      final platformNames = (m['platform_names'] as List?) ?? [];
      final rows = platformNames.map<_PlatformRow>((platformNameStr) {
        final plat = _socialPlatforms.firstWhere(
              (p) => p.nameAr == platformNameStr.toString(),
          orElse: () => _socialPlatforms.first,
        );
        return _PlatformRow(platform: plat);
      }).toList();

      if (rows.isNotEmpty) {
        _platformRows = rows;
      }

      // Do NOT clone: start_date, end_date
      // Leave them empty for user to fill

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل جلب البيانات: $e')));
      }
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _model.dispose();
    super.dispose();
  }

  bool _checkFormValid() {
    return (_model.campaignTitleTextController?.text.trim() ?? '').isNotEmpty &&
        (_model.detailsTextController?.text.trim() ?? '').isNotEmpty &&
        _platformRows.isNotEmpty &&
        _selectedInfluencerContentType != null &&
        _datesValid;
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
          style: GoogleFonts.interTight(textStyle: t.headlineSmall.copyWith(color: t.primaryText)),
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
                    color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
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
                  ? Color(0xFFFEE2E2) // Light red if campaign expired
                  : t.backgroundElan) // Normal background if not expired
                  : t.backgroundElan,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _showErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SubscriptionInfoWidget(isEditMode: _isEdit, currentCampaignExpiryDate: _model.datePicked1),

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
                                // ... rest of your existing form fields ...
                              ],
                            ),
                          ),
                        ),
                      ),
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
                                // TITLE FIELD - Show disabled if expired campaign and can't edit OR if clone mode
                                if ((_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) || widget.isClone) ...[
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
                                      enabled: !(_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) && !widget.isClone,
                                      textCapitalization: TextCapitalization.words,
                                      style: t.bodyMedium.copyWith(color: t.primaryText),
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: t.primaryBackground, width: 2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 2),
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
                                ],

                                // DETAILS FIELD - Same disabled logic
                                if ((_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) || widget.isClone) ...[
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
                                      enabled: !(_isEdit && _isCampaignExpired() && !_canEditExpiredCampaign) && !widget.isClone,
                                      maxLines: 3,
                                      style: t.bodyMedium.copyWith(color: t.primaryText),
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: t.primaryBackground, width: 2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 2),
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
                                      (v == null || v.trim().isEmpty) ? 'يرجى إدخال تفاصيل الحملة' : null,
                                    ),
                                  ),
                                ],

                                // CONTENT TYPE - Locked for edit and clone modes
                                if (_isEdit || widget.isClone) ...[
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5),
                                    child: FeqLabeled('نوع المحتوى'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Color(0xFFE5E7EB), width: 2),
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
                                          const SizedBox(width: 8),
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
                                      itemLabel: (item) => item.nameAr,
                                    ),
                                  ),
                                ],

                                // PLATFORMS SECTION
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
                                              if (!widget.isClone)
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
                                                        _platformRows.add(_PlatformRow());
                                                      });
                                                    },
                                                  ),
                                                )
                                              else
                                                const SizedBox(width: 50),
                                              Align(
                                                alignment: const AlignmentDirectional(1, -1),
                                                child: Padding(
                                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 20, 0),
                                                  child: Text(
                                                    'المنصات',
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
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                          child: Column(
                                            children: List.generate(_platformRows.length, (i) {
                                              final row = _platformRows[i];
                                              return Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 8),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (!widget.isClone)
                                                      Align(
                                                        alignment: const AlignmentDirectional(1, 0),
                                                        child: Padding(
                                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                                          child: FlutterFlowIconButton(
                                                            borderRadius: 8,
                                                            buttonSize: 50,
                                                            icon: Icon(
                                                              Icons.delete_outline,
                                                              color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                                              size: 20,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                _platformRows.removeAt(i);
                                                                if (_platformRows.isEmpty) {
                                                                  _platformRows.add(_PlatformRow());
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      const SizedBox(width: 50),
                                                    Expanded(
                                                      child: Padding(
                                                        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 20, 0),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            if (widget.isClone)
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                decoration: BoxDecoration(
                                                                  color: Color(0xFFF3F4F6),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: Color(0xFFE5E7EB), width: 2),
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                  children: [
                                                                    Text(
                                                                      row.platform?.nameAr ?? 'غير محدد',
                                                                      style: t.bodyMedium.copyWith(
                                                                        color: Color(0xFF9CA3AF),
                                                                        fontStyle: FontStyle.italic,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    Icon(Icons.lock, color: Color(0xFF9CA3AF), size: 18),
                                                                  ],
                                                                ),
                                                              )
                                                            else
                                                              FeqSearchableDropdown<FeqDropDownList>(
                                                                items: _socialPlatforms,
                                                                value: row.platform,
                                                                onChanged: (v) {
                                                                  setState(() => row.platform = v);
                                                                },
                                                                hint: 'اختر المنصة',
                                                                isError: false,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

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
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 8),
                                                child: FFButtonWidget(
                                                  onPressed: _model.datePicked2 == null ? null : () async {
                                                    final picked = await showDatePicker(
                                                      context: context,
                                                      initialDate: _model.datePicked1 ?? _model.datePicked2!,
                                                      firstDate: _model.datePicked2!,
                                                      lastDate: DateTime(2050),
                                                      builder: (context, child) => wrapInMaterialDatePickerTheme(
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
                                                    color: _model.datePicked2 == null ? Colors.grey : t.tertiary,
                                                    textStyle: GoogleFonts.inter(
                                                      textStyle: t.bodyMedium.copyWith(
                                                        color: _model.datePicked2 == null ? Colors.grey[600] : t.primaryText,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    elevation: 0,
                                                    borderSide: BorderSide(color: _model.datePicked2 == null ? Colors.grey : t.tertiary, width: 2),
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
                                                Text(
                                                  _model.datePicked2 == null ? 'اختر تاريخ البدء أولاً' : 'يرجى اختيار تاريخ الإنتهاء',
                                                  style: TextStyle(color: _model.datePicked2 == null ? Colors.orange : Colors.red),
                                                ),
                                            ],
                                          ),

                                          Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 8),
                                                child: FFButtonWidget(
                                                  onPressed: () async {
                                                    final picked = await showDatePicker(
                                                      context: context,
                                                      initialDate: _model.datePicked2 ?? DateTime.now(),
                                                      firstDate: DateTime(2020),
                                                      lastDate: DateTime(2050),
                                                      builder: (context, child) => wrapInMaterialDatePickerTheme(
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
                                                            () {
                                                          _model.datePicked2 = DateTime(
                                                            picked.year,
                                                            picked.month,
                                                            picked.day,
                                                          );
                                                          // Reset end date if it's before new start date
                                                          if (_model.datePicked1 != null && _model.datePicked1!.isBefore(_model.datePicked2!)) {
                                                            _model.datePicked1 = null;
                                                          }
                                                        },
                                                      );
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
                                                    borderSide: BorderSide(color: t.tertiary, width: 2),
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

                                      if (_showErrors &&
                                          _model.datePicked1 != null &&
                                          _model.datePicked2 != null &&
                                          !_datesValid)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text('ادخل تواريخ صحيحة', style: TextStyle(color: Colors.red)),
                                        ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: _model.isVisible,
                                            onChanged: (val) {
                                              setState(() => _model.isVisible = val);
                                            },
                                            activeThumbColor: t.primary,
                                          ),
                                          Text(
                                            'ظاهر',
                                            style: GoogleFonts.inter(
                                              textStyle: t.bodyMedium.copyWith(
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
                                          /*Switch(
                                                  value: _model.isActive,
                                                  onChanged: (val) {
                                                    setState(() => _model.isActive = val);
                                                  },
                                                  activeThumbColor: t.primary,
                                                ),*/
                                          /*Text(
                                                  'نشط',
                                                  style: GoogleFonts.inter(
                                                    textStyle: t.bodyMedium.copyWith(
                                                      color: t.primaryText,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),*/
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
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 24),
                                      child: AnimatedBuilder(
                                        animation: _shakeCtrl,
                                        builder: (context, child) =>
                                            Transform.translate(offset: Offset(_shakeOffset(), 0), child: child),
                                        child: FFButtonWidget(
                                          onPressed: _checkFormValid()
                                              ? () async {
                                            setState(() {
                                              _showErrors = true;
                                              _showDateErrors = true;
                                            });

                                            if (!_datesValid) {
                                              await showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('تصحيح التواريخ'),
                                                  content: const Text(
                                                    'تاريخ الانتهاء يجب ألا يكون قبل تاريخ البدء.',
                                                  ),
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
                                          text: _isEdit ? 'تحديث' : 'إضافة',
                                          options: FFButtonOptions(
                                            width: 200,
                                            height: 40,
                                            color: t.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                            textStyle: GoogleFonts.interTight(
                                              textStyle: t.titleMedium.copyWith(
                                                color: t.containers,
                                                fontSize: 20,
                                              ),
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
    return _model.datePicked1 != null && _model.datePicked1!.isBefore(DateTime.now());
  }

  // Build a disabled text field widget
  Widget _buildDisabledTextField(String label, String value) {
    final t = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 20, 5), child: FeqLabeled(label)),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: t.bodyMedium.copyWith(color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.lock, color: Color(0xFF9CA3AF), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformRow {
  FeqDropDownList? platform;

  _PlatformRow({this.platform});
}