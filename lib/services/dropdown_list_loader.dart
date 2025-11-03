import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dropdown_list.dart';

class DropDownListLoader {
  DropDownListLoader._();

  static final DropDownListLoader instance = DropDownListLoader._();

  List<DropDownList> _businessIndustries = [];
  List<DropDownList> _saudiCompanies = [];
  List<DropDownList> _influencerContentTypes = [];
  List<DropDownList> _socialPlatforms = [];

  List<DropDownList> get businessIndustries => _businessIndustries;

  List<DropDownList> get saudiCompanies => _saudiCompanies;

  List<DropDownList> get influencerContentTypes => _influencerContentTypes;

  List<DropDownList> get socialPlatforms => _socialPlatforms;

  Future<void> init() async {
    final businessIndustryList = await rootBundle.loadString(
      'assets/data/business_industry.json',
    );
    final saudiCompanyList = await rootBundle.loadString(
      'assets/data/saudi_companies_top50.json',
    );
    final ct = await rootBundle.loadString(
      'assets/data/influencer_content_type.json',
    );
    final p = await rootBundle.loadString('assets/data/social_platforms.json');

    final List<dynamic> businessIndustryListJson = json.decode(
      businessIndustryList,
    );
    final List<dynamic> saudiCompanyListJson = json.decode(saudiCompanyList);
    final List<dynamic> ctJson = json.decode(ct);
    final List<dynamic> pJson = json.decode(p);

    _businessIndustries = businessIndustryListJson
        .map(
          (e) => DropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
          ),
        )
        .toList();
    _saudiCompanies = saudiCompanyListJson
        .map(
          (e) => DropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
          ),
        )
        .toList();
    _influencerContentTypes = ctJson
        .map(
          (e) => DropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
          ),
        )
        .toList();

    _socialPlatforms = pJson
        .map(
          (e) => DropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
            domain: e['domain'] as String,
          ),
        )
        .toList();
  }
}
