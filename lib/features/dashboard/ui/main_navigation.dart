import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/viewmodels/profile_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import 'farmer_dashboard.dart';
import 'arhti_dashboard.dart';
import 'dealer_dashboard.dart';
import 'profile_screen.dart';
import '../../crops/ui/my_crops_screen.dart';
import '../../crops/ui/crop_feed_screen.dart';
import '../../mandi/ui/mandi_screen.dart';
import '../../marketplace/ui/marketplace_screen.dart';
import '../../orders/ui/dealer_orders_screen.dart';
import '../../../shared/widgets/subscription_gate.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role =
        context.watch<ProfileViewModel>().currentUser?.role ?? 'farmer';

    final screens = _getScreens(role);
    final items = _getNavItems(role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: Row(
              children: List.generate(
                items.length,
                (index) {
                  final isSelected = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected ? 1.08 : 1.0,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 1.0 : 0.55,
                                child: Image.asset(
                                  items[index]['image'] as String,
                                  height: 26,
                                  width: 26,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[index]['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textGrey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                height: 1.3,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getScreens(String role) {
    switch (role) {
      case 'arhti':
        return [
          const ArhtiDashboard(),
          const SubscriptionGate(
            featureName: 'فصل فیڈ',
            child: CropFeedScreen(),
          ),
          const MandiScreen(),
          const ProfileScreen(),
        ];
      case 'dealer':
        return [
          const DealerDashboard(),
          const SubscriptionGate(
            featureName: 'پروڈکٹس',
            child: MarketplaceScreen(),
          ),
          const SubscriptionGate(
            featureName: 'آرڈرز',
            child: DealerOrdersScreen(),
          ),
          const ProfileScreen(),
        ];
      default:
        return [
          const FarmerDashboard(),
          const MyCropsScreen(),
          const MandiScreen(),
          const ProfileScreen(),
        ];
    }
  }

  List<Map<String, dynamic>> _getNavItems(String role) {
    const basePath = 'assets/images/navigation/';

    switch (role) {
      case 'arhti':
        return [
          {
            'image': '${basePath}home_nav.png',
            'label': 'ہوم',
          },
          {
            'image': '${basePath}crops_nav.png',
            'label': 'فصلیں',
          },
          {
            'image': '${basePath}market_rate_nav.png',
            'label': 'منڈی',
          },
          {
            'image': '${basePath}profile_nav.png',
            'label': 'پروفائل',
          },
        ];
      case 'dealer':
        return [
          {
            'image': '${basePath}home_nav.png',
            'label': 'ہوم',
          },
          {
            'image': '${basePath}agri_products_nav.png',
            'label': 'پروڈکٹس',
          },
          {
            'image': '${basePath}orders_nav.png',
            'label': 'آرڈرز',
          },
          {
            'image': '${basePath}profile_nav.png',
            'label': 'پروفائل',
          },
        ];
      default:
        return [
          {
            'image': '${basePath}home_nav.png',
            'label': 'ہوم',
          },
          {
            'image': '${basePath}crops_nav.png',
            'label': 'میری فصلیں',
          },
          {
            'image': '${basePath}market_rate_nav.png',
            'label': 'منڈی',
          },
          {
            'image': '${basePath}profile_nav.png',
            'label': 'پروفائل',
          },
        ];
    }
  }
}
