import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/components/feq_components.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/offer_contract_pdf_service.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../payment/payment_details_page.dart';

enum _OfferDocumentAction {
  print,
  download,
  share,
}

class OfferDetailPage extends StatefulWidget {
  final String offerId;
  final bool isBusinessView;
  final bool actionContractCanDownload;
  final bool actionContractCanPrint;

  const OfferDetailPage({
    super.key,
    required this.offerId,
    required this.isBusinessView,
    required this.actionContractCanDownload,
    required this.actionContractCanPrint
  });

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  Map<String, dynamic>? _offer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isDocumentBusyDownload = false;
  bool _isDocumentBusyPrint = false;

  final TextEditingController _rejectionReasonCtrl = TextEditingController();

  final Map<String, bool> _acks = {
    'full_review': false,
    'platform_not_responsible': false,
    'preliminary_agreement': false,
    'pay_fees': false,
    'execute_campaign': false,
  };

  final Map<String, String> _ackLabels = {
    'full_review':
    'أقر بالاطلاع الكامل على جميع تفاصيل عرض التعاون والشروط والأحكام أعلاه.',
    'platform_not_responsible':
    'أقر بأن منصة إعلان منصة تقنية فقط، وغير مسؤولة عن أي التزامات مالية أو قانونية بيني وبين صاحب الشركة.',
    'preliminary_agreement':
    'أوافق على أن هذا العرض يُعد اتفاقاً أولياً، وأي تعديل عليه يتم خارج منصة إعلان.',
    'pay_fees':
    'أوافق على دفع رسوم منصة إعلان البالغة 99 ريال سعودي مقابل الخدمة التقنية.',
    'execute_campaign':
    'ألتزم بتنفيذ الحملة وفق التفاصيل المتفق عليها والأنظمة المعمول بها في المملكة العربية السعودية.',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _markAsRead();
  }

  @override
  void dispose() {
    _rejectionReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    if (widget.isBusinessView) return;
    try {
      await firebaseFirestore.collection('offers').doc(widget.offerId).update({
        'is_read_by_influencer': true,
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final snap =
      await firebaseFirestore.collection('offers').doc(widget.offerId).get();
      if (snap.exists) {
        final offerData = Map<String, dynamic>.from(snap.data()!);
        final campaignId = offerData['campaign_id'] as String? ?? '';

        if (campaignId.isNotEmpty) {
          try {
            final campaignSnap = await firebaseFirestore
                .collection('campaigns')
                .where('campaign_id', isEqualTo: campaignId)
                .limit(1)
                .get();

            if (campaignSnap.docs.isNotEmpty) {
              final cData = campaignSnap.docs.first.data();

              if ((offerData['campaign_description'] as String? ?? '').isEmpty) {
                offerData['campaign_description'] =
                    cData['description'] as String? ?? '';
              }

              if ((offerData['influencer_content_type_name'] as String? ?? '')
                  .isEmpty) {
                offerData['influencer_content_type_name'] =
                    cData['influencer_content_type_name'] as String? ?? '';
              }
            }
          } catch (_) {}
        }

        setState(() {
          _offer = offerData;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  bool get _allAcked => _acks.values.every((v) => v);

  // bool get _canShowDocumentActions => (_offer?['status'] as String? ?? 'pending') == 'accepted';

  String _fmtTs(dynamic v) {
    if (v == null) return '—';
    DateTime dt;
    if (v is Timestamp) {
      dt = v.toDate();
    } else if (v is DateTime) {
      dt = v;
    } else {
      return v.toString();
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _contentSummary() {
    if (_offer == null) return '';
    final details = _offer!['content_details'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];

    final imageCount = details['image_post_count'];
    final videoCount = details['video_post_count'];
    final storyCount = details['story_count'];
    final reelsCount = details['reels_count'];
    final liveMin = details['live_count'];

    if (imageCount != null && imageCount != 0) parts.add('$imageCount صور');
    if (videoCount != null && videoCount != 0) parts.add('$videoCount فيديو');
    if (storyCount != null && storyCount != 0) parts.add('$storyCount قصص');
    if (reelsCount != null && reelsCount != 0) parts.add('$reelsCount ريلز');
    if (liveMin != null && liveMin != 0) {
      parts.add('بث مباشر $liveMin دقيقة');
    }

    return parts.join(' – ');
  }

  String _platformsStr() {
    if (_offer == null) return '';
    final platforms = (_offer!['platforms'] as List?) ?? [];
    final socialPlatforms = FeqDropDownListLoader.instance.socialPlatforms;

    return platforms.map((pId) {
      final platformObj = socialPlatforms.firstWhere(
            (p) => p.id == pId,
        orElse: () => const FeqDropDownList(
          id: 0,
          nameEn: '',
          nameAr: '',
          domain: '',
        ),
      );
      return platformObj.nameAr;
    }).where((e) => e.isNotEmpty).join(' / ');
  }

  String _stylesStr() {
    if (_offer == null) return '';
    final styles = (_offer!['content_styles'] as List?) ?? [];
    const labels = {
      'personal_review': 'مراجعة شخصية',
      'usage_experience': 'تجربة استخدام',
      'product_explanation': 'شرح منتج',
      'direct_ad': 'إعلان مباشر',
      'awareness': 'محتوى توعوي',
    };
    return styles.map((s) => labels[s.toString()] ?? s.toString()).join('، ');
  }

  Future<void> _handleDocumentAction(_OfferDocumentAction action) async {
    if (_offer == null || _isDocumentBusyDownload || _isDocumentBusyPrint) return;

    setState(() {
      (action == _OfferDocumentAction.print) ? _isDocumentBusyPrint = true : _isDocumentBusyDownload = true;
    });

    try {
      switch (action) {
        case _OfferDocumentAction.print:
          await OfferContractPdfService.printPdf(
            offer: _offer!,
            contentSummary: _contentSummary(),
            platformsLabel: _platformsStr(),
            stylesLabel: _stylesStr(),
          );
          break;
        case _OfferDocumentAction.download:
          await OfferContractPdfService.downloadPdf(
            offer: _offer!,
            contentSummary: _contentSummary(),
            platformsLabel: _platformsStr(),
            stylesLabel: _stylesStr(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم حفظ الملف بنجاح',
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          }
          break;
        case _OfferDocumentAction.share:
          await OfferContractPdfService.sharePdf(
            offer: _offer!,
            contentSummary: _contentSummary(),
            platformsLabel: _platformsStr(),
            stylesLabel: _stylesStr(),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        _snack('حدث خطأ أثناء إنشاء الملف: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          (action == _OfferDocumentAction.print) ? _isDocumentBusyPrint = false : _isDocumentBusyDownload = false;
        });
      }
    }
  }

  Future<void> _acceptOffer() async {
    if (!_allAcked) {
      _snack('يجب الموافقة على جميع الإقرارات أولاً');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد القبول', textDirection: TextDirection.rtl),
        content: const Text(
          'بالضغط على "موافق"، تؤكد قبول عرض التعاون ودفع رسوم المنصة (99 ريال سعودي).',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('موافقة ومتابعة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    final paymentResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PaymentDetailsPage(
          planId: 'offer_fee',
          returnAfterPayment: true,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (paymentResult != true) return;

    setState(() => _isSubmitting = true);

    try {
      await firebaseFirestore.collection('offers').doc(widget.offerId).update({
        'status': 'accepted',
        'influencer_acknowledged': true,
        'accepted_at': FieldValue.serverTimestamp(),
      });

      final appId = _offer?['application_id'] as String?;
      if (appId != null && appId.isNotEmpty) {
        await firebaseFirestore
            .collection('applications')
            .doc(appId)
            .update({'status': 'accepted'});
      }

      final businessId = _offer?['business_id'] as String? ?? '';
      if (businessId.isNotEmpty) {
        await firebaseFirestore.collection('notifications').add({
          'to_user_id': businessId,
          'type': 'offer_accepted',
          'offer_id': widget.offerId,
          'campaign_title': _offer?['campaign_title'] ?? '',
          'influencer_name': _offer?['influencer_name'] ?? '',
          'created_at': FieldValue.serverTimestamp(),
          'is_read': false,
        });
      }

      setState(() {
        _offer!['status'] = 'accepted';
        _offer!['influencer_acknowledged'] = true;
        _offer!['accepted_at'] = Timestamp.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم قبول العرض بنجاح!',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      _snack('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _rejectOffer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الرفض', textDirection: TextDirection.rtl),
        content: const Text(
          'هل تريد رفض عرض التعاون هذا؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('رفض العرض'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final updateData = <String, dynamic>{
        'status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
      };

      final reason = _rejectionReasonCtrl.text.trim();
      if (reason.isNotEmpty) {
        updateData['rejection_reason'] = reason;
      }

      await firebaseFirestore
          .collection('offers')
          .doc(widget.offerId)
          .update(updateData);

      final appId = _offer?['application_id'] as String?;
      if (appId != null && appId.isNotEmpty) {
        await firebaseFirestore
            .collection('applications')
            .doc(appId)
            .update({'status': 'rejected'});
      }

      final businessId = _offer?['business_id'] as String? ?? '';
      if (businessId.isNotEmpty) {
        await firebaseFirestore.collection('notifications').add({
          'to_user_id': businessId,
          'type': 'offer_rejected',
          'offer_id': widget.offerId,
          'campaign_title': _offer?['campaign_title'] ?? '',
          'influencer_name': _offer?['influencer_name'] ?? '',
          'rejection_reason': reason.isNotEmpty ? reason : null,
          'created_at': FieldValue.serverTimestamp(),
          'is_read': false,
        });
      }

      setState(() => _offer!['status'] = 'rejected');

      if (mounted) {
        final snackMsg = reason.isNotEmpty
            ? 'تم رفض العرض. السبب: $reason'
            : 'تم رفض العرض.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMsg, textDirection: TextDirection.rtl),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _snack('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final status = _offer?['status'] as String? ?? 'pending';

    return Scaffold(
      backgroundColor: t.backgroundElan,
      appBar: FeqAppBar(
        title: 'تفاصيل العرض',
        showBack: true,
        showContractDownload: widget.actionContractCanDownload,
        showContractPrint: widget.actionContractCanPrint,
        isDocumentBusyDownload: _isDocumentBusyDownload,
        isDocumentBusyPrint: _isDocumentBusyPrint,
        onDownload: () => _handleDocumentAction(_OfferDocumentAction.download),
        onPrint: () => _handleDocumentAction(_OfferDocumentAction.print),
        documentActionsOnStart: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offer == null
          ? Center(
        child: Text(
          'لم يتم العثور على العرض',
          style: t.bodyLarge.copyWith(color: t.secondaryText),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status == 'accepted') _acceptedBanner(t),
              if (status == 'rejected') _rejectedStamp(t),
              if (status == 'pending' && !widget.isBusinessView) ...[
                _pendingInfluencerBanner(t),
                const SizedBox(height: 12),
              ],
              _contractDocument(t, status),
              const SizedBox(height: 20),
              _termsSection(t, status),
              if (!widget.isBusinessView && status == 'pending') ...[
                const SizedBox(height: 24),
                _influencerAcknowledgments(t),
                const SizedBox(height: 20),
                _rejectionReasonField(t),
                const SizedBox(height: 20),
                _influencerActionButtons(t),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acceptedBanner(FlutterFlowTheme t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isBusinessView
                  ? 'وافق المؤثر على عرض التعاون وهو ملزم بتنفيذ الحملة وفق التفاصيل المذكورة في العرض.'
                  : 'لقد قبلت هذا العرض بنجاح.',
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedStamp(FlutterFlowTheme t) {
    final rejectionReason = _offer?['rejection_reason'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 36),
          const SizedBox(height: 8),
          const Text(
            'مرفوض',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تم رفض هذا العرض.',
            style: t.bodyMedium.copyWith(color: const Color(0xFFDC2626)),
          ),
          if (rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'سبب الرفض:',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rejectionReason,
                    style: t.bodyMedium.copyWith(color: const Color(0xFF991B1B)),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pendingInfluencerBanner(FlutterFlowTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFB45309), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'لديك عرض تعاون جديد. راجع التفاصيل بعناية قبل القبول أو الرفض.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contractDocument(FlutterFlowTheme t, String status) {
    final businessName = _offer!['business_name'] as String? ?? '';
    final influencerName = _offer!['influencer_name'] as String? ?? '';
    final campaignTitle = _offer!['campaign_title'] as String? ?? '';
    final campaignDescription = _offer!['campaign_description'] as String? ?? '';
    final campaignContentTypeName =
        _offer!['influencer_content_type_name'] as String? ?? '';
    final amount = (_offer!['amount'] as num?)?.toDouble() ?? 0;
    final startDate = _fmtTs(_offer!['collaboration_start']);
    final endDate = _fmtTs(_offer!['collaboration_end']);
    final contractDate =
    _fmtTs(_offer!['accepted_at'] ?? _offer!['created_at'] ?? Timestamp.now());
    final additionalNotes = _offer!['additional_notes'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.alternate),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'عرض تعاون تسويقي',
            style: t.headlineSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            status == 'accepted'
                ? 'العقد النهائي – (بعد القبول)'
                : status == 'rejected'
                ? 'العقد المرسل للمؤثر – (مرفوض)'
                : 'العقد المرسل للمؤثر – (قبل القبول)',
            style: t.bodySmall.copyWith(color: t.secondaryText),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 24),
          Text(
            'تم إرسال هذا العرض من $businessName إلى المؤثر $influencerName للمشاركة في حملة تسويقية بعنوان "$campaignTitle"',
            style: t.bodyMedium.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'تاريخ العقد: $contractDate',
            style: t.bodySmall.copyWith(
              color: t.secondaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 24),
          _sectionHeader('معلومات الحملة', t),
          const SizedBox(height: 12),
          _contractRow('عنوان الحملة', campaignTitle, t),
          if (campaignContentTypeName.isNotEmpty)
            _contractRow('نوع محتوى الحملة', campaignContentTypeName, t),
          if (campaignDescription.isNotEmpty)
            _contractRow('تفاصيل الحملة', campaignDescription, t),
          const Divider(height: 20),
          _sectionHeader('تفاصيل التعاون', t),
          const SizedBox(height: 12),
          _contractRow('المحتوى المطلوب', _contentSummary(), t),
          _contractRow('منصات النشر', _platformsStr(), t),
          if (_stylesStr().isNotEmpty) _contractRow('أسلوب المحتوى', _stylesStr(), t),
          _contractRow('مدة التعاون', 'من $startDate إلى $endDate', t),
          _contractRow('المقابل المالي', '$amount ريال سعودي', t),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'يتم دفعه خارج منصة إعلان وبالاتفاق المباشر بين الطرفين',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (additionalNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _contractRow('ملاحظات إضافية', additionalNotes, t),
          ],
        ],
      ),
    );
  }

  Widget _termsSection(FlutterFlowTheme t, String status) {
    final isAccepted = status == 'accepted';
    final terms = isAccepted && widget.isBusinessView
        ? [
      'يلتزم المؤثر بتنفيذ الحملة وفق التفاصيل المذكورة في عرض التعاون المعتمد.',
      'يلتزم صاحب الشركة بدفع المقابل المالي المتفق عليه للمؤثر وفق التفاصيل المتفق عليها.',
      'منصة إعلان ليست وسيطاً مالياً ولا تتحمل أي مسؤولية قانونية أو مالية.',
      'يُعد المؤثر موافقاً على جميع بنود هذا الاتفاق وملتزماً بتنفيذه.',
      'في حال الإخلال بالشروط، يتم حل النزاع مباشرة بين طرفي الاتفاق.',
    ]
        : [
      'يتم تنفيذ جميع المدفوعات المالية الخاصة بهذا التعاون خارج منصة إعلان.',
      'يقتصر دور منصة إعلان على توفير منصة تقنية لعرض فرص التعاون، ولا تشارك في التفاوض أو التنفيذ أو الدفع.',
      'يتحمل كل من صاحب الشركة والمؤثر المسؤولية الكاملة عن تنفيذ هذا التعاون.',
      'يلتزم المؤثر بدفع رسوم خدمة تقنية ثابتة لمنصة إعلان قدرها 99 ريال سعودي عند قبول العرض.',
      'يلتزم المؤثر بتنفيذ المحتوى وفق الأنظمة واللوائح المعمول بها في المملكة العربية السعودية.',
      'يُعد هذا العرض اتفاقاً أولياً، وأي تعديل يتم مباشرةً بين الطرفين وخارج منصة إعلان.',
      'في حال نشوء أي نزاع، يتم حله مباشرةً بين الطرفين دون أي تدخل أو مسؤولية على منصة إعلان.',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _sectionHeader('الشروط والأحكام', t),
          const SizedBox(height: 12),
          ...terms.asMap().entries.map(
                (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    '${entry.key + 1}. ',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: t.bodySmall.copyWith(height: 1.6),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _influencerAcknowledgments(FlutterFlowTheme t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _allAcked ? const Color(0xFF16A34A) : t.alternate,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'نموذج موافقة المؤثر (إلزامي لقبول العرض)',
                style: t.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified_user_outlined, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'لا يمكن القبول بدون التأشير على جميع البنود ❌',
            style: t.bodySmall.copyWith(color: const Color(0xFFDC2626)),
          ),
          const SizedBox(height: 12),
          ..._acks.keys.map(
                (key) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CheckboxListTile(
                value: _acks[key]!,
                onChanged: (v) => setState(() => _acks[key] = v!),
                title: Text(
                  _ackLabels[key]!,
                  style: t.bodySmall.copyWith(height: 1.5),
                  textAlign: TextAlign.start,
                ),
                controlAffinity: ListTileControlAffinity.trailing,
                activeColor: t.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectionReasonField(FlutterFlowTheme t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'سبب رفض العرض (اختياري)',
            style: t.titleSmall.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              controller: _rejectionReasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض إن أردت...',
                filled: true,
                fillColor: t.tertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _influencerActionButtons(FlutterFlowTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isSubmitting || !_allAcked ? null : _acceptOffer,
          icon: _isSubmitting
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.check_circle_outline),
          label: const Text(
            'موافقة ومتابعة لدفع رسوم التعاون',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _allAcked ? const Color(0xFF16A34A) : null,
            disabledBackgroundColor: const Color(0xFFD1D5DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'رسوم منصة إعلان: 99 ريال سعودي — تُدفع عند قبول العرض كرسوم خدمة تقنية فقط.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _isSubmitting ? null : _rejectOffer,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFDC2626)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'رفض العرض',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, FlutterFlowTheme t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: t.titleSmall.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _contractRow(String label, String value, FlutterFlowTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Text('• ', style: t.bodyMedium.copyWith(color: t.primary)),
          Expanded(
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.primaryText,
                    ),
                  ),
                  TextSpan(
                    text: value.isEmpty ? '—' : value,
                    style: t.bodyMedium.copyWith(color: t.secondaryText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}