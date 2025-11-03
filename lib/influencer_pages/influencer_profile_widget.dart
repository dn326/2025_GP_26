import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '../models/dropdown_list.dart';
import '../services/dropdown_list_loader.dart';
import '../setting/account_settings_page.dart';
import 'influencer_edit_experience_widget.dart';

class InfluncerProfileWidget extends StatefulWidget {
  const InfluncerProfileWidget({super.key});

  static String routeName = 'influncer_profile';
  static String routePath = '/influncerProfile';

  @override
  State<InfluncerProfileWidget> createState() => _InfluncerProfileWidgetState();
}

class _InfluncerProfileWidgetState extends State<InfluncerProfileWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late String userType = "business";
  String? _name;
  String? _contentType;
  String? _description;
  String? _email;
  String? _phone;
  late List<DropDownList> _socialPlatforms;
  List<Map<String, String>> _socials = [];
  List<Map<String, dynamic>> _experiences = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No logged-in user');

      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (usersSnap.docs.isEmpty) throw Exception('User record not found');
      final userDoc = usersSnap.docs.first;
      userType = (userDoc.data()['user_type'] ?? '').toString().toLowerCase();
      if (userType != 'influencer') {
        setState(() {
          _loading = false;
          _error = 'الحساب ليس من نوع مؤثر.';
        });
        return;
      }

      final profilesSnap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('profile_id', isEqualTo: uid)
          .limit(1)
          .get();

      String? name;
      String? description;
      String? contactEmail;
      String? phone;
      String? contentType;
      if (profilesSnap.docs.isNotEmpty) {
        final profileDoc = profilesSnap.docs.first;
        final prof = profileDoc.data();
        name = prof['name']?.toString();
        description = prof['description']?.toString();
        contactEmail = prof['contact_email']?.toString();
        phone = prof['phone_number']?.toString();

        final inflSnap = await profileDoc.reference
            .collection('influencer_profile')
            .limit(1)
            .get();
        if (inflSnap.docs.isNotEmpty) {
          contentType = inflSnap.docs.first.data()['content_type']?.toString();
        }
      }

      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapString = await FirebaseFirestore.instance
          .collection('social_account')
          .where('influencer_id', isEqualTo: uid)
          .get();
      final snapRef = await FirebaseFirestore.instance
          .collection('social_account')
          .where('influencer_id', isEqualTo: usersRef)
          .get();
      final allDocs = [...snapString.docs, ...snapRef.docs];
      final socials = allDocs
          .map((d) {
            final m = d.data();
            final platform = (m['platform'] ?? m['platform_name'] ?? '')
                .toString();
            final username = (m['username'] ?? '').toString();
            return {'platform': platform, 'username': username};
          })
          .where(
            (e) =>
                (e['platform'] ?? '').isNotEmpty ||
                (e['username'] ?? '').isNotEmpty,
          )
          .toList();

      final expSnap = await FirebaseFirestore.instance
          .collection('experiences')
          .where('influencer_id', isEqualTo: uid)
          .get();
      final exps = expSnap.docs.map((d) {
        final m = d.data();
        return {
          'id': d.id,
          'company_name': (m['company_name'] ?? '').toString(),
          'campaign_title': (m['campaign_title'] ?? '').toString(),
          'details': (m['details'] ?? '').toString(),
          'start_date': m['start_date'],
          'end_date': m['end_date'],
        };
      }).toList();

      DateTime? toDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return null;
      }

      exps.sort((a, b) {
        final da = toDate(a['start_date'])?.millisecondsSinceEpoch ?? -1;
        final db = toDate(b['start_date'])?.millisecondsSinceEpoch ?? -1;
        return db.compareTo(da);
      });

      setState(() {
        _name = name ?? '';
        _contentType = contentType ?? '';
        _description = description ?? '';
        _email = contactEmail ?? '';
        _phone = phone ?? '';
        _socials = socials;
        _experiences = exps;
        _loading = false;
        _error = null;
        _socialPlatforms = DropDownListLoader.instance.socialPlatforms;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'حصل خطأ أثناء جلب البيانات: $e';
      });
    }
  }

  String _fmtDate(dynamic tsOrDate) {
    if (tsOrDate == null) return '';
    DateTime dt;
    if (tsOrDate is Timestamp) {
      dt = tsOrDate.toDate();
    } else if (tsOrDate is DateTime) {
      dt = tsOrDate;
    } else {
      return tsOrDate.toString();
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  IconData _getSocialIcon(String platformNameEn) {
    final name = platformNameEn.toLowerCase();
    if (name == 'instagram') return FontAwesomeIcons.instagram;
    if (name == 'youtube') return FontAwesomeIcons.youtube;
    if (name == 'x' || name == 'twitter') return FontAwesomeIcons.xTwitter;
    if (name == 'facebook') return FontAwesomeIcons.facebook;
    if (name == 'tiktok') return FontAwesomeIcons.tiktok;
    if (name == 'linkedin') return FontAwesomeIcons.linkedin;
    if (name == 'snapchat') return FontAwesomeIcons.snapchat;
    if (name == 'telegram') return FontAwesomeIcons.telegram;
    if (name == 'whatsapp') return FontAwesomeIcons.whatsapp;
    if (name == 'pinterest') return FontAwesomeIcons.pinterest;
    if (name == 'reddit') return FontAwesomeIcons.reddit;
    if (name == 'twitch') return FontAwesomeIcons.twitch;
    if (name == 'threads') return FontAwesomeIcons.threads;
    if (name == 'bluesky') return FontAwesomeIcons.bluesky;
    return FontAwesomeIcons.link;
  }

  Color _getSocialColor(String platformNameEn) {
    final name = platformNameEn.toLowerCase();
    if (name == 'instagram') return Color(0xFFE4405F);
    if (name == 'youtube') return Color(0xFFFF0000);
    if (name == 'x' || name == 'twitter') return Color(0xFF000000);
    if (name == 'facebook') return Color(0xFF1877F2);
    if (name == 'tiktok') return Color(0xFF000000);
    if (name == 'linkedin') return Color(0xFF0A66C2);
    if (name == 'snapchat') return Color(0xFFFFFC00);
    if (name == 'telegram') return Color(0xFF26A5E4);
    if (name == 'whatsapp') return Color(0xFF25D366);
    if (name == 'pinterest') return Color(0xFFE60023);
    if (name == 'reddit') return Color(0xFFFF4500);
    if (name == 'twitch') return Color(0xFF9146FF);
    if (name == 'threads') return Color(0xFF000000);
    if (name == 'bluesky') return Color(0xFF1185FE);
    return Colors.grey;
  }

  Widget _buildSocialLinks1() {
    if (_socials.isEmpty) return const SizedBox.shrink();

    final t = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _socials.map((s) {
          final platId = s['platform']?.trim();
          final u = s['username']?.trim();

          if ((platId?.isEmpty ?? true) || (u?.isEmpty ?? true)) {
            return const SizedBox.shrink();
          }

          final platform = _socialPlatforms.firstWhere(
            (p) => p.id.toString() == platId,
            orElse: () =>
                DropDownList(id: 0, nameEn: '', nameAr: '', domain: ''),
          );

          final domain = platform.domain ?? '';
          final platformNameEn = platform.nameEn;
          final platformNameAr = platform.nameAr;
          final username = u ?? '';

          if (domain.isEmpty || username.isEmpty || platformNameEn.isEmpty) {
            return const SizedBox.shrink();
          }

          final url = 'https://$domain/$username';
          final icon = _getSocialIcon(platformNameEn);
          final color = _getSocialColor(platformNameEn);

          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  try {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('لا يمكن فتح الرابط')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: t.tertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(icon, color: color, size: 24),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              platformNameAr,
                              style: TextStyle(
                                color: t.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: GoogleFonts.inter().fontFamily,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: TextStyle(
                                color: t.subtextHints,
                                fontSize: 13,
                                fontFamily: GoogleFonts.inter().fontFamily,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoLines1() {
    final t = FlutterFlowTheme.of(context);
    final labelStyle = t.labelSmall.override(
      fontFamily: GoogleFonts.inter().fontFamily,
      color: t.primaryText,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    final valueStyle = t.labelSmall.override(
      fontFamily: GoogleFonts.inter().fontFamily,
      color: t.subtextHints,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if ((_contentType ?? '').isNotEmpty) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: t.tertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: t.subtextHints.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'نوع المحتوى',
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _contentType!,
                    style: valueStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
        if ((_description ?? '').isNotEmpty) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: t.tertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: t.subtextHints.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'نبذة عني',
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _description!,
                    style: valueStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
        if ((_email ?? '').isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 16, color: t.subtextHints),
                SizedBox(width: 6),
                Text(_email!, style: labelStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
        if ((_phone ?? '').isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 16, color: t.subtextHints),
                SizedBox(width: 6),
                Text(_phone!, style: labelStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
        _buildSocialLinks1(),
      ],
    );
  }

  Widget _buildSocialLinks() {
    if (_socials.isEmpty) return const SizedBox.shrink();

    final t = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _socials.map((s) {
          final platId = s['platform']?.trim();
          final u = s['username']?.trim();

          if ((platId?.isEmpty ?? true) || (u?.isEmpty ?? true)) {
            return const SizedBox.shrink();
          }

          final platform = _socialPlatforms.firstWhere(
                (p) => p.id.toString() == platId,
            orElse: () =>
                DropDownList(id: 0, nameEn: '', nameAr: '', domain: ''),
          );

          final domain = platform.domain ?? '';
          final platformNameEn = platform.nameEn;
          final username = u ?? '';

          if (domain.isEmpty || username.isEmpty || platformNameEn.isEmpty) {
            return const SizedBox.shrink();
          }

          final url = 'https://$domain/$username';
          final icon = _getSocialIcon(platformNameEn);
          final color = _getSocialColor(platformNameEn);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('لا يمكن فتح الرابط')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: t.tertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(icon, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '@$username',
                      style: TextStyle(
                        color: t.primaryText,
                        fontSize: 13,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoLines(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle = t.bodyMedium.copyWith(color: t.primaryText, fontWeight: FontWeight.w600);
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    final socialsText = _socials.isEmpty
        ? ''
        : _socials
        .map((s) {
      final p = s['platform']?.trim();
      final u = s['username']?.trim();
      if ((p?.isEmpty ?? true) && (u?.isEmpty ?? true)) return null;
      return '${p ?? ''}: ${u ?? ''}'.trim();
    })
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join('\n');

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if ((_contentType ?? '').isNotEmpty) ...[
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text('نوع المحتوى', style: labelStyle, textAlign: TextAlign.end),
            ),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text(_contentType!, style: valueStyle, textAlign: TextAlign.end),
            ),
          ],
          if ((_description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text('نبذة عني', style: labelStyle, textAlign: TextAlign.end),
            ),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text(_description!, style: valueStyle, textAlign: TextAlign.end),
            ),
          ],
          if (_socials.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text('المنصات الاجتماعية', style: labelStyle, textAlign: TextAlign.end),
            ),
            _buildSocialLinks(),
          ],
          /*
          if (socialsText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text('المنصات الاجتماعية', style: labelStyle, textAlign: TextAlign.end),
            ),
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text(socialsText, style: valueStyle, textAlign: TextAlign.end),
            ),
          ],
          */
          const SizedBox(height: 8),
          Align(
            alignment: const AlignmentDirectional(1, 0),
            child: Text(':للتواصل', style: labelStyle, textAlign: TextAlign.end),
          ),
          if ((_email ?? '').isNotEmpty)
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text(_email!, style: valueStyle, textAlign: TextAlign.end),
            ),
          if ((_phone ?? '').isNotEmpty)
            Align(
              alignment: const AlignmentDirectional(1, 0),
              child: Text(_phone!, style: valueStyle, textAlign: TextAlign.end),
            ),
        ],
      ),
    );
  }

  Widget _avatarWidget({double size = 100}) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.tertiary,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds
              .withAlpha(50),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: _buildUniversalImage(theme, size)),
    );
  }

  Widget _buildUniversalImage(FlutterFlowTheme theme, double size) {
    return FutureBuilder<Widget>(
      future: _loadUniversalAvatar(theme, size),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingIndicator(theme);
        }
        return snapshot.data ?? _placeholderAvatar(theme, size);
      },
    );
  }

  Future<Widget> _loadUniversalAvatar(
    FlutterFlowTheme theme,
    double size,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return _placeholderAvatar(theme, size);

      // Try to get image from Firestore first
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('profile_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        final profileData = profileSnapshot.docs.first.data();
        final imageUrl = profileData['profile_image']?.toString();

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Use a simple network image with error handling
          return Image.network(
            "$imageUrl?alt=media",
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _placeholderAvatar(theme, size);
            },
          );
        }
      }

      return _placeholderAvatar(theme, size);
    } catch (e) {
      debugPrint('Universal avatar load failed: $e');
      return _placeholderAvatar(theme, size);
    }
  }

  Widget _loadingIndicator(FlutterFlowTheme theme) {
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
          ),
        ),
      ),
    );
  }

  Widget _placeholderAvatar(FlutterFlowTheme theme, double size) {
    return Image.asset(
      'assets/images/person_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Widget _experienceTile(Map<String, dynamic> e) {
    final t = FlutterFlowTheme.of(context);

    final labelStyle = t.bodyMedium.copyWith(
      color: t.primaryText,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = t.bodyMedium.copyWith(color: t.secondaryText);

    final company = e['company_name'] as String? ?? '';
    final title = e['campaign_title'] as String? ?? '';
    final details = e['details'] as String? ?? '';
    final s = _fmtDate(e['start_date']);
    final en = _fmtDate(e['end_date']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.tertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 8,
                      buttonSize: 40,
                      icon: Icon(
                        Icons.edit_sharp,
                        color: t
                            .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                        size: 20,
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InfluncerEditExperienceWidget(
                              experienceId: e['id'] as String,
                            ),
                          ),
                        );
                        await _loadAll();
                      },
                    ),
                    const SizedBox(width: 8),
                    FlutterFlowIconButton(
                      borderRadius: 8,
                      buttonSize: 40,
                      icon: Icon(
                        Icons.minimize_outlined,
                        color: t
                            .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                        size: 20,
                      ),
                      onPressed: () async {
                        final expId = e['id'] as String?;
                        if (expId == null || expId.isEmpty) return;

                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد الحذف'),
                            content: const Text(
                              'هل أنت متأكد من حذف هذه الخبرة؟ لا يمكن التراجع عن هذه العملية.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('experiences')
                                .doc(expId)
                                .delete();
                            if (!mounted) return;
                            await _loadAll();
                          } catch (err) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذّر الحذف: $err')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الشركة / المنظمة',
                    style: labelStyle,
                    textAlign: TextAlign.end,
                  ),
                  Text(company, style: valueStyle, textAlign: TextAlign.end),
                  const SizedBox(height: 8),
                  Text(
                    'عنوان الحملة',
                    style: labelStyle,
                    textAlign: TextAlign.end,
                  ),
                  Text(title, style: valueStyle, textAlign: TextAlign.end),
                  const SizedBox(height: 8),
                  if (s.isNotEmpty || en.isNotEmpty) ...[
                    Text(
                      'الفترة الزمنية',
                      style: labelStyle,
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      'من $s إلى $en',
                      style: valueStyle,
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'تفاصيل الخبرة',
                    style: labelStyle,
                    textAlign: TextAlign.end,
                  ),
                  Text(details, style: valueStyle, textAlign: TextAlign.end),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.backgroundElan,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: AppBar(
            backgroundColor: theme.containers,
            automaticallyImplyLeading: false,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: AlignmentDirectional(-1, 1),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AccountSettingsPage.routeName,
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16),
                      child: FaIcon(
                        FontAwesomeIcons.bahai,
                        color: theme
                            .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: true,
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(8, 16, 8, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.containers,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 3,
                                color: Color(0x33000000),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  0,
                                  16,
                                  0,
                                  8,
                                ),
                                child: _avatarWidget(),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  _name ?? '',
                                  textAlign: TextAlign.center,
                                  style: theme.headlineSmall.override(
                                    fontFamily:
                                        GoogleFonts.interTight().fontFamily,
                                    fontSize: 22,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                              _buildInfoLines(context),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: FFButtonWidget(
                                  onPressed: () => context.pushNamed(
                                    InfluncerEditProfileWidget.routeName,
                                  ),
                                  text: 'تعديل الملف الشخصي',
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 44,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      8,
                                      0,
                                      8,
                                      0,
                                    ),
                                    color: theme
                                        .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                    textStyle: theme.titleSmall.override(
                                      fontFamily:
                                          GoogleFonts.interTight().fontFamily,
                                      color: theme.containers,
                                      letterSpacing: 0.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    hoverColor: theme.subtextHints,
                                    hoverTextColor: theme.backgroundElan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.containers,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 3,
                                color: Color(0x33000000),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FlutterFlowIconButton(
                                      borderRadius: 8,
                                      buttonSize: 50,
                                      icon: Icon(
                                        Icons.add_circle,
                                        color: theme
                                            .iconsOnLightBackgroundsMainButtonsOnLightBackgrounds,
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const InfluncerAddExperienceWidget(),
                                          ),
                                        );
                                        await _loadAll();
                                      },
                                    ),
                                    Text(
                                      'الخبرات',
                                      textAlign: TextAlign.end,
                                      style: theme.headlineLarge.override(
                                        fontFamily:
                                            GoogleFonts.interTight().fontFamily,
                                        fontSize: 22,
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_experiences.isEmpty)
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: theme.tertiary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'اضف خبراتك ليتعرف الآخرون على تميزك',
                                        style: theme.labelSmall.override(
                                          fontFamily:
                                              GoogleFonts.inter().fontFamily,
                                          color: theme.subtextHints,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    children: _experiences
                                        .map(
                                          (e) => Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                  0,
                                                  0,
                                                  0,
                                                  12,
                                                ),
                                            child: _experienceTile(e),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
