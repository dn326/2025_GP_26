// lib/features/common/models/archive_sort_order.dart

enum ArchiveSortOrder {
  dateDesc,
  dateAsc,
  priceDesc,
  priceAsc,
}

extension ArchiveSortOrderX on ArchiveSortOrder {
  bool get isDate {
    return this == ArchiveSortOrder.dateDesc ||
        this == ArchiveSortOrder.dateAsc;
  }

  bool get isPrice {
    return this == ArchiveSortOrder.priceDesc ||
        this == ArchiveSortOrder.priceAsc;
  }

  bool get descending {
    return this == ArchiveSortOrder.dateDesc ||
        this == ArchiveSortOrder.priceDesc;
  }

  String get labelAr {
    switch (this) {
      case ArchiveSortOrder.dateDesc:
        return 'الأحدث أولاً';
      case ArchiveSortOrder.dateAsc:
        return 'الأقدم أولاً';
      case ArchiveSortOrder.priceDesc:
        return 'السعر: الأعلى';
      case ArchiveSortOrder.priceAsc:
        return 'السعر: الأقل';
    }
  }
}