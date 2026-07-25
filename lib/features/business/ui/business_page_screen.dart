import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/review_model.dart';
import '../../marketplace/ui/order_screen.dart';

class BusinessPageScreen extends StatefulWidget {
  final String userId;
  const BusinessPageScreen({super.key, required this.userId});

  @override
  State<BusinessPageScreen> createState() => _BusinessPageScreenState();
}

class _BusinessPageScreenState extends State<BusinessPageScreen> {
  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserRole = '';
  bool _hasReviewed = false;
  double _userRating = 0;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!doc.exists) return;

    final data = doc.data()!;

    final existing = await FirebaseFirestore.instance
        .collection('reviews')
        .where('dealerId', isEqualTo: widget.userId)
        .where('farmerId', isEqualTo: userId)
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _currentUserName = data['name'] ?? '';
        _currentUserRole = data['role'] ?? 'farmer';
        _hasReviewed = existing.docs.isNotEmpty;
        if (_hasReviewed) {
          _userRating = (existing.docs.first.data()['rating'] ?? 0).toDouble();
        }
      });
    }
  }

  Future<void> _submitReview(double rating, String comment) async {
    if (_currentUserId.isEmpty) return;

    final existing = await FirebaseFirestore.instance
        .collection('reviews')
        .where('dealerId', isEqualTo: widget.userId)
        .where('farmerId', isEqualTo: _currentUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('reviews').add({
        'dealerId': widget.userId,
        'farmerId': _currentUserId,
        'farmerName': _currentUserName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final all = await FirebaseFirestore.instance
        .collection('reviews')
        .where('dealerId', isEqualTo: widget.userId)
        .get();

    double total = 0;
    for (final r in all.docs) {
      total += (r.data()['rating'] ?? 0).toDouble();
    }
    final avg = total / all.docs.length;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'avgRating': double.parse(avg.toStringAsFixed(1)),
      'totalReviews': all.docs.length,
    });

    if (mounted) {
      setState(() {
        _hasReviewed = true;
        _userRating = rating;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '  ریٹنگ محفوظ ہو گئی',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showReviewSheet() {
    double selected = _userRating == 0 ? 0 : _userRating;
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ڈیلر کو ریٹنگ دیں',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setS(() => selected = (i + 1).toDouble()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < selected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: i < selected ? 46 : 40,
                        color:
                            i < selected ? Colors.amber : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _ratingLabel(selected),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected > 0
                      ? Colors.amber.shade700
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                maxLines: 3,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'تبصرہ لکھیں (اختیاری)',
                  hintTextDirection: TextDirection.rtl,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == 0
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _submitReview(
                            selected,
                            ctrl.text.trim(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _hasReviewed ? 'ریٹنگ اپ ڈیٹ کریں' : 'ریٹنگ جمع کریں',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r == 1) return 'بہت برا';
    if (r == 2) return 'برا';
    if (r == 3) return 'ٹھیک ہے';
    if (r == 4) return 'اچھا';
    if (r == 5) return 'بہترین! ⭐';
    return 'ستارہ منتخب کریں';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          if (!snap.hasData || !snap.data!.exists) {
            return _NotFoundView();
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final businessName = data['businessName'] ?? '';
          final ownerName = data['ownerName'] ?? data['name'] ?? '';
          final logoUrl = data['logoUrl'] ?? data['profileImage'] ?? '';
          final bannerUrl = data['bannerUrl'] ?? '';
          final description = data['description'] ?? '';
          final district = data['district'] ?? '';
          final tehsil = data['tehsil'] ?? '';
          final years = data['yearsInBusiness'] ?? 0;
          final verified = data['verified'] ?? false;
          final avgRating = (data['avgRating'] ?? 0.0).toDouble();
          final totalReviews = data['totalReviews'] ?? 0;
          final categories = List<String>.from(data['categories'] ?? []);
          final isOwner = _currentUserId == widget.userId;
          final isFarmer = _currentUserRole == 'farmer';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero Banner ──────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppTheme.primaryGreen,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner
                      bannerUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: bannerUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const _GradientBg(),
                              errorWidget: (_, __, ___) => const _GradientBg(),
                            )
                          : const _GradientBg(),

                      // Bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 130,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Logo + Name at bottom
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Left side info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Rating pill
                                  if (totalReviews > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${avgRating.toStringAsFixed(1)}  ($totalReviews)',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),

                                  // Location
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        tehsil.isNotEmpty
                                            ? '$tehsil، $district'
                                            : district,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Logo + Name right side
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Name + verified
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (verified)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.verified,
                                          color: Color(0xFF1DA1F2),
                                          size: 16,
                                        ),
                                      ),
                                    Text(
                                      businessName,
                                      style: const TextStyle(
                                        fontFamily: 'Nastaleeq',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.6,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),

                                // Logo
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: logoUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: logoUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                const _LogoFallback(),
                                          )
                                        : const _LogoFallback(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quick Stats ──────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('dealerId', isEqualTo: widget.userId)
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    builder: (ctx, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          _StatChip(
                            icon: Icons.inventory_2_outlined,
                            label: '$count پروڈکٹس',
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          if (years > 0)
                            _StatChip(
                              icon: Icons.calendar_today_outlined,
                              label: '$years سال تجربہ',
                              color: Colors.orange,
                            ),
                          const SizedBox(width: 8),
                          if (verified)
                            _StatChip(
                              icon: Icons.verified_outlined,
                              label: 'تصدیق شدہ',
                              color: const Color(0xFF1DA1F2),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Divider ──────────────────────
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),

              // ── About Section ────────────────
              if (description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'تعارف',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          description,
                          maxLines: _descExpanded ? null : 3,
                          overflow:
                              _descExpanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.7,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),

                        if (description.length > 120)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _descExpanded = !_descExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _descExpanded ? 'کم دیکھیں' : 'مزید پڑھیں',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Categories
                        if (categories.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.end,
                            children: categories
                                .map(
                                  (c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      c,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // ── Products Section ─────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'پروڈکٹس',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('dealerId', isEqualTo: widget.userId)
                    .where('status', isEqualTo: 'active')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ابھی کوئی پروڈکٹ نہیں',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final docs = snap.data!.docs;
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return _ProductCard(
                            data: d,
                            productId: docs[i].id,
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),

              // ── Ratings Section ──────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('dealerId', isEqualTo: widget.userId)
                          .orderBy('createdAt', descending: true)
                          .limit(20)
                          .snapshots(),
                      builder: (ctx, snap) {
                        final docs = snap.data?.docs ?? [];
                        final count = docs.length;

                        double liveAvg = 0;
                        final starCounts = List.filled(5, 0);
                        if (count > 0) {
                          double sum = 0;
                          for (final d in docs) {
                            final r = (d.data() as Map)['rating'] ?? 0;
                            sum += r.toDouble();
                            final ri = r.round().clamp(1, 5);
                            starCounts[ri - 1]++;
                          }
                          liveAvg = sum / count;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Section header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Give rating button
                                if (isFarmer && !isOwner)
                                  GestureDetector(
                                    onTap: _showReviewSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _hasReviewed
                                            ? Colors.amber
                                                .withValues(alpha: 0.1)
                                            : AppTheme.primaryGreen
                                                .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _hasReviewed
                                              ? Colors.amber
                                              : AppTheme.primaryGreen
                                                  .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _hasReviewed
                                                ? 'ریٹنگ بدلیں'
                                                : 'ریٹنگ دیں',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _hasReviewed
                                                  ? Colors.amber
                                                  : AppTheme.primaryGreen,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.star_rate_outlined,
                                            size: 14,
                                            color: _hasReviewed
                                                ? Colors.amber
                                                : AppTheme.primaryGreen,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'کسٹمر ریٹنگ',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                        height: 1.5,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.amber
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (count == 0)
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'ابھی کوئی ریٹنگ نہیں',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              // Summary row
                              Row(
                                children: [
                                  // Star bars
                                  Expanded(
                                    child: Column(
                                      children: List.generate(5, (i) {
                                        final star = 5 - i;
                                        final c = starCounts[star - 1];
                                        final pct = count > 0 ? c / count : 0.0;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 5),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: pct,
                                                    backgroundColor:
                                                        Colors.grey.shade100,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors.amber),
                                                    minHeight: 7,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              SizedBox(
                                                width: 16,
                                                child: Text(
                                                  '$c',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.star_rounded,
                                                size: 11,
                                                color: Colors.amber,
                                              ),
                                              SizedBox(
                                                width: 14,
                                                child: Text(
                                                  '$star',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Big number
                                  Column(
                                    children: [
                                      Text(
                                        liveAvg.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 46,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(5, (i) {
                                          if (i < liveAvg.floor()) {
                                            return const Icon(
                                                Icons.star_rounded,
                                                size: 14,
                                                color: Colors.amber);
                                          } else if (i < liveAvg) {
                                            return const Icon(
                                                Icons.star_half_rounded,
                                                size: 14,
                                                color: Colors.amber);
                                          } else {
                                            return const Icon(
                                                Icons.star_outline_rounded,
                                                size: 14,
                                                color: Colors.amber);
                                          }
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$count ریٹنگز',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400,
                                          height: 1.4,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 14),

                              // Reviews list
                              ...docs.map((d) {
                                final rv = d.data() as Map<String, dynamic>;
                                final name = rv['farmerName'] ?? '';
                                final rating = (rv['rating'] ?? 0).toDouble();
                                final comment = rv['comment'] ?? '';
                                final ts = rv['createdAt'];
                                String time = '';
                                if (ts != null) {
                                  final dt = (ts as Timestamp).toDate();
                                  final diff = DateTime.now().difference(dt);
                                  if (diff.inDays == 0) {
                                    time = 'آج';
                                  } else if (diff.inDays == 1) {
                                    time = 'کل';
                                  } else {
                                    time = '${diff.inDays} دن پہلے';
                                  }
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Stars + time
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: List.generate(
                                                    5,
                                                    (j) => Icon(
                                                          j < rating
                                                              ? Icons
                                                                  .star_rounded
                                                              : Icons
                                                                  .star_outline_rounded,
                                                          size: 13,
                                                          color: Colors.amber,
                                                        )),
                                              ),
                                              Text(
                                                time,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Name + avatar
                                          Row(
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textDark,
                                                  height: 1.3,
                                                ),
                                                textDirection:
                                                    TextDirection.rtl,
                                              ),
                                              const SizedBox(width: 8),
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: AppTheme
                                                    .primaryGreen
                                                    .withValues(alpha: 0.1),
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryGreen,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (comment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          comment,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            height: 1.6,
                                          ),
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String productId;

  const _ProductCard({
    required this.data,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? '';
    final name = data['name'] ?? '';
    final price = data['price'] ?? 0;
    final unit = data['unit'] ?? '';
    final stock = data['stock'] ?? 0;

    return GestureDetector(
      onTap: stock > 0
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderScreen(
                    productData: data,
                    productId: productId,
                  ),
                ),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.05),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.05),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.primaryGreen,
                                size: 28,
                              ),
                            ),
                          )
                        : Container(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.05),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppTheme.primaryGreen,
                              size: 28,
                            ),
                          ),

                    // Out of stock
                    if (stock == 0)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ختم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cart icon
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: stock > 0
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color:
                                stock > 0 ? Colors.white : Colors.grey.shade400,
                            size: 15,
                          ),
                        ),

                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PKR $price',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                                height: 1.2,
                              ),
                            ),
                            if (unit.isNotEmpty)
                              Text(
                                unit,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade400,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                          ],
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
    );
  }
}

// ── Stat Chip ─────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 13, color: color),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────
class _GradientBg extends StatelessWidget {
  const _GradientBg();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3D1A), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      child: const Icon(
        Icons.store_outlined,
        color: AppTheme.primaryGreen,
        size: 28,
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            const Text(
              'پیج نہیں ملا',
              style: TextStyle(
                fontFamily: 'Nastaleeq',
                fontSize: 20,
                color: AppTheme.textGrey,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'واپس جائیں',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
