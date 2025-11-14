import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'payment_details_page.dart';

class PaymentPage extends StatefulWidget {
  static const String routeName = 'payment_page';
  static const String routePath = '/payment_page';

  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedPlan;

  final List<Map<String, dynamic>> plans = [
    {
      'id': 'basic',
      'name': 'الخطة الأساسية',
      'price': 'SAR 99',
      'duration': 'شهرياً',
      'features': [
        'إنشاء حتى 15 حملة إعلانية',
        'دعم أساسي عبر البريد الإلكتروني',
        'إحصائيات أداء أساسية',
      ],
      'color': Color(0xFF182B54),
    },
    {
      'id': 'premium',
      'name': 'الخطة المميزة',
      'price': 'SAR 999',
      'duration': 'سنوياً',
      'features': [
        'حملات غير محدودة',
        'دعم فني مباشر',
        'تحليلات متقدمة للحملات',
        'مدة الاشتراك 2 سنوات',
      ],
      'color': Colors.amber.shade700,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: t.backgroundElan,
        appBar: AppBar(
          backgroundColor: t.containers,
          centerTitle: true,
          elevation: 0,
          title: Text(
            'الاشتراك والدفع',
            style: GoogleFonts.interTight(
              textStyle: t.headlineSmall.copyWith(color: t.primaryText),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.primaryText, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: t.containers,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon section
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.payment, size: 40, color: t.primary),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'اختر خطة الاشتراك',
                      style: t.headlineSmall.copyWith(
                        color: t.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'اختر الخطة المناسبة لاحتياجاتك وابدأ في إنشاء حملاتك الإعلانية.',
                      style: t.bodyMedium.copyWith(color: t.secondaryText, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Plans section
                    ...plans.map((plan) {
                      final isSelected = selectedPlan == plan['id'];
                      return GestureDetector(
                        onTap: () => setState(() => selectedPlan = plan['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? plan['color'].withOpacity(0.1)
                                : t.primaryBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? plan['color'] : t.primary.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    plan['name'],
                                    style: t.titleMedium.copyWith(
                                      color: t.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: plan['color'],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      plan['duration'],
                                      style: t.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...plan['features'].map<Widget>(
                                (feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: t.success, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: t.bodyMedium.copyWith(color: t.primaryText),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                plan['price'],
                                style: t.headlineLarge.copyWith(
                                  color: t.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Payment button
                    FFButtonWidget(
                      onPressed: selectedPlan == null
                          ? () {}
                          : () {
                              // Navigate to payment details page
                              Navigator.pushNamed(
                                context,
                                PaymentDetailsPage.routeName,
                                arguments: selectedPlan,
                              );
                            },
                      text: selectedPlan == null ? 'اختر خطة للمتابعة' : 'المتابعة للدفع',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50,
                        color: selectedPlan == null ? t.secondaryText.withOpacity(0.3) : t.primary,
                        textStyle: GoogleFonts.interTight(
                          textStyle: t.titleMedium.copyWith(
                            color: selectedPlan == null ? t.primaryText : Colors.white,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'إلغاء',
                        style: t.bodyMedium.copyWith(
                          color: t.secondaryText,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
