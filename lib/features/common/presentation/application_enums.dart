import 'package:flutter/material.dart';

enum ApplicationInitiator {
  business,
  influencer;

  String toFirestore() => name;

  static ApplicationInitiator fromFirestore(String value) {
    return ApplicationInitiator.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ApplicationInitiator.influencer,
    );
  }
}

enum ApplicationStatus {
  offerSent,
  pending,
  accepted,
  rejected;

  String toFirestore() {
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  static ApplicationStatus fromFirestore(String value) {
    final camelCase = value.replaceAllMapped(
      RegExp(r'_([a-z])'),
          (match) => match.group(1)!.toUpperCase(),
    );
    return ApplicationStatus.values.firstWhere(
          (e) => e.name == camelCase,
      orElse: () => ApplicationStatus.pending,
    );
  }

  String toArabic() {
    switch (this) {
      case ApplicationStatus.offerSent:
        return 'تم استلام عرض';
      case ApplicationStatus.pending:
        return 'قيد الانتظار';
      case ApplicationStatus.accepted:
        return 'مقبول';
      case ApplicationStatus.rejected:
        return 'مرفوض';
    }
  }

  Color getColor() {
    switch (this) {
      case ApplicationStatus.offerSent:
        return const Color(0xFF3B82F6);
      case ApplicationStatus.pending:
        return const Color(0xFFF59E0B);
      case ApplicationStatus.accepted:
        return const Color(0xFF16A34A);
      case ApplicationStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }
}