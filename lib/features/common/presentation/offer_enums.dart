import 'package:flutter/material.dart';

enum OfferInitiator {
  business,
  influencer;

  String toFirestore() => name;

  static OfferInitiator fromFirestore(String value) {
    return OfferInitiator.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfferInitiator.influencer,
    );
  }
}

enum OfferStatus {
  pending,
  accepted,
  rejected;

  String toFirestore() => name;

  static OfferStatus fromFirestore(String value) {
    return OfferStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfferStatus.pending,
    );
  }

  String toArabic() {
    switch (this) {
      case OfferStatus.pending:
        return 'قيد الانتظار';
      case OfferStatus.accepted:
        return 'مقبول';
      case OfferStatus.rejected:
        return 'مرفوض';
    }
  }

  Color getColor() {
    switch (this) {
      case OfferStatus.pending:
        return const Color(0xFFF59E0B);
      case OfferStatus.accepted:
        return const Color(0xFF16A34A);
      case OfferStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }
}
