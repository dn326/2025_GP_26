// lib/features/common/presentation/applications_offers_page.dart
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/dropdown_list_loader.dart';
import '../../../core/services/user_session.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import 'applications_tab_content.dart';
import 'archive_tab_content.dart';
import 'offers_tab_content.dart';

class ApplicationsOffersPage extends StatefulWidget {
  const ApplicationsOffersPage({super.key});

  static const String routeName = 'applications-offers';
  static const String routePath = '/$routeName';

  @override
  State<ApplicationsOffersPage> createState() => _ApplicationsOffersPageState();
}

class _ApplicationsOffersPageState extends State<ApplicationsOffersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userType = '';
  bool _isLoading = true;

  // Filter states for business - tab 1
  List<String> _businessTab1SelectedCampaigns = [];
  List<int> _businessTab1SelectedContentTypes = [];
  List<int> _businessTab1SelectedPlatforms = [];

  // Filter states for business - tab 2
  List<String> _businessTab2SelectedStatuses = [];
  List<String> _businessTab2SelectedCampaigns = [];

  // Filter states for influencer - tab 1
  List<String> _influencerTab1SelectedStatuses = [];

  // Filter states for influencer - tab 2
  List<String> _influencerTab2SelectedStatuses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final userTypeValue = (await UserSession.getUserType()) ?? '';
    setState(() {
      _userType = userTypeValue;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tab titles and icons based on user type
  List<Tab> get _tabs {
    if (_userType == 'business') {
      return const [
        Tab(icon: Icon(Icons.inbox), text: 'الطلبات الواردة'),
        Tab(icon: Icon(Icons.send), text: 'العروض المرسلة'),
        Tab(icon: Icon(Icons.handshake), text: 'سجل الاتفاقيات'),
      ];
    } else {
      return const [
        Tab(icon: Icon(Icons.send), text: 'الطلبات المرسلة'),
        Tab(icon: Icon(Icons.inbox), text: 'العروض الواردة'),
        Tab(icon: Icon(Icons.archive), text: 'الأرشيف'),
      ];
    }
  }

  void _showFilterSheet() {
    final currentTab = _tabController.index;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (_userType == 'business') {
          if (currentTab == 0) {
            return _buildBusinessTab1Filter();
          } else if (currentTab == 1) {
            return _buildBusinessTab2Filter();
          } else {
            return _buildNoFilter();
          }
        } else {
          if (currentTab == 0) {
            return _buildInfluencerTab1Filter();
          } else if (currentTab == 1) {
            return _buildInfluencerTab2Filter();
          } else {
            return _buildNoFilter();
          }
        }
      },
    );
  }

  // Business Tab 1 Filter: Campaigns, Content Types, Platforms
  Widget _buildBusinessTab1Filter() {
    final t = FlutterFlowTheme.of(context);
    final contentTypes = FeqDropDownListLoader.instance.influencerContentTypes;
    final platforms = FeqDropDownListLoader.instance.socialPlatforms;
    final tempCampaigns = List<String>.from(_businessTab1SelectedCampaigns);
    final tempContentTypes = List<int>.from(_businessTab1SelectedContentTypes);
    final tempPlatforms = List<int>.from(_businessTab1SelectedPlatforms);

    // Mock campaigns - in real app, load from Firestore
    final campaigns = [
      {'id': '1', 'title': 'حملة تسويقية 1'},
      {'id': '2', 'title': 'حملة تسويقية 2'},
    ];

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        tempCampaigns.clear();
                        tempContentTypes.clear();
                        tempPlatforms.clear();
                        setModalState(() {});
                      },
                      child: Text('مسح الكل', style: TextStyle(color: t.error)),
                    ),
                    Text('تصفية الطلبات الواردة', style: t.headlineSmall),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter by campaign
                Text('حسب الحملة', style: t.bodyLarge),
                const SizedBox(height: 10),
                ...campaigns.map((campaign) {
                  final isSelected = tempCampaigns.contains(campaign['id']);
                  return CheckboxListTile(
                    title: Text(campaign['title']!),
                    value: isSelected,
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          tempCampaigns.add(campaign['id']!);
                        } else {
                          tempCampaigns.remove(campaign['id']);
                        }
                      });
                    },
                  );
                }),

                const Divider(height: 30),

                // Filter by content type
                Text('حسب نوع محتوى المؤثر', style: t.bodyLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: contentTypes.map((ct) {
                    final isSelected = tempContentTypes.contains(ct.id);
                    return FilterChip(
                      label: Text(ct.nameAr),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            tempContentTypes.add(ct.id);
                          } else {
                            tempContentTypes.remove(ct.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const Divider(height: 30),

                // Filter by platform
                Text('حسب منصات التواصل', style: t.bodyLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: platforms.map((p) {
                    final isSelected = tempPlatforms.contains(p.id);
                    return FilterChip(
                      label: Text(p.nameAr),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            tempPlatforms.add(p.id);
                          } else {
                            tempPlatforms.remove(p.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _businessTab1SelectedCampaigns = tempCampaigns;
                      _businessTab1SelectedContentTypes = tempContentTypes;
                      _businessTab1SelectedPlatforms = tempPlatforms;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('تطبيق التصفية', style: TextStyle(color: t.containers)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Business Tab 2 Filter: Status and Campaign
  Widget _buildBusinessTab2Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses = List<String>.from(_businessTab2SelectedStatuses);
    final tempCampaigns = List<String>.from(_businessTab2SelectedCampaigns);

    final statuses = [
      {'id': 'pending', 'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    final campaigns = [
      {'id': '1', 'title': 'حملة تسويقية 1'},
      {'id': '2', 'title': 'حملة تسويقية 2'},
    ];

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        tempStatuses.clear();
                        tempCampaigns.clear();
                        setModalState(() {});
                      },
                      child: Text('مسح الكل', style: TextStyle(color: t.error)),
                    ),
                    Text('تصفية العروض المرسلة', style: t.headlineSmall),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter by status
                Text('حسب الحالة', style: t.bodyLarge),
                const SizedBox(height: 10),
                ...statuses.map((status) {
                  final isSelected = tempStatuses.contains(status['id']);
                  return CheckboxListTile(
                    title: Text(status['name']!),
                    value: isSelected,
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          tempStatuses.add(status['id']!);
                        } else {
                          tempStatuses.remove(status['id']);
                        }
                      });
                    },
                  );
                }).toList(),

                const Divider(height: 30),

                // Filter by campaign
                Text('حسب الحملة', style: t.bodyLarge),
                const SizedBox(height: 10),
                ...campaigns.map((campaign) {
                  final isSelected = tempCampaigns.contains(campaign['id']);
                  return CheckboxListTile(
                    title: Text(campaign['title']!),
                    value: isSelected,
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          tempCampaigns.add(campaign['id']!);
                        } else {
                          tempCampaigns.remove(campaign['id']);
                        }
                      });
                    },
                  );
                }).toList(),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _businessTab2SelectedStatuses = tempStatuses;
                      _businessTab2SelectedCampaigns = tempCampaigns;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('تطبيق التصفية', style: TextStyle(color: t.containers)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Influencer Tab 1 Filter: Status only
  Widget _buildInfluencerTab1Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses = List<String>.from(_influencerTab1SelectedStatuses);

    final statuses = [
      {'id': 'pending', 'name': 'قيد الانتظار'},
      {'id': 'offer_sent', 'name': 'تم إرسال عرض'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      tempStatuses.clear();
                      setModalState(() {});
                    },
                    child: Text('مسح الكل', style: TextStyle(color: t.error)),
                  ),
                  Text('تصفية الطلبات المرسلة', style: t.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              Text('حسب الحالة', style: t.bodyLarge),
              const SizedBox(height: 10),
              ...statuses.map((status) {
                final isSelected = tempStatuses.contains(status['id']);
                return CheckboxListTile(
                  title: Text(status['name']!),
                  value: isSelected,
                  onChanged: (value) {
                    setModalState(() {
                      if (value == true) {
                        tempStatuses.add(status['id']!);
                      } else {
                        tempStatuses.remove(status['id']);
                      }
                    });
                  },
                );
              }).toList(),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _influencerTab1SelectedStatuses = tempStatuses;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('تطبيق التصفية', style: TextStyle(color: t.containers)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Influencer Tab 2 Filter: Status only
  Widget _buildInfluencerTab2Filter() {
    final t = FlutterFlowTheme.of(context);
    final tempStatuses = List<String>.from(_influencerTab2SelectedStatuses);

    final statuses = [
      {'id': 'pending', 'name': 'قيد الانتظار'},
      {'id': 'accepted', 'name': 'مقبول'},
      {'id': 'rejected', 'name': 'مرفوض'},
    ];

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: t.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      tempStatuses.clear();
                      setModalState(() {});
                    },
                    child: Text('مسح الكل', style: TextStyle(color: t.error)),
                  ),
                  Text('تصفية العروض الواردة', style: t.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              Text('حسب الحالة', style: t.bodyLarge),
              const SizedBox(height: 10),
              ...statuses.map((status) {
                final isSelected = tempStatuses.contains(status['id']);
                return CheckboxListTile(
                  title: Text(status['name']!),
                  value: isSelected,
                  onChanged: (value) {
                    setModalState(() {
                      if (value == true) {
                        tempStatuses.add(status['id']!);
                      } else {
                        tempStatuses.remove(status['id']);
                      }
                    });
                  },
                );
              }).toList(),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _influencerTab2SelectedStatuses = tempStatuses;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('تطبيق التصفية', style: TextStyle(color: t.containers)),
              ),
            ],
          ),
        );
      },
    );
  }

  // No filter for archive tabs
  Widget _buildNoFilter() {
    final t = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: t.secondaryText),
          const SizedBox(height: 16),
          Text('لا توجد فلاتر متاحة لهذا القسم', style: t.bodyLarge.copyWith(color: t.secondaryText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: t.backgroundElan,
      appBar: AppBar(
        backgroundColor: t.secondaryBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          _userType == 'business' ? 'الطلبات والعروض' : 'طلباتي وعروضي',
          style: t.headlineSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list, color: t.primaryText),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: t.secondaryBackground,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                controller: _tabController,
                labelColor: t.primary,
                unselectedLabelColor: t.secondaryText,
                indicatorColor: t.primary,
                tabs: _tabs,
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _userType == 'business'
                  ? [
                      _buildBusinessTab1(), // Received applications
                      _buildBusinessTab2(), // Sent offers
                      _buildBusinessTab3(), // Archive
                    ]
                  : [
                      _buildInfluencerTab1(), // Sent applications
                      _buildInfluencerTab2(), // Received offers
                      _buildInfluencerTab3(), // Archive
                    ],
            ),
          ),
        ],
      ),
    );
  }

  // Business tabs
  Widget _buildBusinessTab1() {
    return ApplicationsTabContent(
      key: const ValueKey('business_apps'),
      isBusinessView: true,
      filterStatuses:
          _businessTab1SelectedCampaigns.isEmpty &&
              _businessTab1SelectedContentTypes.isEmpty &&
              _businessTab1SelectedPlatforms.isEmpty
          ? []
          : ['pending', 'offer_sent', 'rejected'], // Show all if no filter
      filterCampaigns: _businessTab1SelectedCampaigns,
    );
  }

  Widget _buildBusinessTab2() {
    return OffersTabContent(
      key: const ValueKey('business_offers'),
      isBusinessView: true,
      filterStatuses: _businessTab2SelectedStatuses,
      filterCampaigns: _businessTab2SelectedCampaigns,
    );
  }

  Widget _buildBusinessTab3() {
    return const ArchiveTabContent(key: ValueKey('business_archive'), isBusinessView: true);
  }

  // Influencer tabs
  Widget _buildInfluencerTab1() {
    return ApplicationsTabContent(
      key: const ValueKey('influencer_apps'),
      isBusinessView: false,
      filterStatuses: _influencerTab1SelectedStatuses,
    );
  }

  Widget _buildInfluencerTab2() {
    return OffersTabContent(
      key: const ValueKey('influencer_offers'),
      isBusinessView: false,
      filterStatuses: _influencerTab2SelectedStatuses,
    );
  }

  Widget _buildInfluencerTab3() {
    return const ArchiveTabContent(key: ValueKey('influencer_archive'), isBusinessView: false);
  }
}
