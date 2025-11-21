import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../../services/subscription_model.dart';
import '../payment/payment_page.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  static const String routeName = 'subscription_details';
  static const String routePath = '/subscription_details';

  final SubscriptionModel subscriptionData;

  const SubscriptionDetailsPage({super.key, required this.subscriptionData});

  @override
  State<SubscriptionDetailsPage> createState() => _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Validate subscription data
    if (widget.subscriptionData.id.isEmpty || widget.subscriptionData.planType == null) {
      return Scaffold(
        backgroundColor: theme.backgroundElan,
        appBar: AppBar(
          backgroundColor: theme.containers,
          centerTitle: true,
          elevation: 0,
          title: Text(
            'تفاصيل الاشتراك',
            style: theme.headlineSmall.copyWith(color: theme.primaryText),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryText, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.error),
                const SizedBox(height: 16),
                Text(
                  'لم يتم العثور على بيانات الاشتراك',
                  style: theme.titleLarge.copyWith(color: theme.primaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FFButtonWidget(
                  onPressed: () => Navigator.of(context).pop(),
                  text: 'رجوع',
                  options: FFButtonOptions(
                    width: 160,
                    height: 50,
                    color: theme.primary,
                    textStyle: theme.titleSmall.copyWith(color: Colors.white),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundElan,
      appBar: AppBar(
        backgroundColor: theme.containers,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'تفاصيل الاشتراك',
          style: theme.headlineSmall.copyWith(color: theme.primaryText),
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
              _buildPlanInfoCard(),
              const SizedBox(height: 16),
              _buildUsageStats(),
              const SizedBox(height: 16),
              _buildExpiryInfo(),
              const SizedBox(height: 24),
              _buildUpgradeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanInfoCard() {
    final theme = FlutterFlowTheme.of(context);

    // Get plan name in Arabic
    String planName;
    String planPrice;
    String billingPeriod;

    if (widget.subscriptionData.isPremium) {
      planName = 'الخطة المتميزة';
      planPrice = '500';
      billingPeriod = '(سنتان)';
    } else {
      planName = 'الباقة الأساسية';
      planPrice = ' 300';
      billingPeriod = '';
    }

    // Get subscription start date
    String formattedStartDate = 'غير محدد';

    if (widget.subscriptionData.startDate != null) {
      formattedStartDate = DateFormat('yyyy/MM/dd').format(widget.subscriptionData.startDate!);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.containers,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Plan name
          Text(
            planName,
            style: theme.titleLarge.copyWith(
              fontFamily: GoogleFonts.interTight().fontFamily,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 16),

          // Price and billing period
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(billingPeriod, style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
              SvgPicture.asset('assets/svg/riyal.svg', color: Colors.black, width: 24),

              const SizedBox(width: 8),
              Text(
                planPrice,
                style: theme.headlineLarge.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(color: theme.secondaryText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),

          // Start date
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                formattedStartDate,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text('تاريخ البدء:', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    // Only show for basic users
    if (!widget.subscriptionData.isBasic) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final campaignsUsed = widget.subscriptionData.campaignsUsed;
    final campaignLimit = widget.subscriptionData.campaignLimit;

    // Calculate percentage
    final percentage = campaignLimit > 0 ? (campaignsUsed / campaignLimit) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.containers,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'إحصائيات الاستخدام',
            style: theme.titleMedium.copyWith(
              fontFamily: GoogleFonts.interTight().fontFamily,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 16),

          // Campaign usage
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$campaignsUsed / $campaignLimit',
                style: theme.headlineSmall.copyWith(
                  fontFamily: GoogleFonts.interTight().fontFamily,
                  color: theme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الحملات المستخدمة:',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: theme.secondaryText.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 0.9 ? theme.warning : theme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Percentage text
          Text(
            '${(percentage * 100).toStringAsFixed(0)}% مستخدم',
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryInfo() {
    // Only show for premium users
    if (!widget.subscriptionData.isPremium) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final expiryDate = widget.subscriptionData.expiryDate;

    if (expiryDate == null) {
      return const SizedBox.shrink();
    }

    // Calculate days remaining
    final daysRemaining = widget.subscriptionData.daysRemaining ?? 0;

    // Format expiry date
    final formattedExpiryDate = DateFormat('yyyy/MM/dd').format(expiryDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.containers,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x33000000), offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'معلومات الاشتراك',
            style: theme.titleMedium.copyWith(
              fontFamily: GoogleFonts.interTight().fontFamily,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 16),

          // Expiry date
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                formattedExpiryDate,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text('تاريخ الانتهاء:', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
            ],
          ),
          const SizedBox(height: 12),

          // Days remaining
          if (daysRemaining > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$daysRemaining يوم',
                  style: theme.headlineSmall.copyWith(
                    fontFamily: GoogleFonts.interTight().fontFamily,
                    color: daysRemaining < 30 ? theme.warning : theme.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'الأيام المتبقية:',
                  style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ] else ...[
            Text(
              'انتهى الاشتراك',
              style: theme.bodyMedium.copyWith(color: theme.error, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    // Only show for basic users
    if (!widget.subscriptionData.isBasic) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);

    return FFButtonWidget(
      icon: SvgPicture.asset('assets/svg/star.svg', width: 20, color: theme.pagesBackground),
      onPressed: isProcessing ? null : _navigateToUpgrade,
      text: 'الترقية الئ الخطة المتميزة',
      options: FFButtonOptions(
        width: double.infinity,
        height: 50,
        color: Color(0xFF182B54),
        textStyle: GoogleFonts.interTight(
          textStyle: theme.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _navigateToUpgrade() {
    setState(() {
      isProcessing = true;
    });

    // Navigate to PaymentPage with 'premium' as pre-selected plan
    Navigator.pushNamed(context, PaymentPage.routeName, arguments: 'premium').then((_) {
      // Reset processing state when returning
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
        // Pop back to profile to refresh subscription data
        Navigator.of(context).pop();
      }
    });
  }
}
