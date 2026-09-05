import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../features/auth/viewmodels/profile_viewmodel.dart';
import '../../crops/ui/crop_post_screen.dart';
import '../../crops/ui/my_crops_screen.dart';
import '../../mandi/ui/mandi_screen.dart';
import '../../guides/ui/guides_screen.dart';
import '../../marketplace/ui/marketplace_screen.dart';
import '../../orders/ui/farmer_orders_screen.dart';
import '../widgets/hero_banner.dart';
import 'profile_screen.dart';
import '../../business/ui/find_arhti_screen.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../advertisements/widgets/hero_banner_carousel.dart';
import '../../../shared/widgets/announcement_popup.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Profile load
      context.read<ProfileViewModel>().loadUserProfile();

      // ✅ Announcement — screen build hone ke baad
      Future.delayed(
        const Duration(milliseconds: 800),
        () {
          if (mounted) {
            AnnouncementPopup.showIfNeeded(context);
          }
        },
      );
    });
  }

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'منڈی ریٹس',
      'image': 'assets/images/market_rate.png',
      'route': 'mandi',
    },
    {
      'title': 'فصل پوسٹ کریں',
      'image': 'assets/images/upload_crop.png',
      'route': 'crop_post',
    },
    {
      'title': 'زرعی مصنوعات',
      'image': 'assets/images/agri_products.png',
      'route': 'marketplace',
    },
    {
      'title': 'زرعی بکنگ',
      'image': 'assets/images/booking.png',
      'route': 'agri_booking',
      'disabled': true,
    },
    {
      'title': 'آڑھتی تلاش کریں',
      'image': 'assets/images/find_arhti.png',
      'route': 'find_arhti',
    },
    {
      'title': ' زرعی قرضہ',
      'image': 'assets/images/loan.png',
      'route': 'loan',
      'disabled': true,
    },
    {
      'title': 'فصل رہنمائی',
      'image': 'assets/images/crop_guidlines.png',
      'route': 'guides',
    },
    {
      'title': 'میری فصلیں',
      'image': 'assets/images/my_crop_posts.png',
      'route': 'my_crops',
    },
    {
      'title': 'میرے آرڈرز',
      'image': 'assets/images/my_orders.png',
      'route': 'orders',
    },
  ];

  void _onActionTap(String route) {
    switch (route) {
      case 'agri_booking':
        break;
      case 'mandi':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MandiScreen()));
        break;
      case 'crop_post':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CropPostScreen()));
        break;
      case 'find_arhti':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FindArhtiScreen()));
        break;
      case 'marketplace':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
        break;
      case 'guides':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GuidesScreen()));
        break;
      case 'my_crops':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MyCropsScreen()));
        break;
      case 'orders':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()));
        break;
    }
  }

  void _showAllQuickActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: AppTheme.textGrey,
                            size: 22,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'تمام سہولیات',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            SizedBox(width: 6),
                            Text('🌿', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _quickActions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final action = _quickActions[index];
                        final isDisabled = action['disabled'] == true;
                        return _QuickActionGridCard(
                          title: action['title'] as String,
                          imagePath: action['image'] as String,
                          disabled: isDisabled,
                          onTap: isDisabled
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _onActionTap(action['route'] as String);
                                },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final user = profileVM.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: AppTheme.darkGreen,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F3D1A), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Notification
                        const NotificationBell(),

                        // Center -Logo + Name
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'کسان دوست',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 25,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),

                        // Profile
                        // Profile with name
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user != null
                                        ? '${user.name} صاحب'
                                        : 'خوش آمدید',
                                    style: const TextStyle(
                                      fontFamily: 'Nastaleeq',
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      height: 1.6,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  Text(
                                    user?.roleLabel ?? 'کسان',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                      height: 1.3,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: user != null &&
                                          user.profileImage.isNotEmpty
                                      ? Image.network(
                                          user.profileImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
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
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: HeroBannerCarousel(),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _showAllQuickActions,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'سب دیکھیں',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'فوری سہولیات',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 6),
                          Text('🌿', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick Action Cards
                SizedBox(
                  height: 118,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _quickActions.length,
                    itemBuilder: (context, index) {
                      final action = _quickActions[index];
                      final isDisabled = action['disabled'] == true;
                      // ✅ FIX: give each card a fixed width inside the
                      // horizontal ListView (unbounded width otherwise)
                      // and add spacing between cards.
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 90,
                          child: _QuickActionCard(
                            title: action['title'] as String,
                            imagePath: action['image'] as String,
                            disabled: isDisabled,
                            onTap: isDisabled
                                ? null
                                : () => _onActionTap(action['route'] as String),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Crop Feed Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'مزید دیکھیں <',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'تازہ فصل پوسٹس',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 6),
                          Text('🌾', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Crop Feed
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('crops')
                      .where('status', isEqualTo: 'active')
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.grass_outlined,
                                size: 48,
                                color: AppTheme.textGrey.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ابھی کوئی فصل نہیں',
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final expiresAt = data['expiresAt'];
                      if (expiresAt == null) return true;
                      final expiry = (expiresAt as Timestamp).toDate();
                      return expiry.isAfter(DateTime.now());
                    }).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _CropFeedCard(data: data);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Header Button Widget
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick Action Card (horizontal scroll cards on the dashboard)
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;
  final bool disabled;

  const _QuickActionCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Image.asset(
          imagePath,
          width: 46,
          height: 46,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.grass,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 2),
        // ✅ FIX: always reserve this line's space (empty when not
        // disabled) so every card has identical layout height and the
        // icon/title never shift between normal and locked cards.
        Text(
          disabled ? 'جلد آرہا ہے' : '',
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textGrey,
            height: 1.3,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
      ],
    );

    final card = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: disabled ? Opacity(opacity: 0.5, child: content) : content,
    );

    if (disabled) {
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(child: card),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 12,
                color: AppTheme.textGrey,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

// Crop Feed Card
// Crop Feed Card -Premium
class _CropFeedCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CropFeedCard({required this.data});

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

  bool _isFresh(dynamic timestamp) {
    if (timestamp == null) return false;
    try {
      final time = (timestamp as Timestamp).toDate();
      return DateTime.now().difference(time).inHours < 6;
    } catch (_) {
      return false;
    }
  }

  String _initials(String name) {
    if (name.isEmpty) return 'ک';
    return name.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final cropType = data['cropType'] ?? '';
    final isFresh = _isFresh(data['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image + badges
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Builder(
                    builder: (_) {
                      final imageUrl = data['imageUrl'] as String? ?? '';
                      if (imageUrl.isEmpty) {
                        return _CropImagePlaceholder();
                      }
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, prog) {
                          if (prog == null) return child;
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
                        errorBuilder: (_, __, ___) => _CropImagePlaceholder(),
                      );
                    },
                  ),
                ),
                // Fresh badge -top left
                if (isFresh)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'تازہ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),

                // Bookmark -top right (single instance)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    child: const Icon(
                      Icons.bookmark_border,
                      size: 17,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),

                // Price + quantity glass chips -bottom of image
                Positioned(
                  bottom: 10,
                  right: 12,
                  left: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _GlassBadge(
                        icon: Icons.scale_outlined,
                        text: '${data['quantity']} من',
                      ),
                      const SizedBox(width: 8),
                      _GlassBadge(
                        icon: Icons.monetization_on_outlined,
                        text: '${data['expectedPrice']} روپے',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Crop name + time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timeAgo(data['createdAt']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      cropType,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEFEFEF)),
                const SizedBox(height: 10),

                // Farmer row
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['userId'])
                      .get(),
                  builder: (context, snapshot) {
                    final name = snapshot.hasData && snapshot.data!.exists
                        ? ((snapshot.data!.data()
                                as Map<String, dynamic>)['name'] as String? ??
                            'کسان')
                        : 'کسان';

                    return Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                                height: 1.3,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  data['district'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textGrey,
                                    height: 1.3,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 11,
                                  color: AppTheme.textGrey,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.grass_outlined,
        size: 40,
        color: AppTheme.primaryGreen.withValues(alpha: 0.4),
      ),
    );
  }
}

// Glass-style floating badge for use on top of images
class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;

  const _GlassBadge({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primaryGreen.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : AppTheme.textDark,
              height: 1.3,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 12,
            color: highlight ? Colors.white : AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Badge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 3),
          Icon(icon, size: 11, color: color),
        ],
      ),
    );
  }
}

/// Quick Action Card for the "See All" grid popup (no fixed width, fits grid cell)
class _QuickActionGridCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;
  final bool disabled;

  const _QuickActionGridCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Image.asset(
          imagePath,
          width: 46,
          height: 46,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.grass,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 2),
        // ✅ FIX: always reserve this line's space (empty when not
        // disabled) so every grid card has identical layout height and
        // the icon/title never shift between normal and locked cards.
        Text(
          disabled ? 'جلد آرہا ہے' : '',
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textGrey,
            height: 1.3,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
      ],
    );

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: disabled ? Opacity(opacity: 0.5, child: content) : content,
    );

    if (disabled) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(child: card),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 12,
                color: AppTheme.textGrey,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
