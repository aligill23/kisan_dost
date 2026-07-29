import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/subscription_service.dart';
import '../../subscription/ui/subscription_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'crop_detail_screen.dart';

class CropFeedScreen extends StatefulWidget {
  const CropFeedScreen({super.key});

  @override
  State<CropFeedScreen> createState() => _CropFeedScreenState();
}

class _CropFeedScreenState extends State<CropFeedScreen> {
  String _searchQuery = '';
  String _selectedCrop = 'سب';
  bool _isSubscribed = false;

  final List<String> _cropTypes = [
    'سب',
    'گندم',
    'چاول',
    'کپاس',
    'گنا',
    'مکئی',
    'سبزیاں',
    'پھل',
  ];

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final active = await SubscriptionService.isSubscriptionActive();
    if (mounted) setState(() => _isSubscribed = active);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF3E2000),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3E2000), Color(0xFFE65100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'دستیاب فصلیں',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              'تازہ فصل پوسٹس',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'فصل تلاش کریں...',
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.primaryGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _cropTypes.length,
                    itemBuilder: (_, i) {
                      final crop = _cropTypes[i];
                      final selected = _selectedCrop == crop;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCrop = crop),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE65100)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFE65100)
                                  : AppTheme.borderLight,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE65100)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            crop,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  selected ? Colors.white : AppTheme.textGrey,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Crop List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('crops')
                .where('status', isEqualTo: 'active')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: Color(0xFFE65100)),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(child: _emptyState());
              }

              var docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // Expiry
                final expiresAt = data['expiresAt'];
                if (expiresAt != null) {
                  if (!(expiresAt as Timestamp)
                      .toDate()
                      .isAfter(DateTime.now())) return false;
                }

                // Crop filter
                if (_selectedCrop != 'سب' && data['cropType'] != _selectedCrop)
                  return false;

                // Search
                if (_searchQuery.isNotEmpty) {
                  final ct = (data['cropType'] ?? '').toString().toLowerCase();
                  final d = (data['district'] ?? '').toString().toLowerCase();
                  if (!ct.contains(_searchQuery) && !d.contains(_searchQuery))
                    return false;
                }

                return true;
              }).toList();

              if (docs.isEmpty) {
                return SliverToBoxAdapter(child: _emptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      return _PremiumCropCard(
                        data: data,
                        docId: id,
                        isSubscribed: _isSubscribed,
                        onContactTap: () => _handleContact(context, data),
                        onDetailsTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropDetailScreen(
                              data: data,
                              isSubscribed: _isSubscribed,
                              onSubscribeTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SubscriptionScreen()),
                              ).then((_) => _checkSubscription()),
                            ),
                          ),
                        ),
                        onSubscribeTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen()),
                        ).then((_) => _checkSubscription()),
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

  Future<void> _handleContact(
      BuildContext context, Map<String, dynamic> data) async {
    if (!_isSubscribed) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      ).then((_) => _checkSubscription());
      return;
    }
    final phone = data['phone'] ?? '';
    if (phone.isEmpty) return;
    _showContactDialog(context, phone);
  }

  void _showContactDialog(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F3D1A), AppTheme.primaryGreen],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'کسان سے رابطہ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ContactButton(
                    label: 'واٹس ایپ پر میسج کریں',
                    icon: Icons.message,
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(
                          'https://wa.me/92${phone.replaceAll(RegExp(r'^0'), '')}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _ContactButton(
                    label: 'کال کریں',
                    icon: Icons.call,
                    color: AppTheme.primaryGreen,
                    onTap: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'بند کریں',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grass_outlined,
              size: 80, color: AppTheme.textGrey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'کوئی فصل نہیں ملی',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'فلٹر تبدیل کریں یا دوبارہ کوشش کریں',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Premium Crop Card
class _PremiumCropCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isSubscribed;
  final VoidCallback onContactTap;
  final VoidCallback onDetailsTap;
  final VoidCallback onSubscribeTap;

  const _PremiumCropCard({
    required this.data,
    required this.docId,
    required this.isSubscribed,
    required this.onContactTap,
    required this.onDetailsTap,
    required this.onSubscribeTap,
  });

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final time = (timestamp as Timestamp).toDate();
      final diff = DateTime.now().difference(time);
      if (diff.inMinutes < 60) return '${diff.inMinutes} منٹ پہلے';
      if (diff.inHours < 24) return '${diff.inHours} گھنٹے پہلے';
      return '${diff.inDays} دن پہلے';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row
          Row(
            children: [
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Crop Name + Time
                      Text(
                        data['cropType'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _timeAgo(data['createdAt']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.access_time,
                              size: 11, color: AppTheme.textGrey),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price -BIG
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'روپے/من',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['expectedPrice']?.toString() ?? '0',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'مقدار: ${data['quantity']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.scale_outlined,
                              size: 14, color: AppTheme.textGrey),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Farmer + Location
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['userId'])
                            .get(),
                        builder: (context, snap) {
                          final name = snap.hasData && snap.data!.exists
                              ? (snap.data!.data()
                                      as Map<String, dynamic>)['name'] ??
                                  'کسان'
                              : 'کسان';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.person_outline,
                                      size: 13, color: AppTheme.primaryGreen),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    data['district'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGrey,
                                      height: 1.4,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: AppTheme.primaryGreen),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.08),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
            ],
          ),

          // Action Row
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Contact / Subscribe
                Expanded(
                  child: GestureDetector(
                    onTap: isSubscribed ? onContactTap : onSubscribeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSubscribed
                              ? [const Color(0xFF0F3D1A), AppTheme.primaryGreen]
                              : [
                                  const Color(0xFF4A0080),
                                  const Color(0xFF6A1B9A)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isSubscribed
                                    ? AppTheme.primaryGreen
                                    : const Color(0xFF6A1B9A))
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSubscribed ? Icons.phone : Icons.lock_open,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSubscribed ? 'رابطہ کریں' : 'سبسکرپشن لیں',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Details
                Expanded(
                  child: GestureDetector(
                    onTap: onDetailsTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.primaryGreen, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'تفصیل دیکھیں',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
      child: const Icon(Icons.grass, color: AppTheme.primaryGreen, size: 48),
    );
  }
}

// Contact Button
class _ContactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
