import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firebase_service_utils.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Send Offer Page (Business fills this after accepting an application)
// ─────────────────────────────────────────────────────────────────────────────

class SendOfferPage extends StatefulWidget {
  final String? applicationId; // null when business initiates directly (no prior application)
  final String campaignId;
  final String campaignTitle;
  final String influencerId;
  final String influencerName;
  final String influencerImageUrl;

  const SendOfferPage({
    super.key,
    this.applicationId, // nullable — business can initiate without an application
    required this.campaignId,
    required this.campaignTitle,
    required this.influencerId,
    required this.influencerName,
    required this.influencerImageUrl,
  });

  @override
  State<SendOfferPage> createState() => _SendOfferPageState();
}

class _SendOfferPageState extends State<SendOfferPage> {
  final _firebaseService = FeqFirebaseServiceUtils();
  bool _isSubmitting = false;

  // ── Campaign info (auto-loaded) ─────────────────────────────────────────────
  Map<String, dynamic>? _campaignData;
  bool _loadingCampaign = true;
  String _businessName = '';
  String _businessImageUrl = '';
  String _influencerContentType = '';

  // ── Platforms: dynamic from campaign ───────────────────────────────────────
  // Map<platformKey, isSelected>
  Map<String, bool> _dynamicPlatforms = {};

  static const Map<String, String> _allPlatformLabels = {
    'instagram': 'Instagram',
    'tiktok': 'TikTok',
    'snapchat': 'Snapchat',
    'x': 'X (Twitter)',
    'twitter': 'X (Twitter)',
    'youtube': 'YouTube',
    'facebook': 'Facebook',
    'linkedin': 'LinkedIn',
  };

  // ── Content types (required, multi-select) ──────────────────────────────────
  final Map<String, bool> _contentTypes = {
    'image_post': false,
    'video_post': false,
    'story': false,
    'reels': false,
    'live': false,
  };
  final Map<String, String> _contentTypeLabels = {
    'image_post': 'منشور صورة',
    'video_post': 'منشور فيديو',
    'story': 'قصة',
    'reels': 'ريلز / فيديو قصير',
    'live': 'بث مباشر',
  };

  // ── Content details (number fields per selected type) ───────────────────────
  final Map<String, TextEditingController> _contentCountControllers = {
    'image_post': TextEditingController(),
    'video_post': TextEditingController(),
    'story': TextEditingController(),
    'reels': TextEditingController(),
    'live': TextEditingController(),
  };
  final Map<String, String> _contentCountLabels = {
    'image_post': 'عدد منشورات الصور',
    'video_post': 'عدد منشورات الفيديو',
    'story': 'عدد القصص',
    'reels': 'عدد الريلز / الفيديوهات القصيرة',
    'live': 'مدة البث المباشر (بالدقائق)',
  };

  // ── Content style (optional, multi-select) ──────────────────────────────────
  final Map<String, bool> _contentStyles = {
    'personal_review': false,
    'usage_experience': false,
    'product_explanation': false,
    'direct_ad': false,
    'awareness': false,
  };
  final Map<String, String> _contentStyleLabels = {
    'personal_review': 'مراجعة شخصية',
    'usage_experience': 'تجربة استخدام',
    'product_explanation': 'شرح منتج',
    'direct_ad': 'إعلان مباشر',
    'awareness': 'محتوى توعوي',
  };

  // ── Text fields ──────────────────────────────────────────────────────────────
  final _additionalRequirementsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _additionalNotesCtrl = TextEditingController();

  // ── Dates ────────────────────────────────────────────────────────────────────
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Acknowledgments ──────────────────────────────────────────────────────────
  final Map<String, bool> _acknowledgments = {
    'not_intermediary': false,
    'data_accuracy': false,
    'payment_commitment': false,
    'preliminary_agreement': false,
  };
  final Map<String, String> _acknowledgmentLabels = {
    'not_intermediary':
    'أقر بأن منصة إعلان منصة تقنية فقط، ولا تعمل كوسيط مالي أو تجاري، ولا تشارك في التفاوض أو التنفيذ أو الدفع بين الأطراف.',
    'data_accuracy':
    'أقر بصحة ودقة واكتمال جميع البيانات المدخلة في هذا العرض، وأتحمل كامل المسؤولية النظامية عنها.',
    'payment_commitment':
    'أقر بالتزامي بدفع المقابل المالي المتفق عليه للمؤثر وفق تفاصيل عرض التعاون المعتمد.',
    'preliminary_agreement':
    'أوافق على أن هذا العرض يُعد اتفاقاً أولياً، ويصبح ملزماً بيني وبين المؤثر فقط عند قبوله، وأي تعديل يتم مباشرةً بين الطرفين وخارج منصة إعلان.',
  };

  @override
  void initState() {
    super.initState();
    _loadCampaignData();
  }

  @override
  void dispose() {
    for (final c in _contentCountControllers.values) {
      c.dispose();
    }
    _additionalRequirementsCtrl.dispose();
    _amountCtrl.dispose();
    _additionalNotesCtrl.dispose();
    super.dispose();
  }

  String _normalizePlatformKey(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('instagram')) return 'instagram';
    if (n.contains('tiktok')) return 'tiktok';
    if (n.contains('snapchat')) return 'snapchat';
    if (n.contains('twitter') || n == 'x') return 'x';
    if (n.contains('youtube')) return 'youtube';
    if (n.contains('facebook')) return 'facebook';
    if (n.contains('linkedin')) return 'linkedin';
    return n.replaceAll(' ', '_');
  }

  Future<void> _loadCampaignData() async {
    try {
      // Load campaign
      final snap = await firebaseFirestore
          .collection('campaigns')
          .where('campaign_id', isEqualTo: widget.campaignId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() => _campaignData = data);

        // Build dynamic platforms from campaign only
        final platformNames = (data['platform_names'] as List?) ?? [];
        final Map<String, bool> newPlatforms = {};
        for (final p in platformNames) {
          final key = _normalizePlatformKey(p.toString());
          if (key.isNotEmpty && !newPlatforms.containsKey(key)) {
            newPlatforms[key] = false;
          }
        }
        // Auto-select if only one platform
        if (newPlatforms.length == 1) {
          final onlyKey = newPlatforms.keys.first;
          newPlatforms[onlyKey] = true;
        }
        setState(() => _dynamicPlatforms = newPlatforms);
      }

      // Load business info
      final businessId = UserSession.getCurrentUserId();
      if (businessId != null) {
        final bData = await _firebaseService.fetchBusinessProfileData(businessId);
        if (bData != null) {
          setState(() {
            _businessName = bData.name;
            final raw = bData.profileImageUrl ?? '';
            _businessImageUrl = raw.isNotEmpty
                ? (raw.contains('?')
                ? '${raw.split('?').first}?alt=media'
                : '$raw?alt=media')
                : '';
          });
        }
      }

      // Load influencer's content type
      try {
        final profileSnap = await firebaseFirestore
            .collection('profiles')
            .where('profile_id', isEqualTo: widget.influencerId)
            .limit(1)
            .get();
        if (profileSnap.docs.isNotEmpty) {
          final inflSnap = await profileSnap.docs.first.reference
              .collection('influencer_profile')
              .limit(1)
              .get();
          if (inflSnap.docs.isNotEmpty) {
            setState(() {
              _influencerContentType =
                  (inflSnap.docs.first.data()['content_type'] ?? '').toString();
            });
          }
        }
      } catch (_) {}
    } catch (_) {}

    if (mounted) setState(() => _loadingCampaign = false);
  }

  bool get _allAcknowledged => _acknowledgments.values.every((v) => v);
  bool get _hasContentType => _contentTypes.values.any((v) => v);
  bool get _hasPlatform => _dynamicPlatforms.values.any((v) => v);

  Future<void> _submit() async {
    if (!_hasContentType) {
      _snack('يرجى اختيار نوع المحتوى المطلوب');
      return;
    }
    // Validate that each selected content type has a count >= 1
    for (final key in _contentTypes.keys) {
      if (_contentTypes[key] == true) {
        final raw = _contentCountControllers[key]!.text.trim();
        final count = int.tryParse(raw);
        if (count == null || count < 1) {
          _snack('يرجى إدخال عدد صحيح (١ أو أكثر) لـ ${_contentTypeLabels[key]}');
          return;
        }
      }
    }
    if (!_hasPlatform) {
      _snack('يرجى اختيار منصة واحدة على الأقل');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _snack('يرجى تحديد مدة التعاون');
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      _snack('يرجى إدخال المبلغ المتفق عليه');
      return;
    }
    if (!_allAcknowledged) {
      _snack('يجب الموافقة على جميع الإقرارات قبل الإرسال');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final businessId = UserSession.getCurrentUserId()!;
      final offerId = firebaseFirestore.collection('offers').doc().id;

      final Map<String, dynamic> contentDetails = {};
      for (final key in _contentTypes.keys) {
        if (_contentTypes[key] == true) {
          final val =
              int.tryParse(_contentCountControllers[key]!.text.trim()) ?? 0;
          contentDetails['${key}_count'] = val;
        }
      }

      final offerData = {
        'offer_id': offerId,
        'application_id': widget.applicationId,
        'business_id': businessId,
        'business_name': _businessName,
        'business_image_url': _businessImageUrl,
        'influencer_id': widget.influencerId,
        'influencer_name': widget.influencerName,
        'influencer_image_url': widget.influencerImageUrl,
        'campaign_id': widget.campaignId,
        'campaign_title': widget.campaignTitle,
        'influencer_content_type_id': _campaignData?['influencer_content_type_id'] ?? 0,
        'influencer_content_type_name': _campaignData?['influencer_content_type_name'] ?? '',
        'status': 'pending',
        'content_types': _contentTypes.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        'content_details': contentDetails,
        'platforms': _dynamicPlatforms.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        'content_styles': _contentStyles.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        'additional_requirements': _additionalRequirementsCtrl.text.trim(),
        'collaboration_start': Timestamp.fromDate(_startDate!),
        'collaboration_end': Timestamp.fromDate(_endDate!),
        'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'additional_notes': _additionalNotesCtrl.text.trim(),
        'business_acknowledged': true,
        'influencer_acknowledged': false,
        'is_read_by_influencer': false,
        'created_at': FieldValue.serverTimestamp(),
      };

      await firebaseFirestore.collection('offers').doc(offerId).set(offerData);

      // Only update the application if this offer came from one
      if (widget.applicationId != null && widget.applicationId!.isNotEmpty) {
        await firebaseFirestore
            .collection('applications')
            .doc(widget.applicationId)
            .update({'status': 'offer_sent', 'offer_id': offerId});
      }

      await firebaseFirestore.collection('notifications').add({
        'to_user_id': widget.influencerId,
        'type': 'offer_received',
        'offer_id': offerId,
        'campaign_title': widget.campaignTitle,
        'business_name': _businessName,
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('تم إرسال العرض بنجاح', textDirection: TextDirection.rtl),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _snack('حدث خطأ أثناء الإرسال: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
      isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now)),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'اختياري';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _getPlatformLabel(String key) {
    return _allPlatformLabels[key] ?? key;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: t.backgroundElan,
      appBar: AppBar(
        backgroundColor: t.secondaryBackground,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'إرسال عرض تعاون',
          style: t.headlineSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loadingCampaign
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionInfluencerInfo(t),
              const SizedBox(height: 16),
              _sectionCampaignInfo(t),
              const SizedBox(height: 20),
              _sectionContentTypes(t),
              const SizedBox(height: 20),
              _sectionPlatforms(t),
              const SizedBox(height: 20),
              _sectionContentStyles(t),
              const SizedBox(height: 20),
              _sectionAdditionalRequirements(t),
              const SizedBox(height: 20),
              _sectionDuration(t),
              const SizedBox(height: 20),
              _sectionAmount(t),
              const SizedBox(height: 20),
              _sectionAdditionalNotes(t),
              const SizedBox(height: 24),
              _sectionAcknowledgments(t),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: t.alternate,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('إرسال العرض',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء',
                    style:
                    TextStyle(color: t.secondaryText, fontSize: 15)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section 1: Influencer info ─────────────────────────────────────────────

  Widget _sectionInfluencerInfo(FlutterFlowTheme t) {
    return _card(
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('معلومات المؤثر', t, icon: Icons.person),
                const SizedBox(height: 12),
                _readOnlyRow('الاسم', widget.influencerName, t),
                if (_influencerContentType.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _readOnlyRow('نوع المحتوى', _influencerContentType, t),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: FeqImagePickerWidget(
              initialImageUrl: widget.influencerImageUrl,
              isUploading: false,
              size: 100,
              onImagePicked: (url, file, bytes) {},
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Campaign info ───────────────────────────────────────────────

  Widget _sectionCampaignInfo(FlutterFlowTheme t) {
    final campaignContentType =
    (_campaignData?['influencer_content_type_name'] ?? '')
        .toString();
    final campaignDescription =
    (_campaignData?['description'] ?? '').toString();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('معلومات الحملة', t, icon: Icons.campaign),
          const SizedBox(height: 12),
          _readOnlyRow('عنوان الحملة', widget.campaignTitle, t),
          if (campaignDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            _readOnlyRow('تفاصيل الحملة', campaignDescription, t),
          ],
          if (campaignContentType.isNotEmpty) ...[
            const SizedBox(height: 8),
            _readOnlyRow('نوع محتوى الحملة', campaignContentType, t),
          ],
        ],
      ),
    );
  }

  // ── Content types ──────────────────────────────────────────────────────────

  Widget _sectionContentTypes(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRequired('نوع المحتوى المطلوب', t, icon: Icons.photo_library),
          const SizedBox(height: 4),
          Text('يمكن اختيار أكثر من نوع',
              style: t.bodySmall.copyWith(color: t.secondaryText)),
          const SizedBox(height: 12),
          ..._contentTypes.keys.map((key) {
            final isSelected = _contentTypes[key]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => setState(() => _contentTypes[key] = v!),
                  title: Text(_contentTypeLabels[key]!, textAlign: TextAlign.start),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 16, end: 16, bottom: 8),
                    child: TextFormField(
                      controller: _contentCountControllers[key],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.start,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: _contentCountLabels[key],
                        hintText: '١',
                        filled: true,
                        fillColor: t.containers,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        errorText: (() {
                          final raw = _contentCountControllers[key]!.text.trim();
                          if (raw.isEmpty) return null; // shown only after typing
                          final v = int.tryParse(raw);
                          if (v == null || v < 1) return 'أدخل رقماً من ١ فأكثر';
                          return null;
                        })(),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Platforms (dynamic from campaign) ─────────────────────────────────────

  Widget _sectionPlatforms(FlutterFlowTheme t) {
    if (_dynamicPlatforms.isEmpty) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitleRequired('المنصات', t, icon: Icons.share),
            const SizedBox(height: 8),
            Text('لا توجد منصات محددة في الحملة',
                style: t.bodySmall.copyWith(color: t.secondaryText),
                textAlign: TextAlign.start),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRequired('المنصات', t, icon: Icons.share),
          const SizedBox(height: 4),
          Text('اختر من المنصات المدرجة للحملة',
              style: t.bodySmall.copyWith(color: t.secondaryText)),
          const SizedBox(height: 12),
          ..._dynamicPlatforms.keys.map((key) => CheckboxListTile(
            value: _dynamicPlatforms[key]!,
            onChanged: (v) =>
                setState(() => _dynamicPlatforms[key] = v!),
            title: Text(_getPlatformLabel(key), textAlign: TextAlign.start),
            controlAffinity: ListTileControlAffinity.leading,
          )),
        ],
      ),
    );
  }

  // ── Content style ─────────────────────────────────────────────────────────

  Widget _sectionContentStyles(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('أسلوب المحتوى (اختياري)', t, icon: Icons.style),
          const SizedBox(height: 12),
          ..._contentStyles.keys.map((key) => CheckboxListTile(
            value: _contentStyles[key]!,
            onChanged: (v) => setState(() => _contentStyles[key] = v!),
            title:
            Text(_contentStyleLabels[key]!, textAlign: TextAlign.start),
            controlAffinity: ListTileControlAffinity.leading,
          )),
        ],
      ),
    );
  }

  // ── Additional requirements ────────────────────────────────────────────────

  Widget _sectionAdditionalRequirements(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('متطلبات إضافية (اختياري)', t, icon: Icons.list_alt),
          const SizedBox(height: 12),
          TextFormField(
            controller: _additionalRequirementsCtrl,
            maxLines: 3,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              hintText: 'أي متطلبات إضافية...',
              filled: true,
              fillColor: t.containers,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  // ── Duration ──────────────────────────────────────────────────────────────

  Widget _sectionDuration(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRequired('مدة التعاون', t, icon: Icons.calendar_month),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _datePicker(
                  label: 'تاريخ البدء',
                  value: _startDate,
                  onTap: () => _pickDate(isStart: true),
                  t: t,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _datePicker(
                  label: 'تاريخ الانتهاء',
                  value: _endDate,
                  onTap: () => _pickDate(isStart: false),
                  t: t,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required FlutterFlowTheme t,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: t.containers,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.bodySmall.copyWith(color: t.secondaryText)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  value != null ? _fmtDate(value) : 'اختر تاريخ',
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value != null ? t.primaryText : t.secondaryText,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.calendar_today, size: 16, color: t.secondaryText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Amount ────────────────────────────────────────────────────────────────

  Widget _sectionAmount(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRequired('المقابل المالي', t, icon: Icons.payments),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'ريال سعودي',
              filled: true,
              fillColor: t.containers,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Text(
              'ملاحظة: يتم تنفيذ جميع المدفوعات خارج منصة إعلان',
              textAlign: TextAlign.start,
              style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Additional notes ──────────────────────────────────────────────────────

  Widget _sectionAdditionalNotes(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ملاحظات إضافية (اختياري)', t, icon: Icons.note),
          const SizedBox(height: 12),
          TextFormField(
            controller: _additionalNotesCtrl,
            maxLines: 3,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              hintText: 'أي ملاحظات إضافية...',
              filled: true,
              fillColor: t.containers,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  // ── Acknowledgments ───────────────────────────────────────────────────────

  Widget _sectionAcknowledgments(FlutterFlowTheme t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('إقرارات صاحب الشركة (إلزامية)', t,
              icon: Icons.verified_user, color: const Color(0xFFDC2626)),
          const SizedBox(height: 4),
          Text('لا يمكن الإرسال بدون الموافقة على جميع ما سبق ❌',
              style: t.bodySmall.copyWith(color: const Color(0xFFDC2626))),
          const SizedBox(height: 12),
          ..._acknowledgments.keys.map((key) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: CheckboxListTile(
              value: _acknowledgments[key]!,
              onChanged: (v) =>
                  setState(() => _acknowledgments[key] = v!),
              title: Text(_acknowledgmentLabels[key]!,
                  textAlign: TextAlign.start,
                  style: t.bodySmall.copyWith(height: 1.5)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: t.primary,
            ),
          )),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x15000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  /// Normal title (optional fields)
  Widget _sectionTitle(String title, FlutterFlowTheme t,
      {required IconData icon, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(title,
            style: t.titleSmall.copyWith(
                fontWeight: FontWeight.w700, color: color ?? t.primaryText)),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: color ?? t.primary),
      ],
    );
  }

  /// Title for required fields — red asterisk
  Widget _sectionTitleRequired(String title, FlutterFlowTheme t,
      {required IconData icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(' *',
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16)),
        Text(title,
            style: t.titleSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: t.primary),
      ],
    );
  }

  Widget _readOnlyRow(String label, String value, FlutterFlowTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.bodySmall.copyWith(color: t.secondaryText)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '—' : value,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.start),
      ],
    );
  }
}