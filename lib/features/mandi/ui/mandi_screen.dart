import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  String _searchQuery = '';
  String _selectedDistrict = 'سب';
  String _userDistrict = '';

  static const List<Map<String, String>> _districts = [
    {"id": "pakpattan", "name": "پاکپتن"},
    {"id": "sahiwal", "name": "ساہیوال"},
    {"id": "okara", "name": "اوکاڑہ"},
    {"id": "faisalabad", "name": "فیصل آباد"},
    {"id": "multan", "name": "ملتان"},
    {"id": "lahore", "name": "لاہور"},
    {"id": "bahawalpur", "name": "بہاولپور"},
    {"id": "sargodha", "name": "سرگودھا"},
    {"id": "sheikhupura", "name": "شیخوپورہ"},
    {"id": "gojranwala", "name": "گوجرانوالہ"},
    {"id": "rawalpindi", "name": "راولپنڈی"},
    {"id": "attock", "name": "اٹک"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDistrict();
  }

  // ── BACKEND LOGIC -UNCHANGED ─────────────────────
  Future<void> _loadUserDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && mounted) {
        final district = doc.data()?['district'] ?? '';
        setState(() {
          _userDistrict = district;
          if (district.isNotEmpty) {
            _selectedDistrict = district;
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F1),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────
          SliverAppBar(
            expandedHeight: 128,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.darkGreen,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D3315),
                      Color(0xFF1B5E20),
                      Color(0xFF256B2B),
                    ],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkGreen.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      // Decorative soft glow circles
                      Positioned(
                        top: -30,
                        left: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFF69F0AE).withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: Color(0xFF69F0AE),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'کسان دوست منڈی ریٹس',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Nastaleeq',
                                      fontSize: 27,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.6,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Live indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF69F0AE)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const _PulsingDot(),
                                        const SizedBox(width: 6),
                                        Text(
                                          'لائیو اپ ڈیٹ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            height: 1.3,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Last updated
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('mandi_rates')
                                        .orderBy('createdAt', descending: true)
                                        .limit(1)
                                        .snapshots(),
                                    builder: (ctx, snap) {
                                      if (!snap.hasData ||
                                          snap.data!.docs.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      final data = snap.data!.docs.first.data()
                                          as Map<String, dynamic>?;
                                      final ts = data?['createdAt'];
                                      if (ts == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final dt =
                                          (ts as dynamic).toDate() as DateTime;
                                      final diff =
                                          DateTime.now().difference(dt);
                                      final when = diff.inMinutes < 60
                                          ? '${diff.inMinutes} منٹ پہلے'
                                          : diff.inHours < 24
                                              ? '${diff.inHours} گھنٹے پہلے'
                                              : '${dt.day}/${dt.month}/${dt.year}';
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            when,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white
                                                  .withValues(alpha: 0.75),
                                              height: 1.3,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Animated marquee strip ────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.10),
                    AppTheme.primaryGreen.withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.campaign_rounded,
                    size: 15,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _MarqueeText(
                      text:
                          'خرید و فروخت سے پہلے آج کے منڈی ریٹس ضرور چیک کریں',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── District Dropdown + Search ────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  // District dropdown (above search)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDistrict,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Colors.white,
                        items: [
                          'سب',
                          ..._districts.map((d) => d['name']!),
                        ].map((d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  d,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: AppTheme.primaryGreen,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return [
                            'سب',
                            ..._districts.map((d) => d['name']!),
                          ].map((d) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.filter_list_rounded,
                                      size: 14,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    d,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDistrict = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search
                  TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    textDirection: TextDirection.rtl,
                    style:
                        const TextStyle(fontSize: 14, color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'فصل تلاش کریں...',
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6FAF6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGreen,
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats Row ────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mandi_rates')
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const SizedBox.shrink();
                }
                final docs = snap.data!.docs;
                final up = docs
                    .where((d) => (d.data() as Map)['trend'] == 'up')
                    .length;
                final down = docs.length - up;

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatPill(
                          label: 'قیمت اوپر',
                          value: '$up',
                          color: const Color(0xFF2E7D32),
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      _Divider(),
                      Expanded(
                        child: _StatPill(
                          label: 'قیمت نیچے',
                          value: '$down',
                          color: const Color(0xFFC62828),
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                      _Divider(),
                      Expanded(
                        child: _StatPill(
                          label: 'کل فصلیں',
                          value: '${docs.length}',
                          color: AppTheme.primaryGreen,
                          icon: Icons.grass_rounded,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Rate Cards ───────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mandi_rates')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const _RateSkeleton(),
                    childCount: 5,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(),
                );
              }

              var docs = snapshot.data!.docs;

              // District filter
              if (_selectedDistrict != 'سب') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['district'] == _selectedDistrict;
                }).toList();
              }

              // Search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['cropName'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    message: 'اس ضلع میں کوئی ریٹ نہیں',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _RateCard(
                        data: data,
                        isUserDistrict: data['district'] == _userDistrict,
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Pulsing live-dot ───────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 0.7 + (_ctrl.value * 0.5);
        return Opacity(
          opacity: 0.5 + (_ctrl.value * 0.5),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF69F0AE),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Animated Marquee (seamless, continuous loop) ───
class _MarqueeText extends StatefulWidget {
  final String text;
  const _MarqueeText({required this.text});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _lastUnitWidth = 0;

  static const _style = TextStyle(
    fontFamily: 'Nastaleeq',
    fontSize: 15,
    color: AppTheme.primaryGreen,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  // Explicit pixel gap between repeats -plain space characters collapse
  // in Urdu/Nastaleeq shaping, so a real SizedBox is used instead of spaces.
  static const double _gapWidth = 60;
  static const double _pixelsPerSecond = 30;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: _style),
          textDirection: TextDirection.rtl,
          maxLines: 1,
        )..layout();
        final textWidth = tp.width;
        final unitWidth = textWidth + _gapWidth;

        final repeatCount = (maxWidth * 2 / unitWidth).ceil() + 2;
        final totalWidth = unitWidth * repeatCount;

        if (_lastUnitWidth != unitWidth) {
          _lastUnitWidth = unitWidth;
          _ctrl.duration = Duration(
            milliseconds: (unitWidth / _pixelsPerSecond * 1000).round(),
          );
          if (!_ctrl.isAnimating) {
            _ctrl.repeat();
          }
        } else if (!_ctrl.isAnimating) {
          _ctrl.repeat();
        }

        final repeatedChildren = <Widget>[];
        for (int i = 0; i < repeatCount; i++) {
          repeatedChildren.add(
            Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: _style,
              textDirection: TextDirection.rtl,
            ),
          );
          repeatedChildren.add(SizedBox(width: _gapWidth));
        }

        return ClipRect(
          child: SizedBox(
            height: 22,
            width: maxWidth,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final dx = -_ctrl.value * unitWidth;
                return OverflowBox(
                  maxWidth: totalWidth,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: repeatedChildren,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Rate Card ─────────────────────────────────────
class _RateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isUserDistrict;

  const _RateCard({
    required this.data,
    required this.isUserDistrict,
  });

  @override
  Widget build(BuildContext context) {
    final trend = data['trend'] ?? 'stable';
    final isUp = trend == 'up';
    final isDown = trend == 'down';
    final price = data['pricePerMund']?.toString() ?? '0';
    final cropName = data['cropName'] ?? '';
    final district = data['district'] ?? '';

    final trendColor = isUp
        ? const Color(0xFF2E7D32)
        : isDown
            ? const Color(0xFFC62828)
            : Colors.grey.shade500;

    final trendIcon = isUp
        ? Icons.trending_up_rounded
        : isDown
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    final trendLabel = isUp
        ? 'اوپر'
        : isDown
            ? 'نیچے'
            : 'مستحکم';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUserDistrict
            ? Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.45),
                width: 1.5,
              )
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored trend accent bar
              Container(
                width: 5,
                color: trendColor.withValues(alpha: isUserDistrict ? 0.9 : 0.7),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      // Left -Price + Trend
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trend badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: trendColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  trendIcon,
                                  size: 13,
                                  color: trendColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  trendLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: trendColor,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PKR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'فی من',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                trendColor == Colors.grey.shade500
                                    ? AppTheme.textDark
                                    : trendColor,
                                (trendColor == Colors.grey.shade500
                                        ? AppTheme.textDark
                                        : trendColor)
                                    .withValues(alpha: 0.75),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              _formatPrice(price),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Right -Crop info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isUserDistrict)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.primaryGreen
                                        .withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.star_rounded,
                                      size: 11, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'آپ کا ضلع',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),

                          // Crop name
                          Text(
                            cropName,
                            style: const TextStyle(
                              fontFamily: 'Nastaleeq',
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              height: 1.7,
                            ),
                            textDirection: TextDirection.rtl,
                          ),

                          // District
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  district,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(String price) {
    try {
      final n = int.parse(price);
      final s = n.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i != 0 && (s.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(s[i]);
      }
      return buffer.toString();
    } catch (_) {
      return price;
    }
  }
}

// ── Stat Pill ─────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

// ── Divider ───────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: Colors.grey.shade200,
    );
  }
}

// ── Skeleton (shimmer) ─────────────────────────────
class _RateSkeleton extends StatefulWidget {
  const _RateSkeleton();

  @override
  State<_RateSkeleton> createState() => _RateSkeletonState();
}

class _RateSkeletonState extends State<_RateSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ShaderMask(
              shaderCallback: (bounds) {
                final t = _ctrl.value;
                return LinearGradient(
                  begin: Alignment(-1.0 - t * 2, 0),
                  end: Alignment(1.0 - t * 2, 0),
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                  stops: const [0.35, 0.5, 0.65],
                ).createShader(bounds);
              },
              child: Container(color: Colors.grey.shade200),
            ),
          ),
        );
      },
    );
  }
}

// ── Empty State ───────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? message;

  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.12),
                  AppTheme.primaryGreen.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up_outlined,
              size: 42,
              color: AppTheme.primaryGreen.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message ?? 'ابھی کوئی ریٹ نہیں',
            style: const TextStyle(
              fontFamily: 'Nastaleeq',
              fontSize: 18,
              color: AppTheme.textGrey,
              height: 1.8,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          const Text(
            'جلد اپ ڈیٹ ہوں گے',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
