import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/viewmodels/profile_viewmodel.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/role_selection_screen.dart';
import '../../features/auth/ui/profile_setup_screen.dart';
import '../../features/auth/ui/profile_success_screen.dart';
import '../../features/auth/ui/terms_screen.dart';
import '../../features/dashboard/ui/main_navigation.dart';
import '../../features/business/ui/business_setup_screen.dart';
import '../../features/business/ui/business_page_screen.dart';
import '../../features/notifications/ui/notification_screen.dart';
import '../../features/notifications/viewmodels/notification_viewmodel.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authVM,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (_, __) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => ProfileViewModel(),
            child: const ProfileSetupScreen(),
          ),
        ),
        GoRoute(
          path: '/business-setup',
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => ProfileViewModel(),
            child: const BusinessSetupScreen(),
          ),
        ),
        GoRoute(
          path: '/profile-success',
          builder: (_, __) => const ProfileSuccessScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (_, __) => const TermsScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const MainNavigation(),
        ),
        // In app_router.dart -confirm this route exists:
        GoRoute(
          path: '/notifications',
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => NotificationViewModel(),
            child: const NotificationScreen(),
          ),
        ),
        GoRoute(
          path: '/business/:userId',
          builder: (_, state) => BusinessPageScreen(
            userId: state.pathParameters['userId'] ?? '',
          ),
        ),
      ],

      //   Simple redirect -NO async
      redirect: (context, state) {
        final location = state.matchedLocation;
        // Let everything through
        // SplashScreen handles all auth logic
        if (location == '/splash') return null;
        return null;
      },
    );
  }
}
