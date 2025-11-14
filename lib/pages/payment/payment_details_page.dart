import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/subscription_service.dart';

class PaymentDetailsPage extends StatefulWidget {
  static const String routeName = 'payment_details_page';
  static const String routePath = '/payment_details';

  const PaymentDetailsPage({super.key, required this.planId});

  final String planId;

  static PaymentDetailsPage fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    return PaymentDetailsPage(planId: args ?? 'basic');
  }

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  String? selectedPaymentMethod;
  bool isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'credit_card',
      'name': 'بطاقة ائتمان',
      'icon': Icons.credit_card,
      'description': '**** **** **** 1234',
    },
    {'id': 'apple_pay', 'name': 'Apple Pay', 'icon': Icons.apple, 'description': 'محفظة Apple'},
    {
      'id': 'wallet',
      'name': 'المحفظة الإلكترونية',
      'icon': Icons.account_balance_wallet,
      'description': 'رصيد المحفظة',
    },
  ];

  Map<String, dynamic> get planDetails {
    if (widget.planId == 'basic') {
      return {
        'name': 'الخطة الأساسية',
        'price': 99,
        'currency': 'SAR',
        'duration': 'شهرياً',
        'plan_type': 'basic',
      };
    } else {
      return {
        'name': 'الخطة المميزة',
        'price': 999,
        'currency': 'SAR',
        'duration': 'سنوياً',
        'plan_type': 'premium',
      };
    }
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null) return;

    setState(() => isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final subscriptionService = SubscriptionService();

      // Get or create subscription
      final existingSubscription = await subscriptionService.getSubscription();
      String subscriptionId;

      if (existingSubscription != null) {
        subscriptionId = existingSubscription['id'];
        // Update existing subscription
        await FirebaseFirestore.instance.collection('subscriptions').doc(subscriptionId).update({
          'plan_type': planDetails['plan_type'],
          'start_date': FieldValue.serverTimestamp(),
          'campaigns_used': 0, // Reset for new plan
        });
      } else {
        // Create new subscription
        final newSubscriptionRef = FirebaseFirestore.instance.collection('subscriptions').doc();
        subscriptionId = newSubscriptionRef.id;

        await newSubscriptionRef.set({
          'id': subscriptionId,
          'user_id': user.uid,
          'plan_type': planDetails['plan_type'],
          'start_date': FieldValue.serverTimestamp(),
          'campaigns_used': 0,
          'created_at': FieldValue.serverTimestamp(),
          'campaign_limit': 15,
        });

        // Update user with subscription ID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'subscription_id': subscriptionId,
        });
      }

      // Create payment record
      await FirebaseFirestore.instance.collection('payments').add({
        'amount': planDetails['price'],
        'created_at': FieldValue.serverTimestamp(),
        'currency': planDetails['currency'],
        'is_simulated': true,
        'status': 'completed',
        'subscription_id': subscriptionId,
        'user_id': user.uid,
        'payment_method': selectedPaymentMethod,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت عملية الدفع بنجاح!')));

        // Navigate back to main screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشلت عملية الدفع: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

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
            'تفاصيل الدفع',
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
                    // Plan details section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: t.primaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.primary.withOpacity(0.2), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            planDetails['name'],
                            style: t.titleLarge.copyWith(
                              color: t.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.planId == 'basic'
                                  ? Colors.blueAccent
                                  : Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              planDetails['duration'],
                              style: t.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${planDetails['price']} ${planDetails['currency']}',
                            style: t.headlineLarge.copyWith(
                              color: t.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Payment methods section
                    Text(
                      'اختر طريقة الدفع',
                      style: t.titleLarge.copyWith(
                        color: t.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    ...paymentMethods.map((method) {
                      final isSelected = selectedPaymentMethod == method['id'];
                      return GestureDetector(
                        onTap: () => setState(() => selectedPaymentMethod = method['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? t.primary.withOpacity(0.1) : t.primaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? t.primary : t.secondaryText.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: t.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(method['icon'], color: t.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method['name'],
                                      style: t.titleSmall.copyWith(
                                        color: t.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      method['description'],
                                      style: t.bodySmall.copyWith(color: t.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) Icon(Icons.check_circle, color: t.primary, size: 24),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Pay button
                    FFButtonWidget(
                      onPressed: (selectedPaymentMethod != null && !isProcessing)
                          ? () => _processPayment()
                          : () {},
                      text: selectedPaymentMethod == null
                          ? 'اختر طريقة دفع للمتابعة'
                          : isProcessing
                          ? 'جاري المعالجة...'
                          : 'ادفع الآن',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50,
                        color: selectedPaymentMethod == null || isProcessing
                            ? t.secondaryText.withOpacity(0.3)
                            : t.primary,
                        textStyle: GoogleFonts.interTight(
                          textStyle: t.titleMedium.copyWith(
                            color: selectedPaymentMethod == null ? t.primaryText : Colors.white,
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
