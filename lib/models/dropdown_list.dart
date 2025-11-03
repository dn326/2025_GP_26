class DropDownList {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? domain; // only for platforms

  const DropDownList({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.domain,
  });

  factory DropDownList.fromJson(Map<String, dynamic> json) => DropDownList(
    id: (json['id'] is int) ? json['id'] : int.parse(json['id'].toString()),
    nameAr: json['name_ar'] as String,
    nameEn: json['name_en'] as String,
    domain: json['domain'] as String?,
  );

  @override
  String toString() => nameAr;
}
