import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OfferContractPdfService {
  /* ───────────────────────── helpers ───────────────────────── */

  static String _toArabicNumber(int number) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    return number
        .toString()
        .split('')
        .map((d) => eastern[western.indexOf(d)])
        .join();
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

  /* ───────────────────────── build PDF ───────────────────────── */

  static Future<Uint8List> buildPdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'),
    );

    Uint8List? logo;
    try {
      logo = (await rootBundle.load('assets/images/logo.png'))
          .buffer
          .asUint8List();
    } catch (_) {}

    final pdf = pw.Document(title: 'عقد تعاون تسويقي');

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );

    final terms = [
      'يتم تنفيذ جميع المدفوعات المالية الخاصة بهذا التعاون خارج منصة إعلان.',
      'يقتصر دور منصة إعلان على توفير منصة تقنية لعرض فرص التعاون، ولا تشارك في التفاوض أو التنفيذ أو الدفع.',
      'يتحمل كل من صاحب الشركة والمؤثر المسؤولية الكاملة عن تنفيذ هذا التعاون.',
      'يلتزم المؤثر بتنفيذ المحتوى وفق الأنظمة واللوائح المعمول بها في المملكة العربية السعودية.',
      'يُعد هذا العرض اتفاقاً أولياً، وأي تعديل يتم مباشرةً بين الطرفين وخارج منصة إعلان.',
      'في حال نشوء أي نزاع، يتم حله مباشرةً بين الطرفين دون أي تدخل أو مسؤولية على منصة إعلان.',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Text(
                'نسخة إلكترونية',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: PdfColors.grey400,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${_toArabicNumber(context.pageNumber)} / ${_toArabicNumber(context.pagesCount)}',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // _header(logo, bold, regular),
                // pw.SizedBox(height: 24),
                _title(bold, regular),
                // pw.SizedBox(height: 28),

                _section(
                  'بيانات الأطراف',
                  [
                    ['الطرف الأول', offer['business_name'] ?? '—'],
                    ['الطرف الثاني', offer['influencer_name'] ?? '—'],
                    [
                      'تاريخ العقد',
                      _fmtTs(offer['accepted_at'] ?? offer['created_at'])
                    ],
                  ],
                  bold,
                  regular,
                ),

                // pw.SizedBox(height: 20),

                _section(
                  'معلومات الحملة',
                  [
                    ['عنوان الحملة', offer['campaign_title'] ?? '—'],
                    [
                      'نوع المحتوى',
                      offer['influencer_content_type_name'] ?? '—'
                    ],
                    ['تفاصيل الحملة', offer['campaign_description'] ?? '—'],
                  ],
                  bold,
                  regular,
                ),

                // pw.SizedBox(height: 20),

                _section(
                  'تفاصيل التعاون',
                  [
                    ['المحتوى المطلوب', contentSummary],
                    ['منصات النشر', platformsLabel],
                    ['أسلوب المحتوى', stylesLabel],
                    [
                      'مدة التعاون',
                      'من ${_fmtTs(offer['collaboration_start'])} إلى ${_fmtTs(offer['collaboration_end'])}'
                    ],
                    [
                      'المقابل المالي',
                      '${_toArabicNumber((offer['amount'] ?? 0).toInt())} ريال سعودي'
                    ],
                  ],
                  bold,
                  regular,
                ),

                // pw.SizedBox(height: 20),

                _termsSection(terms, bold, regular),

                // pw.SizedBox(height: 24),

                pw.Text(
                  'هذه الوثيقة تم إنشاؤها من داخل منصة إعلان وهي صالحة للطباعة والمشاركة.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: regular, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /* ───────────────────────── actions ───────────────────────── */

  static Future<void> printPdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final bytes = await buildPdf(
      offer: offer,
      contentSummary: contentSummary,
      platformsLabel: platformsLabel,
      stylesLabel: stylesLabel,
    );
    await Printing.layoutPdf(
      name: '${_fileBase(offer)}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  static Future<void> sharePdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final bytes = await buildPdf(
      offer: offer,
      contentSummary: contentSummary,
      platformsLabel: platformsLabel,
      stylesLabel: stylesLabel,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_fileBase(offer)}.pdf',
    );
  }

  static Future<void> downloadPdf({
    required Map<String, dynamic> offer,
    required String contentSummary,
    required String platformsLabel,
    required String stylesLabel,
  }) async {
    final bytes = await buildPdf(
      offer: offer,
      contentSummary: contentSummary,
      platformsLabel: platformsLabel,
      stylesLabel: stylesLabel,
    );
    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: _fileBase(offer),
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } else {
      await FileSaver.instance.saveAs(
        name: _fileBase(offer),
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    }
  }

  /* ───────────────────────── widgets ───────────────────────── */

  static pw.Widget _header(
    Uint8List? logo,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('إعلان', style: pw.TextStyle(font: bold, fontSize: 14)),
            pw.Text(
              'وثيقة تعاون قابلة للطباعة والمشاركة',
              style: pw.TextStyle(font: regular, fontSize: 9),
            ),
          ],
        ),
        if (logo != null)
          pw.Image(pw.MemoryImage(logo), height: 100)
        else
          pw.SizedBox(width: 100),
      ],
    );
  }

  static pw.Widget _title(pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        // borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.fromBorderSide(pw.BorderSide.none),
      ),
      child: pw.Column(
        children: [
          pw.Text('عقد تعاون تسويقي',
              style: pw.TextStyle(font: bold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text('العقد النهائي',
              style: pw.TextStyle(font: regular, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _section(
      String title,
      List<List<dynamic>> rows,
      pw.Font bold,
      pw.Font regular,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.symmetric(
            horizontal: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 13)),
          pw.SizedBox(height: 12),
          ...rows.map(
                (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start, // ← added
                children: [
                  pw.Text(
                    '${r[0]}:',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: bold, fontSize: 9),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Expanded(          // ← THIS is the critical fix for Android
                    child: pw.Text(
                      r[1]?.toString() ?? '—',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: regular, fontSize: 9),
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

  static pw.Widget _termsSection(
    List<String> terms,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        // borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.symmetric(
            horizontal: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('الشروط والأحكام',
              style: pw.TextStyle(font: bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          ...terms.asMap().entries.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${_toArabicNumber(e.key + 1)}.',
                        style: pw.TextStyle(font: bold, fontSize: 9),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        child: pw.Text(
                          e.value,
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: regular,
                            fontSize: 8,
                            height: 1.2,
                          ),
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
}
