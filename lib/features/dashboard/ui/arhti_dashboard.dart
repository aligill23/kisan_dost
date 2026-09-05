import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../features/auth/viewmodels/profile_viewmodel.dart';
import '../../../services/subscription_service.dart';
import '../../crops/ui/crop_feed_screen.dart';
import '../../mandi/ui/mandi_screen.dart';
import '../../advertisements/widgets/hero_banner_carousel.dart';
import 'profile_screen.dart';
import '../../subscription/ui/subscription_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../crops/ui/crop_detail_screen.dart';
import '../../../shared/widgets/announcement_popup.dart';

class ArhtiDashboard extends StatefulWidget {
  const ArhtiDashboard({super.key});

  @override
  State<ArhtiDashboard> createState() => _ArhtiDashboardState();
}

class _ArhtiDashboardState extends State<ArhtiDashboard> {
  bool _isSubscribed = false;
  bool _checkingSubscription = true;

  @override
  // dealer_dashboard.dart initState:
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUserProfile();

      // ✅ Same announcement
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

// arhti_dashboard.dart mein bhi same ✅

  Future<void> _checkSubscription() async {
    final active = await SubscriptionService.isSubscriptionActive();
    if (mounted) {
      setState(() {
        _isSubscribed = active;
        _checkingSubscription = false;
      });
    }
  }

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'فصلیں دیکھیں',
      'image': 'assets/images/my_crop_posts.png',
      'route': 'crops',
    },
    {
      'title': 'منڈی ریٹس',
      'image': 'assets/images/market_rate.png',
      'route': 'mandi',
    },
    {
      'title': 'سبسکرپشن',
      'image': 'assets/images/subscription.png',
      'route': 'subscription',
    },
  ];

  void _onActionTap(String route) {
    switch (route) {
      case 'crops':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CropFeedScreen()));
        break;
      case 'mandi':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MandiScreen()));
        break;
      case 'subscription':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        ).then((_) => _checkSubscription());
        break;
    }
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
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF5D3A00),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Notification
                        const NotificationBell(),

                        // Center
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'کسان دوست',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            if (user != null)
                              Text(
                                'السلام علیکم، ${user.name} صاحب',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.3,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                          ],
                        ),

//  Profile avatar with R2 image
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ),
                          child: Container(
                            width: 42,
                            height: 42,
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
                                      errorBuilder: (_, __, ___) => const Icon(
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
                // Subscription Banner (if not subscribed)
                if (!_checkingSubscription)
                  _isSubscribed
                      ? _ActiveSubscriptionCard()
                      : _SubscriptionBanner(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen()),
                          ).then((_) => _checkSubscription()),
                        ),

                // Hero Banner
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: const HeroBannerCarousel(),
                ),
                const SizedBox(height: 24),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('crops')
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          Expanded(
                            child: _IllustrationStatCard(
                              title: 'کُل فصلیں',
                              value: count.toString(),
                              imagePath: 'assets/images/crops/totalcrops.png',
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _IllustrationStatCard(
                              title: user?.district ?? '—',
                              value: 'ضلع',
                              imagePath: 'assets/images/crops/location.png',
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _IllustrationStatCard(
                              title: _isSubscribed ? 'فعال' : 'غیر فعال',
                              value: 'سبسکرپشن',
                              imagePath:
                                  'assets/images/crops/subscriptionicon.png',
                              color: _isSubscribed
                                  ? AppTheme.primaryGreen
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                      const Text('🌿', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick Actions
                SizedBox(
                  height: 118,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _quickActions.length,
                    itemBuilder: (context, index) {
                      final action = _quickActions[index];
                      return _QuickActionCard(
                        title: action['title'] as String,
                        imagePath: action['image'] as String,
                        onTap: () => _onActionTap(action['route'] as String),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Crop Feed Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CropFeedScreen()),
                        ),
                        child: const Text(
                          'مزید دیکھیں <',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE65100),
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
                          const Text('🌾', style: TextStyle(fontSize: 16)),
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
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'ابھی کوئی فصل نہیں',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final expiresAt = data['expiresAt'];
                      if (expiresAt == null) return true;
                      return (expiresAt as Timestamp)
                          .toDate()
                          .isAfter(DateTime.now());
                    }).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _ArhtiCropCard(
                          docId: docs[index].id, // ← ADD
                          data: data,
                          isSubscribed: _isSubscribed,
                          onContactTap: () => _handleContact(data),
                          onSubscribeTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen()),
                          ).then((_) => _checkSubscription()),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton.icon(
                    onPressed: () async {
                      await authVM.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: AppTheme.textGrey,
                      size: 16,
                    ),
                    label: const Text(
                      'لاگ آؤٹ',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _handleContact(Map<String, dynamic> data) async {
    if (!_isSubscribed) {
      _showSubscriptionRequired();
      return;
    }
    final phone = data['phone'] ?? '';
    if (phone.isEmpty) return;
    _showContactDialog(phone);
  }

  void _showContactDialog(String phone) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F3D1A), AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 32),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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
                    // WhatsApp
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final url =
                            'https://wa.me/92${phone.replaceAll(RegExp(r'^0'), '')}';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25D366)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'واٹس ایپ پر میسج کریں',
                              style: TextStyle(
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
                    ),
                    const SizedBox(height: 10),

                    // Call
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'کال کریں',
                              style: TextStyle(
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
                    ),
                    const SizedBox(height: 10),

                    // Cancel
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
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
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
    );
  }

  void _showSubscriptionRequired() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: Color(0xFF6A1B9A), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'سبسکرپشن ضروری ہے',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'کسانوں سے رابطہ کرنے کے لیے سبسکرپشن لیں',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'بعد میں',
                        style: TextStyle(color: AppTheme.textGrey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A0080), Color(0xFF6A1B9A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen()),
                          ).then((_) => _checkSubscription());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ابھی لیں',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Header Button
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// Subscription Banner
class _SubscriptionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SubscriptionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A0080), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ابھی لیں',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                  height: 1.4,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'پریمیم ممبر بنیں',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    'کسانوں سے براہ راست رابطہ کریں',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/images/subscription.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Action Card
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 12),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Image.asset(
              imagePath,
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.grass,
                color: AppTheme.primaryGreen,
                size: 32,
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
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// Stat Card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textGrey,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// Arhti Crop Card
class _ArhtiCropCard extends StatelessWidget {
  final String docId; // ← ADD
  final Map<String, dynamic> data;
  final bool isSubscribed;
  final VoidCallback onContactTap;
  final VoidCallback onSubscribeTap;

  const _ArhtiCropCard({
    required this.docId, // ← ADD
    required this.data,
    required this.isSubscribed,
    required this.onContactTap,
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

  String _getFallbackImage(String cropType) {
    const map = {
      'گندم': 'assets/images/banner1.jpg',
      'چاول': 'assets/images/banner2.jpg',
      'کپاس': 'assets/images/banner3.jpg',
    };
    return map[cropType] ?? 'assets/images/banner1.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? '';
    final hasNetworkImage = imageUrl.isNotEmpty;

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
        children: [
          Row(
            children: [
              // Left Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Crop Name
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
                      // Time
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

                      // Price BIG
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

              // Right -Real Crop Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 180,
                      child: hasNetworkImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, prog) {
                                if (prog == null) return child;
                                return Container(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.08),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Image.asset(
                                _getFallbackImage(data['cropType'] ?? ''),
                                fit: BoxFit.cover,
                                width: 120,
                                height: 180,
                              ),
                            )
                          : Image.asset(
                              _getFallbackImage(data['cropType'] ?? ''),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 180,
                            ),
                    ),
                    // Lock overlay for non-subscribed
                    if (!isSubscribed)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: const Icon(Icons.lock_outline,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    // Bookmark
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_border,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
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
                // Contact / Subscribe Button
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
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CropDetailScreen(
                        data: data,
                        isSubscribed: isSubscribed,
                        onSubscribeTap: onSubscribeTap,
                      ),
                    ),
                  ),
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
              ],
            ),
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
} // Active Subscription Card

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D1A), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left -Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.amber,
              size: 28,
            ),
          ),

          // Right -Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Row(
                children: [
                  Text(
                    'پریمیم سبسکرپشن فعال',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.verified, color: Colors.amber, size: 16),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'تمام سہولیات فعال ہیں ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IllustrationStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String imagePath;
  final Color color;

  const _IllustrationStatCard({
    required this.title,
    required this.value,
    required this.imagePath,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(
            imagePath,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.grass, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.3,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
