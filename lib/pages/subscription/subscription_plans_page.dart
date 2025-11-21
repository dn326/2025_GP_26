import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../payment/payment_page.dart';

class SubscriptionPlansPage extends StatelessWidget {
  static const String routeName = 'subscription_plans';
  static const String routePath = '/subscription_plans';

  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final plans = [
      {
        'id': 'free',
        'name': 'الخطة المجانية',
        'price': 'مجاناً',
        'duration': 'دائماً',
        'features': [
          'تصفح الحملات الإعلانية',
          'عرض ملفات المؤثرين',
          'الوصول إلى المحتوى الأساسي',
          'لا يمكن إنشاء حملات',
        ],
        'color': const Color(0xFF6B7280),
        'isCurrentPlan': true,
        'canUpgrade': false,
      },
      {
        'id': 'basic',
        'name': 'الخطة الأساسية',
        'price': '300 ريال',
        'duration': 'حتى انتهاء رصيد الحملات',
        'features': [
          'إنشاء حتى 15 حملة إعلانية',
          'دعم أساسي عبر البريد الإلكتروني',
          'إحصائيات أداء أساسية',
          'إدارة الحملات والمؤثرين',
        ],
        'color': const Color(0xFF182B54),
        'isCurrentPlan': false,
        'canUpgrade': true,
      },
      {
        'id': 'premium',
        'name': 'الخطة المميزة',
        'price': '500',
        'duration': 'سنتان',
        'features': [
          'حملات غير محدودة',
          'دعم فني مباشر',
          'تحليلات متقدمة للحملات',
          'مدة الاشتراك سنتان كاملتان',
        ],
        'color': const Color(0xFFF4EDE2),
        'isCurrentPlan': false,
        'canUpgrade': true,
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: AppBar(
          backgroundColor: theme.containers,
          centerTitle: true,
          elevation: 0,
          title: Text(
            'خطط الاشتراك',
            style: GoogleFonts.interTight(
              textStyle: theme.headlineSmall.copyWith(color: theme.primaryText),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryText, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.containers,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3,
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.workspace_premium, size: 48, color: theme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'اختر الخطة المناسبة لك',
                        style: theme.headlineSmall.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'قم بالترقية لإنشاء حملات إعلانية والوصول إلى ميزات متقدمة',
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Plans list
                ...plans.map((plan) => _buildPlanCard(context, theme, plan)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    FlutterFlowTheme theme,
    Map<String, dynamic> plan,
  ) {
    final isCurrentPlan = plan['isCurrentPlan'] as bool;
    final canUpgrade = plan['canUpgrade'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.containers,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? theme.primary : theme.secondaryText.withValues(alpha: 0.2),
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            color: Color(0x33000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'] as String,
                      style: theme.titleLarge.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['duration'] as String,
                      style: theme.bodySmall.copyWith(color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الخطة الحالية',
                    style: theme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Price
          Row(
            children: [
              SvgPicture.asset(
                'assets/svg/riyal.svg',
                colorFilter: ColorFilter.mode(
                  plan['color'] as Color,
                  BlendMode.srcIn,
                ),
                width: 28,
              ),
              const SizedBox(width: 8),
              Text(
                plan['price'] as String,
                style: theme.headlineLarge.copyWith(
                  color: plan['color'] as Color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(color: theme.secondaryText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),

          // Features
          ...(plan['features'] as List<String>).map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.bodyMedium.copyWith(
                        color: theme.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upgrade button
          if (canUpgrade) ...[
            const SizedBox(height: 16),
            FFButtonWidget(
              onPressed: () {
                // Navigate to payment page with pre-selected plan
                Navigator.pushNamed(
                  context,
                  PaymentPage.routeName,
                  arguments: plan['id'],
                );
              },
              text: 'الترقية إلى ${plan['name']}',
              options: FFButtonOptions(
                width: double.infinity,
                height: 45,
                color: plan['color'] as Color,
                textStyle: GoogleFonts.interTight(
                  textStyle: theme.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
