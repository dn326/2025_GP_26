import 'package:elan_flutterproject/flutter_flow/flutter_flow_icon_button.dart';
import 'package:flutter/material.dart';

import '../../flutter_flow/flutter_flow_theme.dart';

class TermsAndPrivacyPage extends StatelessWidget {
  const TermsAndPrivacyPage({super.key});

  static String routeName = 'terms_and_privacy';
  static String routePath = '/termsAndPrivacy';

  final List<Map<String, String>> termsSections = const [
    {
      'title': 'شروط استخدام منصة إعلان وسياسة الخصوصية',
      'content':
          'تهدف منصة إعلان إلى تسهيل التعاون بين الشركات والمؤثرين عبر بيئة رقمية آمنة واحترافية. '
          'استخدامك للمنصة يعني اطلاعك على هذه السياسة و موافقتك على الشروط الواردة فيها.',
    },
    {
      'title': '1. صحة المعلومات التي يزوّدها المستخدم',
      'content':
          'يضمن المستخدم أن جميع البيانات المقدمة صحيحة ودقيقة ومحدثة.\n'
          'تلتزم المنصة باتخاذ الإجراءات اللازمة لتصحيح أو تحديث البيانات إذا ثبت وجود خطأ ناتج عن النظام أو عن عملية المعالجة.\n'
          'تحتفظ المنصة بحق رفض أو تعليق التسجيل في حال ثبوت وجود بيانات غير صحيحة أو مخالفة للواقع.',
    },
    {
      'title': '2. إنشاء الحساب واستخدامه',
      'content':
          'يُسمح لكل مستخدم بامتلاك حساب واحد فقط في منصة إعلان.\n'
          'يتعهد المستخدم بأنه هو الوحيد المخوّل باستخدام حسابه، ويتحمّل كامل المسؤولية عن أي نشاط يتم من خلاله.',
    },
    {
      'title': '3. عمر المستخدم',
      'content':
          'يشترط أن يكون عمر المستخدم 18 سنة أو أكثر.\n'
          'يتم التحقق من العمر أثناء التسجيل بشكل آلي.',
    },
    {
      'title': '4. التحقق من الهوية',
      'content':
          'تُجري المنصة عملية تحقق آلية لضمان موثوقية المستخدمين.\n'
          'يشمل التحقق: رقم الجوال، البريد الإلكتروني، العمر، شهادة "موثوق" للمؤثرين، والسجل التجاري للشركات.\n'
          'في حال عدم استيفاء المتطلبات أو وجود بيانات غير دقيقة، يتم رفض التسجيل لحماية المستخدمين.',
    },
    {
      'title': '5. شهادة "موثوق" للمؤثرين',
      'content':
          'يجب على المؤثر إدخال رقم شهادة "موثوق" الصادرة من الهيئة العامة للإعلام المرئي والمسموع قبل ممارسة أي إعلان تجاري.\n'
          'تتحقق المنصة من صحة الشهادة أثناء التسجيل.',
    },
    {
      'title': '6. التحقق من السجل التجاري للشركات',
      'content':
          'يتعين على الشركات إدخال رقم السجل التجاري الصحيح والساري المفعول، وتتحقق المنصة من صحته أثناء التسجيل.',
    },
    {
      'title': '7. مخالفة الشروط أو إساءة الاستخدام',
      'content':
          'يُمنع القيام بما يلي:\n'
          '- إدخال معلومات أو وثائق مزيفة.\n'
          '- استخدام الحساب من قبل أكثر من شخص.\n'
          '- محاولة تجاوز نظام التحقق أو التلاعب بالبيانات.\n'
          'وفي حال ارتكاب أي من هذه المخالفات، يتحمل المستخدم كامل المسؤولية عن النتائج المترتبة.',
    },
    {
      'title': '8. معالجة البيانات الشخصية',
      'content':
          'تقوم المنصة بجمع ومعالجة البيانات الشخصية لأغراض تشغيل النظام وتحسين تجربة المستخدم.\n'
          'لا تتم معالجة أو تحليل سلوك المستخدم لأغراض تسويقية أو إحصائية إلا بعد الحصول على موافقة صريحة منه.\n'
          'توضح المنصة للمستخدم نوع البيانات التي يتم جمعها والغرض من استخدامها ومدة الاحتفاظ بها وفق المادة (12) من نظام حماية البيانات الشخصية.',
    },
    {
      'title': '9. حماية الخصوصية والبيانات',
      'content':
          'تلتزم المنصة بالمحافظة على خصوصية المستخدمين وفق نظام حماية البيانات الشخصية السعودي (PDPL).\n'
          'كما تلتزم بحماية بياناتهم من الوصول أو المعالجة أو النقل غير المصرح بها.\n'
          'لا تتم مشاركة المعلومات الشخصية أو التجارية مع أي طرف ثالث دون موافقة صريحة من المستخدم.',
    },
    {
      'title': '10. تصحيح وتحديث البيانات',
      'content':
          'تلتزم المنصة بتمكين المستخدم من تحديث بياناته الشخصية في أي وقت.\n'
          'وفي حال وجود خطأ ناتج عن النظام في عرض أو تحديث البيانات، تتحمل المنصة مسؤولية تصحيحه فورًا.',
    },
    {
      'title': '11. مشاركة المعلومات الشخصية',
      'content':
          'إذا قام المستخدم بمشاركة بياناته الشخصية مع مستخدمين آخرين داخل المنصة أو خارجها، فإن ذلك يتم على مسؤوليته الشخصية الكاملة.',
    },
    {
      'title': '12. المعلومات المالية والدفع الإلكتروني',
      'content':
          'تستخدم المنصة نظام دفع إلكتروني آمن معتمد.\n'
          'لا تحتفظ المنصة بمعلومات الدفع بعد إتمام العملية.\n'
          'المنصة غير مسؤولة عن أي أخطاء ناتجة عن إدخال بيانات دفع غير صحيحة.',
    },
    {
      'title': '13. رسوم الخدمة',
      'content':
          'تفرض المنصة رسومًا رمزية مقابل دورها كوسيط، وتُعرض نسبة الرسوم بوضوح قبل إتمام أي اتفاق.\n'
          'تقتصر مسؤولية المنصة على عمليات الدفع المنفذة داخل التطبيق فقط.',
    },
    {
      'title': '14. إخلاء المسؤولية',
      'content':
          'تعمل المنصة كوسيط بين الشركات والمؤثرين، ولا تُعد طرفًا قانونيًا في أي اتفاق بينهما.\n'
          'لا تتحمل المنصة مسؤولية جودة الخدمات أو نتائج الحملات أو أي نزاع بين المستخدمين.',
    },
    {
      'title': '15. تعديل السياسة',
      'content':
          'تحتفظ المنصة بحق تعديل سياسة الاستخدام أو الخصوصية، مع التزامها بإشعار المستخدمين بشكل صريح قبل بدء تطبيق التعديلات.',
    },
    {
      'title': '16. القانون المطبق',
      'content':
          'تخضع هذه السياسة لأنظمة وقوانين المملكة العربية السعودية.\n'
          'في حال وجود نزاع، يُسعى أولًا للحل الودي، وإن تعذر يُحال للجهات المختصة داخل المملكة.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x33000000),
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            automaticallyImplyLeading: false,
            elevation: 0,
            // set to 0 so the custom shadow is visible
            titleSpacing: 0,
            title: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FlutterFlowIconButton(
                        borderRadius: 8.0,
                        buttonSize: 40.0,
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 24.0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 6, // move title slightly lower
                      child: Text(
                        'انشاء الحساب',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(
                          context,
                        ).headlineSmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.rtl, // Ensure full right alignment
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: termsSections.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: RichText(
                  text: TextSpan(
                    style: theme.bodyMedium.copyWith(
                      height: 1.5,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                    children: [
                      TextSpan(
                        text: '${section['title']!}\n',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: section['content']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
