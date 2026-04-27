import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OfferContractPdfServiceNew {
  // ── Tune this one value to control all vertical spacing in the PDF ──────────
  static const double _sp = 8.0;
  // ── Font sizes ───────────────────────────────────────────────────────────────
  static const double _fzTitle  = 15.0;
  static const double _fzSub    = 10.0;
  static const double _fzHead   = 11.0;
  static const double _fzBody   = 9.5;
  static const double _fzFooter = 8.0;

  /* ─── helpers ─────────────────────────────────────────────────────────────── */

  static String _toArabicNumber(int n) {
    const w = ['0','1','2','3','4','5','6','7','8','9'];
    const e = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((d) => e[w.indexOf(d)]).join();
  }

  static String _fmtTs(dynamic v) {
    if (v == null) return '—';
    DateTime dt;
    if (v is DateTime) {
      dt = v;
    } else if (v.runtimeType.toString() == 'Timestamp') {
      dt = v.toDate();
    } else {
      return v.toString();
    }
    return '${_toArabicNumber(dt.day)}/${_toArabicNumber(dt.month)}/${_toArabicNumber(dt.year)}';
  }

  static String _fileBase(Map<String, dynamic> offer) {
    final title = (offer['campaign_title'] ?? 'offer').toString();
    return 'contract_${title.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_')}';
  }

  /* ─── build ───────────────────────────────────────────────────────────────── */

  static Future<Uint8List> buildPdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final bold    = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));

    Uint8List? logo;
    try {
      logo = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
    } catch (_) {}

    final pdf = pw.Document(title: 'عقد تعاون تسويقي');

    final terms = [
      'يتم تنفيذ جميع المدفوعات المالية خارج منصة إعلان.',
      'دور منصة إعلان تقني فقط، ولا تشارك في التفاوض أو التنفيذ أو الدفع.',
      'يتحمل الطرفان المسؤولية الكاملة عن تنفيذ هذا التعاون.',
      'يلتزم المؤثر بتنفيذ المحتوى وفق الأنظمة المعمول بها في المملكة العربية السعودية.',
      'يُعد هذا العرض اتفاقاً أولياً، وأي تعديل يتم مباشرةً بين الطرفين.',
      'يُحل أي نزاع مباشرةً بين الطرفين دون تدخل أو مسؤولية على منصة إعلان.',
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: _sp * 4, vertical: _sp * 3),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('إعلان', style: pw.TextStyle(font: bold, fontSize: _fzTitle)),
                      pw.Text('وثيقة تعاون قابلة للطباعة والمشاركة',
                          style: pw.TextStyle(font: regular, fontSize: _fzFooter)),
                    ],
                  ),
                  if (logo != null)
                    pw.Image(pw.MemoryImage(logo), height: _sp * 7)
                  else
                    pw.SizedBox(width: _sp * 7),
                ],
              ),
              pw.SizedBox(height: _sp),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: _sp),

              // ── Title ────────────────────────────────────────────────────────
              pw.Center(
                child: pw.Column(children: [
                  pw.Text('عقد تعاون تسويقي',
                      style: pw.TextStyle(font: bold, fontSize: _fzTitle)),
                  pw.SizedBox(height: _sp * 0.5),
                  pw.Text('العقد النهائي – (بعد القبول)',
                      style: pw.TextStyle(font: regular, fontSize: _fzSub,
                          color: PdfColors.grey600)),
                ]),
              ),
              pw.SizedBox(height: _sp),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: _sp),

              // ── Two-column layout: parties + campaign / collaboration + terms ─
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _section('بيانات الأطراف', [
                          ['الطرف الأول', offer['business_name'] ?? '—'],
                          ['الطرف الثاني', offer['influencer_name'] ?? '—'],
                          ['تاريخ العقد', _fmtTs(offer['accepted_at'] ?? offer['created_at'])],
                        ], bold, regular),
                        pw.SizedBox(height: _sp),
                        _section('معلومات الحملة', [
                          ['عنوان الحملة', offer['campaign_title'] ?? '—'],
                          ['نوع المحتوى', offer['influencer_content_type_name'] ?? '—'],
                          ['تفاصيل الحملة', offer['campaign_description'] ?? '—'],
                        ], bold, regular),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: _sp),
                  // Right column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _section('تفاصيل التعاون', [
                          ['المحتوى المطلوب', contentSummary],
                          ['منصات النشر', platformsLabel],
                          if (stylesLabel.isNotEmpty) ['أسلوب المحتوى', stylesLabel],
                          ['مدة التعاون',
                            'من ${_fmtTs(offer['collaboration_start'])} إلى ${_fmtTs(offer['collaboration_end'])}'],
                          ['المقابل المالي',
                            '${_toArabicNumber((offer['amount'] ?? 0).toInt())} ريال سعودي'],
                        ], bold, regular),
                        pw.SizedBox(height: _sp),
                        _termsSection(terms, bold, regular),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: _sp),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: _sp * 0.5),

              // ── Footer ───────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('هذه الوثيقة تم إنشاؤها من داخل منصة إعلان وهي صالحة للطباعة والمشاركة.',
                      style: pw.TextStyle(font: regular, fontSize: _fzFooter,
                          color: PdfColors.grey500)),
                  pw.Text('نسخة إلكترونية',
                      style: pw.TextStyle(font: regular, fontSize: _fzFooter,
                          color: PdfColors.grey400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /* ─── actions ─────────────────────────────────────────────────────────────── */

  static Future<void> printPdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final bytes = await buildPdf(
        offer: offer, contentSummary: contentSummary,
        platformsLabel: platformsLabel, stylesLabel: stylesLabel);
    await Printing.layoutPdf(name: '${_fileBase(offer)}.pdf', onLayout: (_) async => bytes);
  }

  static Future<void> sharePdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final bytes = await buildPdf(
        offer: offer, contentSummary: contentSummary,
        platformsLabel: platformsLabel, stylesLabel: stylesLabel);
    await Printing.sharePdf(bytes: bytes, filename: '${_fileBase(offer)}.pdf');
  }

  static Future<void> downloadPdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final bytes = await buildPdf(
        offer: offer, contentSummary: contentSummary,
        platformsLabel: platformsLabel, stylesLabel: stylesLabel);
    await FileSaver.instance.saveFile(
        name: _fileBase(offer), bytes: bytes, ext: 'pdf', mimeType: MimeType.pdf);
  }

  /* ─── pdf widgets ─────────────────────────────────────────────────────────── */

  static pw.Widget _section(
      String title,
      List<List<dynamic>> rows,
      pw.Font bold,
      pw.Font regular,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(_sp),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(title, style: pw.TextStyle(font: bold, fontSize: _fzHead)),
          pw.SizedBox(height: _sp * 0.5),
          pw.Divider(thickness: 0.3, color: PdfColors.grey300),
          pw.SizedBox(height: _sp * 0.5),
          ...rows.map((r) => pw.Padding(
            padding: pw.EdgeInsets.only(bottom: _sp * 0.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('${r[0]}:',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: bold, fontSize: _fzBody)),
                ),
                pw.SizedBox(width: _sp * 0.5),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(r[1]?.toString() ?? '—',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: regular, fontSize: _fzBody)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _termsSection(
      List<String> terms,
      pw.Font bold,
      pw.Font regular,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(_sp),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('الشروط والأحكام', style: pw.TextStyle(font: bold, fontSize: _fzHead)),
          pw.SizedBox(height: _sp * 0.5),
          pw.Divider(thickness: 0.3, color: PdfColors.grey300),
          pw.SizedBox(height: _sp * 0.5),
          ...terms.asMap().entries.map((e) => pw.Padding(
            padding: pw.EdgeInsets.only(bottom: _sp * 0.4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${_toArabicNumber(e.key + 1)}.',
                    style: pw.TextStyle(font: bold, fontSize: _fzBody)),
                pw.SizedBox(width: _sp * 0.4),
                pw.Expanded(
                  child: pw.Text(e.value,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: regular, fontSize: _fzBody, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}