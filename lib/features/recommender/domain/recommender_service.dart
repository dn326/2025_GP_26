// lib/core/services/recommender_service.dart
//
// Implements the personalised recommendation formulas.
//
// Business → Influencer (max score = 100):
//   Content Match (30) + Platform Match (25) + Favourite (10)
//   + Offer History (15) + Application Acceptance (10)
//   + Liked By Other Business (10)
//
// Influencer → Campaign (max score = 100):
//   Content Match (25) + Platform Match (20) + Most Applied (15)
//   + Favorite Business (10) + Application History (10)
//   + Campaign Like (10) + Favourite Campaign Similarity (10)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/firebase_service.dart';

// ─── Input models ─────────────────────────────────────────────────────────────

/// Carries the already-loaded influencer data from FeqProfilesListWidget
/// so the recommender does not re-query Firestore per influencer.
class InfluencerInput {
  /// Firestore profile_id / user UID
  final String id;

  /// Platform IDs as strings (e.g. "1", "2") – from social_account.platform
  final List<String> platformIds;

  /// Arabic content type name (e.g. "كوميديا") – from item.content2
  final String? contentTypeName;

  const InfluencerInput({
    required this.id,
    required this.platformIds,
    this.contentTypeName,
  });
}

/// Carries the already-loaded campaign data from FeqCampaignListWidget.
class CampaignInput {
  final String id;
  final String businessId;
  final int contentTypeId;
  final List<String> platformNames; // Arabic names, e.g. ["إنستغرام"]

  const CampaignInput({
    required this.id,
    required this.businessId,
    required this.contentTypeId,
    required this.platformNames,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class RecommenderService {
  final _fs = firebaseFirestore;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Maps an Arabic platform name to its numeric ID via the dropdown loader.
  int _platformNameToId(String nameAr) {
    try {
      return FeqDropDownListLoader.instance.socialPlatforms
          .firstWhere((p) => p.nameAr == nameAr)
          .id;
    } catch (_) {
      return 0;
    }
  }

  /// Maps an Arabic content type name to its numeric ID.
  int? _contentTypeNameToId(String? nameAr) {
    if (nameAr == null || nameAr.isEmpty) return null;
    try {
      return FeqDropDownListLoader.instance.influencerContentTypes
          .firstWhere((ct) => ct.nameAr == nameAr)
          .id;
    } catch (_) {
      return null;
    }
  }

  /// Batches a list into chunks of [size] for Firestore whereIn (max 30).
  Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (int i = 0; i < list.length; i += size) {
      yield list.skip(i).take(size).toList();
    }
  }

  // ─── Business → Influencer ────────────────────────────────────────────────

  /// Returns { influencerId → score (0–100) } for the current business user.
  ///
  /// [favoriteInfluencerIds] is passed in from the widget (already loaded).
  Future<Map<String, double>> scoreInfluencers({
    required String businessId,
    required List<InfluencerInput> influencers,
    required Set<String> favoriteInfluencerIds,
  }) async {
    if (influencers.isEmpty) return {};

    try {
      // ── 1. Business campaigns ────────────────────────────────────────────
      final camSnap = await _fs
          .collection('campaigns')
          .where('business_id', isEqualTo: businessId)
          .where('visible', isEqualTo: true)
          .get();

      final campaigns = camSnap.docs.map((d) => d.data()).toList();
      final int totalCampaigns = campaigns.length;

      final List<int> camContentTypeIds = campaigns
          .map((c) => (c['influencer_content_type_id'] as int?) ?? 0)
          .toList();

      // Campaign platform IDs (Arabic name → int ID)
      final List<Set<int>> camPlatformIdSets = campaigns.map((c) {
        final names = (c['platform_names'] as List?) ?? [];
        return names
            .map((n) => _platformNameToId(n.toString()))
            .where((id) => id != 0)
            .toSet();
      }).toList();

      // Total platform slots (no dedup) for denominator
      int totalPlatformSlots = 0;
      for (final s in camPlatformIdSets) {
        totalPlatformSlots += s.length;
      }

      // ── 2. Offer history (all offers sent by this business) ──────────────
      final offersSnap = await _fs
          .collection('offers')
          .where('business_id', isEqualTo: businessId)
          .get();

      final Map<String, List<DateTime>> offerDatesByInfluencer = {};
      for (final doc in offersSnap.docs) {
        final data = doc.data();
        final infId = (data['influencer_id'] ?? '').toString();
        final ts = data['created_at'];
        final dt = ts is Timestamp ? ts.toDate() : null;
        if (infId.isNotEmpty) {
          offerDatesByInfluencer.putIfAbsent(infId, () => []);
          if (dt != null) offerDatesByInfluencer[infId]!.add(dt);
        }
      }

      // ── 3. Application history (all apps received by this business) ──────
      final appsSnap = await _fs
          .collection('applications')
          .where('business_id', isEqualTo: businessId)
          .get();

      final Map<String, int> appTotal = {};
      final Map<String, int> appAccepted = {};
      for (final doc in appsSnap.docs) {
        final data = doc.data();
        final infId = (data['influencer_id'] ?? '').toString();
        if (infId.isNotEmpty) {
          appTotal[infId] = (appTotal[infId] ?? 0) + 1;
          if (data['status'] == 'accepted') {
            appAccepted[infId] = (appAccepted[infId] ?? 0) + 1;
          }
        }
      }

      // ── 4. Same-industry business likes ─────────────────────────────────
      // (Liked By Other Business Score)
      final Map<String, int> sameIndustryLikesPerInfluencer = {};
      int totalSameIndustryLikes = 0;

      final bizProfileSnap = await _fs
          .collection('profiles')
          .where('profile_id', isEqualTo: businessId)
          .limit(1)
          .get();

      if (bizProfileSnap.docs.isNotEmpty) {
        final industryId =
        bizProfileSnap.docs.first.data()['business_industry_id'] as int?;

        if (industryId != null) {
          final sameIndSnap = await _fs
              .collection('profiles')
              .where('business_industry_id', isEqualTo: industryId)
              .get();

          final sameIndBizIds = sameIndSnap.docs
              .map((d) => (d.data()['profile_id'] ?? '').toString())
              .where((id) => id.isNotEmpty && id != businessId)
              .toList();

          for (final chunk in _chunks(sameIndBizIds, 30)) {
            if (chunk.isEmpty) continue;
            // favourites collection stores both camelCase and snake_case;
            // the composite index uses businessId (camelCase).
            final likeSnap = await _fs
                .collection('favourites')
                .where('type', isEqualTo: 'influencer')
                .where('businessId', whereIn: chunk)
                .get();
            for (final doc in likeSnap.docs) {
              final infId =
              (doc.data()['influencerId'] ?? doc.data()['influencer_id'] ?? '')
                  .toString();
              if (infId.isNotEmpty) {
                sameIndustryLikesPerInfluencer[infId] =
                    (sameIndustryLikesPerInfluencer[infId] ?? 0) + 1;
                totalSameIndustryLikes++;
              }
            }
          }
        }
      }

      // ── 5. Compute scores ────────────────────────────────────────────────
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final Map<String, double> scores = {};

      for (final inf in influencers) {
        double score = 0;

        final int? infContentTypeId = _contentTypeNameToId(inf.contentTypeName);
        final Set<int> infPlatIds = inf.platformIds
            .map((s) => int.tryParse(s) ?? 0)
            .where((id) => id != 0)
            .toSet();

        // 1. Content Match Score (30)
        if (totalCampaigns > 0 && infContentTypeId != null) {
          final matches =
              camContentTypeIds.where((id) => id == infContentTypeId).length;
          score += (matches / totalCampaigns) * 30;
        }

        // 2. Platform Match Score (25)
        // shared = for each campaign platform list, count matching platforms (no dedup)
        if (totalPlatformSlots > 0 && infPlatIds.isNotEmpty) {
          int sharedCount = 0;
          for (final camPlatIds in camPlatformIdSets) {
            sharedCount += camPlatIds.intersection(infPlatIds).length;
          }
          score += (sharedCount / totalPlatformSlots) * 25;
        }

        // 3. Favourite Score (10)
        if (favoriteInfluencerIds.contains(inf.id)) score += 10;

        // 4. Offer History Score (15): recent(6) + repeat(max 9) → max 15 ✓
        final offerDates = offerDatesByInfluencer[inf.id] ?? [];
        final offerCount = offerDates.length;
        final hasRecentOffer = offerDates.any((dt) => dt.isAfter(sixMonthsAgo));
        double offerScore = hasRecentOffer ? 6 : 0;
        if (offerCount >= 3) {
          offerScore += 9;
        } else if (offerCount == 2) {
          offerScore += 6;
        } else if (offerCount == 1) {
          offerScore += 3;
        }
        score += offerScore; // max 15

        // 5. Application Acceptance Score (10)
        final total = appTotal[inf.id] ?? 0;
        if (total > 0) {
          score += ((appAccepted[inf.id] ?? 0) / total) * 10;
        }

        // 6. Liked By Other Business Score (10)
        if (totalSameIndustryLikes > 0) {
          final likes = sameIndustryLikesPerInfluencer[inf.id] ?? 0;
          score += (likes / totalSameIndustryLikes) * 10;
        }

        scores[inf.id] = score.clamp(0, 100);
      }

      return scores;
    } catch (e, st) {
      debugPrint('RecommenderService.scoreInfluencers error: $e\n$st');
      return {};
    }
  }

  // ─── Influencer → Campaign ────────────────────────────────────────────────

  /// Returns { campaignId → score (0–100) } for the current influencer user.
  ///
  /// [favoriteCampaignIds] is passed in from the widget (already loaded).
  Future<Map<String, double>> scoreCampaigns({
    required String influencerId,
    required List<CampaignInput> campaigns,
    required Set<String> favoriteCampaignIds,
  }) async {
    if (campaigns.isEmpty) return {};

    try {
      // ── 1. Influencer profile: content type + social platforms ────────────
      final profSnap = await _fs
          .collection('profiles')
          .where('profile_id', isEqualTo: influencerId)
          .limit(1)
          .get();

      if (profSnap.docs.isEmpty) return {};
      final profDoc = profSnap.docs.first;

      int infContentTypeId = 0;
      final subSnap = await profDoc.reference
          .collection('influencer_profile')
          .limit(1)
          .get();
      if (subSnap.docs.isNotEmpty) {
        infContentTypeId =
            subSnap.docs.first.data()['content_type_id'] as int? ?? 0;
      }

      final socialSnap = await _fs
          .collection('social_account')
          .where('influencer_id', isEqualTo: influencerId)
          .get();
      final Set<int> infPlatIds = socialSnap.docs
          .map((d) => int.tryParse((d.data()['platform'] ?? '').toString()) ?? 0)
          .where((id) => id != 0)
          .toSet();

      // ── 2. Application history (all apps by this influencer) ─────────────
      final appsSnap = await _fs
          .collection('applications')
          .where('influencer_id', isEqualTo: influencerId)
          .get();

      final Map<String, int> appCountByBusiness = {};
      final Map<String, bool> appRecentByBusiness = {};
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

      for (final doc in appsSnap.docs) {
        final data = doc.data();
        final bizId = (data['business_id'] ?? '').toString();
        if (bizId.isNotEmpty) {
          appCountByBusiness[bizId] = (appCountByBusiness[bizId] ?? 0) + 1;
          final ts = data['applied_at'];
          final dt = ts is Timestamp ? ts.toDate() : null;
          if (dt != null && dt.isAfter(sixMonthsAgo)) {
            appRecentByBusiness[bizId] = true;
          }
        }
      }

      // ── 3. Campaign reactions (liked campaigns) ───────────────────────────
      final reactSnap = await _fs
          .collection('campaign_reactions')
          .where('influencer_id', isEqualTo: influencerId)
          .where('reaction', isEqualTo: 'like')
          .get();
      final Set<String> likedCampaignIds = reactSnap.docs
          .map((d) => (d.data()['campaign_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      // ── 4. Infer liked business IDs from bookmarked campaigns ────────────
      // (No separate "influencer likes business" collection exists.)
      final Set<String> likedBusinessIds = {};
      if (favoriteCampaignIds.isNotEmpty) {
        for (final chunk in _chunks(favoriteCampaignIds.toList(), 30)) {
          final favSnap = await _fs
              .collection('favourites')
              .where('type', isEqualTo: 'campaign')
              .where('influencer_id', isEqualTo: influencerId)
              .where('campaign_id', whereIn: chunk)
              .get();
          for (final doc in favSnap.docs) {
            final bizId =
            (doc.data()['businessId'] ?? doc.data()['business_id'] ?? '')
                .toString();
            if (bizId.isNotEmpty) likedBusinessIds.add(bizId);
          }
        }
      }

      // ── 5. Most Applied Score: application counts per campaign ────────────
      // Only meaningful for campaigns whose content type matches the influencer.
      final matchingCampaignIds = campaigns
          .where((c) => infContentTypeId != 0 && c.contentTypeId == infContentTypeId)
          .map((c) => c.id)
          .toList();

      final Map<String, int> uniqueApplicants = {}; // campaignId → count
      int totalUniqueApplicantsAllMatching = 0;

      if (matchingCampaignIds.isNotEmpty) {
        for (final chunk in _chunks(matchingCampaignIds, 30)) {
          final batchSnap = await _fs
              .collection('applications')
              .where('campaign_id', whereIn: chunk)
              .get();

          final Map<String, Set<String>> appsByCam = {};
          for (final doc in batchSnap.docs) {
            final data = doc.data();
            final camId = (data['campaign_id'] ?? '').toString();
            final infId2 = (data['influencer_id'] ?? '').toString();
            if (camId.isNotEmpty && infId2.isNotEmpty) {
              appsByCam.putIfAbsent(camId, () => {}).add(infId2);
            }
          }
          for (final entry in appsByCam.entries) {
            uniqueApplicants[entry.key] = entry.value.length;
            totalUniqueApplicantsAllMatching += entry.value.length;
          }
        }
      }

      // ── 6. Liked/saved campaign metadata (for similarity score) ───────────
      final Set<String> allLikedCamIds = {...favoriteCampaignIds, ...likedCampaignIds};
      final List<Map<String, dynamic>> likedCamData = [];

      if (allLikedCamIds.isNotEmpty) {
        for (final chunk in _chunks(allLikedCamIds.toList(), 30)) {
          final camSnap = await _fs
              .collection('campaigns')
              .where('campaign_id', whereIn: chunk)
              .get();
          likedCamData.addAll(camSnap.docs.map((d) => d.data()));
        }
      }

      final int likedCamCount = likedCamData.length;

      // ── 7. Compute scores ────────────────────────────────────────────────
      final Map<String, double> scores = {};

      for (final cam in campaigns) {
        double score = 0;

        // Convert campaign platform names → IDs
        final Set<int> camPlatIds = cam.platformNames
            .map((n) => _platformNameToId(n))
            .where((id) => id != 0)
            .toSet();

        // ── Content Match Score (25) ────────────────────────────────────────
        final bool contentMatches =
            infContentTypeId != 0 && cam.contentTypeId == infContentTypeId;
        if (contentMatches) score += 25;

        // ── Platform Match Score (20) ───────────────────────────────────────
        if (infPlatIds.isNotEmpty && camPlatIds.isNotEmpty) {
          final shared = camPlatIds.intersection(infPlatIds).length;
          score += (shared / camPlatIds.length) * 20;
        }

        // ── Most Applied Score (15) — only when content matches ─────────────
        if (contentMatches && totalUniqueApplicantsAllMatching > 0) {
          final applicants = uniqueApplicants[cam.id] ?? 0;
          score += (applicants / totalUniqueApplicantsAllMatching) * 15;
        }

        // ── Favorite Business Score (10) ────────────────────────────────────
        if (likedBusinessIds.contains(cam.businessId)) score += 10;

        // ── Application History Score (10) ──────────────────────────────────
        // raw formula: recent(6) + repeat(max 9) → capped at 10 per label
        final appCount = appCountByBusiness[cam.businessId] ?? 0;
        final hasRecentApp = appRecentByBusiness[cam.businessId] ?? false;
        double historyRaw = hasRecentApp ? 6.0 : 0.0;
        if (appCount >= 3) {
          historyRaw += 4;
        } else if (appCount == 2) {
          historyRaw += 2;
        } else if (appCount == 1) {
          historyRaw += 1;
        }
        score += historyRaw.clamp(0, 10); // cap at 10 as specified

        // ── Campaign Like Score (10) ────────────────────────────────────────
        if (likedCampaignIds.contains(cam.id)) score += 10;

        // ── Favourite Campaign Similarity Score (10) ────────────────────────
        if (likedCamCount > 0 && camPlatIds.isNotEmpty) {
          // 1) Content similarity
          final likedSameContent = likedCamData.where((d) =>
          (d['influencer_content_type_id'] as int? ?? 0) == cam.contentTypeId
          ).length;

          final double contentPortion = likedSameContent / likedCamCount;

          // 2) Platform similarity
          int totalSharedPlatforms = 0;
          for (final lcd in likedCamData) {
            final names = (lcd['platform_names'] as List?) ?? [];
            final likedPlatIds = names
                .map((n) => _platformNameToId(n.toString()))
                .where((id) => id != 0)
                .toSet();

            totalSharedPlatforms += likedPlatIds.intersection(camPlatIds).length;
          }

          final int denominator = likedCamCount * camPlatIds.length;
          final double platformPortion =
          denominator > 0 ? totalSharedPlatforms / denominator : 0.0;

          score += (contentPortion + platformPortion) * 10;
        }

        scores[cam.id] = score.clamp(0, 100);
      }

      return scores;
    } catch (e, st) {
      debugPrint('RecommenderService.scoreCampaigns error: $e\n$st');
      return {};
    }
  }
}