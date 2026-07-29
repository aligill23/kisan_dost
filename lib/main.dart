import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'core/router/app_router.dart';
import 'features/crops/viewmodels/crop_viewmodel.dart';
import 'features/auth/viewmodels/profile_viewmodel.dart';
import 'features/notifications/viewmodels/notification_viewmodel.dart';
import 'services/notification_service.dart'
    show NotificationService, navigatorKey;
import 'firebase_options.dart';
import 'features/advertisements/viewmodels/advertisement_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Must be a top-level function (not inside a class) for FCM background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification already saved to Firestore by the sender -nothing needed here.
  debugPrint('[BG] ${message.data}');
}

// ── Local notifications plugin (mobile only) ──────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Firestore offline persistence ──────────────────────
  // Mobile: unlimited local cache (helps farmers/arhtis in low-connectivity
  // rural areas). Web (admin panel): smaller capped cache since it doesn't
  // need heavy offline support.
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: !kIsWeb,
    cacheSizeBytes: kIsWeb ? 40 * 1024 * 1024 : Settings.CACHE_SIZE_UNLIMITED,
  );

  // ── Anonymous Auth: ensure every device has a Firebase Auth session ──
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint(
          '[Auth] Anonymous sign-in success: ${FirebaseAuth.instance.currentUser?.uid}');
    } catch (e) {
      debugPrint('[Auth] Anonymous sign-in failed: $e');
    }
  } else {
    debugPrint(
        '[Auth] Existing session: ${FirebaseAuth.instance.currentUser?.uid}');
  }

  // ── FCM setup: MOBILE ONLY ──────────────────────────────
  if (!kIsWeb) {
    //   Initialize notification service.
    // NOTE: initialize() already wires up FirebaseMessaging.onMessage
    // (foreground overlay popup) and onMessageOpenedApp / getInitialMessage
    // (background/terminated tap -> deep link) internally. Do NOT add a
    // second onMessage.listen here -it would fire the popup twice.
    await NotificationService.initialize();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    //   Local notification channels (Android) -needed so foreground
    // messages (which FCM does NOT auto-display) show up with the right
    // sound/importance per category.
    await _setupNotificationChannels();

    // Lock to portrait only on mobile
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (_) {}
  }

  runApp(const KisanDostApp());
}

// ── Notification Channels (Android) ───────────────────────
Future<void> _setupNotificationChannels() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification tap while app is in foreground.
      final payload = details.payload ?? '';
      if (payload.isNotEmpty) {
        navigatorKey.currentState?.pushNamed(payload);
      }
    },
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // High importance channel (orders, mandi)
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'high_importance',
      'اہم اطلاعات',
      description: 'آرڈرز اور منڈی ریٹس',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
  );

  // Orders channel
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'orders',
      'آرڈرز',
      description: 'آرڈر کی اطلاعات',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ),
  );

  // Mandi channel
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'mandi',
      'منڈی ریٹس',
      description: 'منڈی قیمتیں',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
  );

  // Crops channel
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'crops',
      'فصلیں',
      description: 'فصل کی اطلاعات',
      importance: Importance.high,
      playSound: true,
    ),
  );

  // Products channel
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'products',
      'مصنوعات',
      description: 'نئی مصنوعات',
      importance: Importance.defaultImportance,
      playSound: true,
    ),
  );

  // Subscription channel
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'subscription',
      'سبسکرپشن',
      description: 'سبسکرپشن کی اطلاعات',
      importance: Importance.high,
      playSound: true,
    ),
  );
}

class KisanDostApp extends StatelessWidget {
  const KisanDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CropViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => AdvertisementViewModel()),
      ],
      child: const _RouterApp(),
    );
  }
}

// Creates the GoRouter exactly once (in initState), instead of recreating
// it on every rebuild. Recreating GoRouter on every build (e.g. inside a
// Builder in build()) tears down and rebuilds the Navigator tree whenever
// refreshListenable fires, leaving stale RenderObjects that get hit-tested
// before layout -> "Cannot hit test a render box that has never been laid
// out" + blank white screen with unresponsive buttons.
class _RouterApp extends StatefulWidget {
  const _RouterApp();

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // ⚠️ IMPORTANT: notification_service.dart exports a global
    // `navigatorKey` used for the foreground overlay popup and for
    // deep-link navigation on notification tap. AppRouter.createRouter
    // must construct GoRouter with that SAME key
    // (GoRouter(navigatorKey: navigatorKey, routes: ...)) -otherwise
    // navigatorKey.currentState / currentContext will be null and
    // popups + deep links will silently no-op. Make sure that's wired
    // up inside app_router.dart.
    _router = AppRouter.createRouter(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      //   Overlay support for foreground notification popups, etc.
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => child ?? const SizedBox(),
            ),
          ],
        );
      },
    );
  }
}
