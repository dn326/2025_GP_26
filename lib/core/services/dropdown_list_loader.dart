import 'dart:convert';

import 'package:flutter/services.dart';

import '../components/feq_components.dart';

class FeqDropDownListLoader {
  FeqDropDownListLoader._();

  static final FeqDropDownListLoader instance = FeqDropDownListLoader._();

  List<FeqDropDownList> _businessIndustries = [];
  List<FeqDropDownList> _saudiCompanies = [];
  List<FeqDropDownList> _influencerContentTypes = [];
  List<FeqDropDownList> _socialPlatforms = [];

  List<FeqDropDownList> get businessIndustries => _businessIndustries;

  List<FeqDropDownList> get saudiCompanies => _saudiCompanies;

  List<FeqDropDownList> get influencerContentTypes => _influencerContentTypes;

  List<FeqDropDownList> get socialPlatforms => _socialPlatforms;

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
          (e) => FeqDropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
          ),
        )
        .toList();
    _saudiCompanies = saudiCompanyListJson
        .map(
          (e) => FeqDropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
          ),
        )
        .toList();
    _influencerContentTypes = ctJson
        .map(
          (e) => FeqDropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
          ),
        )
        .toList();

    _socialPlatforms = pJson
        .map(
          (e) => FeqDropDownList(
            id: (e['id'] is int) ? e['id'] : int.parse(e['id'].toString()),
            nameAr: e['name_ar'] as String,
            nameEn: e['name_en'] as String,
            domain: e['domain'] as String,
          ),
        )
        .toList();
  }
}
