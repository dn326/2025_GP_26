import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/payment/payment_details_page.dart';
import '../../features/payment/payment_page.dart';
import '../../flutter_flow/flutter_flow_theme.dart';

/// Shows a dialog for free users who need to subscribe
Future<bool?> showSubscriptionRequiredDialog(BuildContext context) async {
  final theme = FlutterFlowTheme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.containers,
          icon: Icon(Icons.card_membership, size: 48, color: theme.primary),
          title: Text(
            'يرجي الاشتراك',
            style: GoogleFonts.getFont(
              'Readex Pro',
              color: theme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'إشتراكك الحالي لا يسمح لك بطرح او إضافة الحملات',
            style: GoogleFonts.getFont('Readex Pro', color: theme.secondaryText, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(foregroundColor: theme.secondaryText),
              child: Text('إلغاء', style: GoogleFonts.getFont('Readex Pro', fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'الاشتراك الآن',
                style: GoogleFonts.getFont('Readex Pro', fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shows a dialog for basic users who have reached campaign limit
Future<bool?> showUpgradeRequiredDialog(
  BuildContext context,
  int campaignsUsed,
  int campaignLimit,
) async {
  final theme = FlutterFlowTheme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.containers,
          icon: Icon(Icons.error, size: 48, color: theme.primary),
          title: Text(
            'يعتذر اضافة الحملة',
            style: GoogleFonts.getFont(
              'Readex Pro',
              color: theme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لقد وصلت إلى الحد الأقصى للحملات المخصصة في باقة إشتراكك.',
                style: GoogleFonts.getFont('Readex Pro', color: theme.secondaryText, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'الحملات المستخدمة: $campaignsUsed من $campaignLimit',
                style: GoogleFonts.getFont(
                  'Readex Pro',
                  color: theme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.center,
              child: Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(
                            context,
                            PaymentDetailsPage.routeName,
                            arguments: 'basic',
                          ).then((_) {
                            // Navigator.of(dialogContext).pop(true);
                          }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),

                      child: Text(
                        'تجديد الإشتراك',
                        style: GoogleFonts.getFont(
                          'Readex Pro',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(
                            context,
                            PaymentPage.routeName,
                            arguments: 'premium',
                          ).then((_) {
                            // Navigator.of(dialogContext).pop(true);
                          }),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        ' ترقية الباقه',
                        style: GoogleFonts.getFont(
                          'Readex Pro',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(foregroundColor: theme.secondaryText),
                    child: Text('إلغاء', style: GoogleFonts.getFont('Readex Pro', fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Shows an error dialog when subscription validation fails
Future<void> showSubscriptionErrorDialog(BuildContext context, String message) async {
  final theme = FlutterFlowTheme.of(context);

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.containers,
          icon: Icon(Icons.error_outline, size: 48, color: theme.error),
          title: Text(
            'خطأ',
            style: GoogleFonts.getFont(
              'Readex Pro',
              color: theme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.getFont('Readex Pro', color: theme.secondaryText, fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'حسناً',
                style: GoogleFonts.getFont('Readex Pro', fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    },
  );
}
