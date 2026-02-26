import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '../../core/services/subscription_local_storage.dart';
import '../../core/services/subscription_model.dart';
import '../../core/services/subscription_service.dart';

class PaymentDetailsPage extends StatefulWidget {
  static const String routeName = 'payment_details_page';
  static const String routePath = '/payment_details';

  const PaymentDetailsPage({super.key, required this.planId, this.returnAfterPayment = false});

  final String planId;

  /// When true, after successful payment this page will pop with result=true
  /// instead of navigating to home. Used for offer fee payment flow.
  final bool returnAfterPayment;

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  String? selectedPaymentMethod;
  bool isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {'id': 'credit_card', 'name': 'بطاقة ائتمان', 'icon': Icons.credit_card, 'description': '**** **** **** 1234'},
    {'id': 'apple_pay', 'name': 'Apple Pay', 'icon': Icons.apple, 'description': 'محفظة Apple'},
    {
      'id': 'wallet',
      'name': 'المحفظة الإلكترونية',
      'icon': Icons.account_balance_wallet,
      'description': 'رصيد المحفظة',
    },
  ];

  Map<String, dynamic> get planDetails {
    switch (widget.planId) {
      case 'basic':
        return {
          'name': 'الخطة الأساسية',
          'price': 300,
          'currency': '',
          'duration': '',
          'plan_type': 'basic',
          'is_subscription': true,
        };
      case 'premium':
        return {
          'name': 'الخطة المميزة',
          'price': 500,
          'currency': '',
          'duration': '',
          'plan_type': 'premium',
          'is_subscription': true,
        };
      case 'offer_fee':
      default:
        return {
          'name': 'رسوم قبول العرض',
          'price': 99,
          'currency': '',
          'duration': '',
          'plan_type': 'offer_fee',
          'is_subscription': false,
        };
    }
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null) return;

    setState(() => isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final isSubscription = planDetails['is_subscription'] as bool;

      if (isSubscription) {
        // ── Subscription payment flow ─────────────────────────────────────────
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت عملية الدفع بنجاح!')));

        // Save subscription data to local storage after successful payment
          try {
          // Fetch the subscription from Firestore to get the actual server timestamp
            final subscriptionDoc = await FirebaseFirestore.instance
                .collection('subscriptions')
                .doc(subscriptionId)
                .get();

            if (subscriptionDoc.exists) {
              final subscriptionData = subscriptionDoc.data()!;
              final subscriptionModel = SubscriptionModel.fromMap({'id': subscriptionId, ...subscriptionData});
              await SubscriptionLocalStorage.saveSubscription(subscriptionModel);
            }
          } catch (localStorageError) {
          // Log the error but don't show to user since payment succeeded
            log('Failed to save subscription to local storage: $localStorageError');
          }

          if (widget.returnAfterPayment) {
            Navigator.of(context).pop(true);
          } else {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
            Navigator.of(context).pushNamed('home_page', arguments: 3);
          }
        }
      } else {
        // ── Offer fee payment flow ────────────────────────────────────────────
        await FirebaseFirestore.instance.collection('payments').add({
          'amount': planDetails['price'],
          'created_at': FieldValue.serverTimestamp(),
          'currency': planDetails['currency'],
          'is_simulated': true,
          'status': 'completed',
          'payment_type': 'offer_fee',
          'user_id': user.uid,
          'payment_method': selectedPaymentMethod,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت عملية الدفع بنجاح!')));

          if (widget.returnAfterPayment) {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).pop(true);
          }
        }
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
            style: GoogleFonts.interTight(textStyle: t.headlineSmall.copyWith(color: t.primaryText)),
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
                decoration: BoxDecoration(color: t.containers, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Plan details
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: t.primaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.primary.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            planDetails['name'],
                            style: t.titleLarge.copyWith(color: t.primaryText, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${planDetails['price']}',
                                style: t.headlineLarge.copyWith(color: t.primary, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset('assets/svg/riyal.svg', width: 30),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Payment methods section
                    Text(
                      'اختر طريقة الدفع',
                      style: t.titleLarge.copyWith(color: t.primaryText, fontWeight: FontWeight.w600),
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
                            color: isSelected ? t.primary.withValues(alpha: 0.1) : t.primaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? t.primary : t.secondaryText.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected) Icon(Icons.check_circle, color: t.primary, size: 24),
                              const Spacer(),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      method['name'],
                                      style: t.titleSmall.copyWith(color: t.primaryText, fontWeight: FontWeight.w600),
                                    ),
                                    Text(method['description'], style: t.bodySmall.copyWith(color: t.secondaryText)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: t.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(method['icon'], color: t.primary, size: 24),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Pay button
                    FFButtonWidget(
                      onPressed: (selectedPaymentMethod != null && !isProcessing)
                          ? () async => await _processPayment()
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
                            ? t.secondaryText.withValues(alpha: 0.3)
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
                        style: t.bodyMedium.copyWith(color: t.secondaryText, fontWeight: FontWeight.w500),
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
