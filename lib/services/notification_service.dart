// lib/services/notification_service.dart
//
// DESIGN DECISIONS:
// 1. Deduplication via 'dedupeKey' field -prevents
//    same notification firing twice (race conditions)
// 2. Overlay controller is a static GlobalKey —
//    allows showing popups from anywhere without context
// 3. sendNotification() is the ONLY entry point —
//    all callers use same method regardless of type
// 4. FCM push is best-effort -Firestore write always
//    succeeds first, push is secondary
// 5. Foreground overlay uses OverlayEntry -no
//    package dependency, pure Flutter

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

// ── Global overlay key ────────────────────────────
// Used to show foreground popups from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Active overlay entry reference
  static OverlayEntry? _activeOverlay;
  static Timer? _overlayTimer;

  // ── Initialization ────────────────────────────
  // Call once in main() after Firebase.initializeApp()
  static Future<void> initialize() async {
    await _requestPermission();
    _setupForegroundHandler();
    _setupBackgroundTapHandler();
  }

  static Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Foreground handler ────────────────────────
  // Shows WhatsApp-style overlay popup when app is open
  static void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      if (data.isEmpty) return;

      final type = NotificationModel.typeFromString(data['type'] ?? '');
      final priority =
          NotificationModel.priorityFromString(data['priority'] ?? 'normal');
      // Show overlay popup
      _showOverlayPopup(
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        type: type,
        deepLink: data['deepLink'] ?? '',
        priority: priority,
      );
    });
  }

  // ── Background tap handler ────────────────────
  // Navigates to correct screen when user taps
  // notification from background/terminated state
  static void _setupBackgroundTapHandler() {
    // App opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleDeepLink(message.data['deepLink'] ?? '');
      }
    });

    // App brought from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleDeepLink(message.data['deepLink'] ?? '');
    });
  }

  // ── Deep link navigation ──────────────────────
  static void _handleDeepLink(String deepLink) {
    if (deepLink.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Small delay to ensure app is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed(deepLink);
      }
    });
  }

  // ── Overlay Popup (WhatsApp style) ────────────
  static void _showOverlayPopup({
    required String title,
    required String message,
    required NotificationType type,
    required String deepLink,
    required NotificationPriority priority,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Dismiss existing popup
    _dismissOverlay();

    final color = NotificationModel.colorFor(type);
    final icon = NotificationModel.iconFor(type);

    final duration = switch (priority) {
      NotificationPriority.low => 2,
      NotificationPriority.normal => 3,
      NotificationPriority.high => 5,
      NotificationPriority.urgent => 8,
    };

    _activeOverlay = OverlayEntry(
      builder: (ctx) => _NotificationPopup(
        title: title,
        message: message,
        icon: icon,
        color: color,
        deepLink: deepLink,
        onDismiss: _dismissOverlay,
        onTap: () {
          _dismissOverlay();
          _handleDeepLink(deepLink);
        },
      ),
    );

    overlay.insert(_activeOverlay!);

    // Auto-dismiss after duration
    _overlayTimer?.cancel();
    _overlayTimer = Timer(Duration(seconds: duration), () {
      _dismissOverlay();
    });
  }

  static void _dismissOverlay() {
    _overlayTimer?.cancel();
    _activeOverlay?.remove();
    _activeOverlay = null;
  }

  // ── Core Send Method ──────────────────────────
  // SINGLE entry point for ALL notification types
  //
  // Usage:
  // await NotificationService.sendNotification(
  //   userId: farmerId,
  //   role: 'farmer',
  //   type: NotificationType.orderDelivered,
  //   title: 'آرڈر ڈیلیور ہو گیا',
  //   message: 'آپ کا آرڈر پہنچ گیا',
  //   deepLink: '/orders/$orderId',
  //   metadata: {'orderId': orderId},
  // );

  static Future<void> sendNotification({
    required String userId,
    required String role,
    required NotificationType type,
    required String title,
    required String message,
    String deepLink = '',
    String referenceId = '',
    String referenceType = 'none',
    Map<String, dynamic> metadata = const {},
    NotificationPriority priority = NotificationPriority.normal,
    // Deduplication: same key within 60s = skip
    String dedupeKey = '',
  }) async {
    if (userId.isEmpty) return;

    try {
      // ── Deduplication check ──────────────────
      if (dedupeKey.isNotEmpty) {
        final existing = await _db
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('dedupeKey', isEqualTo: dedupeKey)
            .where(
              'createdAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(minutes: 1)),
              ),
            )
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          // Duplicate -skip silently
          return;
        }
      }

      final groupKey = NotificationModel.groupKeyFor(type);

      // ── Write to Firestore ───────────────────
      // This is the SOURCE OF TRUTH
      // Even if FCM fails, notification is saved
      await _db.collection('notifications').add({
        'userId': userId,
        'role': role,
        'type': type.name,
        'title': title,
        'message': message,
        'deepLink': deepLink,
        'referenceId': referenceId,
        'referenceType': referenceType,
        'groupKey': groupKey,
        'metadata': metadata,
        'priority': priority.name,
        'dedupeKey': dedupeKey,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── FCM Push ─────────────────────────────
      // Best-effort -failure doesn't lose notification
      await _sendFcmToUser(
        userId: userId,
        title: title,
        body: message,
        type: type.name,
        deepLink: deepLink,
        priority: priority,
        metadata: metadata,
      );
    } catch (e) {
      // Log but don't rethrow -notification
      // may have been saved to Firestore already
      debugPrint('[NotificationService] Error: $e');
    }
  }

  // ── Bulk Send ─────────────────────────────────
  static Future<void> sendToMany({
    required List<String> userIds,
    required String role,
    required NotificationType type,
    required String title,
    required String message,
    String deepLink = '',
    Map<String, dynamic> metadata = const {},
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    // Batch Firestore writes for efficiency
    // Max 500 per batch
    const batchSize = 400;
    final chunks = <List<String>>[];

    for (var i = 0; i < userIds.length; i += batchSize) {
      chunks.add(userIds.sublist(
          i, i + batchSize > userIds.length ? userIds.length : i + batchSize));
    }

    final groupKey = NotificationModel.groupKeyFor(type);

    for (final chunk in chunks) {
      final batch = _db.batch();
      for (final uid in chunk) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'userId': uid,
          'role': role,
          'type': type.name,
          'title': title,
          'message': message,
          'deepLink': deepLink,
          'groupKey': groupKey,
          'metadata': metadata,
          'priority': priority.name,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // ── FCM Push Helper ───────────────────────────
  static Future<void> _sendFcmToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String deepLink,
    required NotificationPriority priority,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final tokens = List<String>.from(doc.data()?['fcmTokens'] ?? []);
      if (tokens.isEmpty) return;

      // NOTE: Direct FCM from Flutter client
      // requires Firebase Admin SDK server-side.
      // For production: use Cloud Functions.
      // For MVP: notifications stored in Firestore
      // are shown via stream on next app open.
      // This is acceptable for agricultural use case
      // where real-time push is secondary.

      debugPrint('[NotificationService] FCM tokens found: ${tokens.length}');
    } catch (e) {
      debugPrint('[NotificationService] FCM error: $e');
    }
  }

  // ── Token Management ──────────────────────────
  static Future<void> registerToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _db.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> removeToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (_) {}
  }

  // ── Read Management ───────────────────────────
  static Future<void> markAsRead(String id) async {
    try {
      await _db.collection('notifications').doc(id).update({'isRead': true});
    } catch (_) {}
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  static Future<void> markGroupAsRead({
    required String userId,
    required String groupKey,
  }) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('groupKey', isEqualTo: groupKey)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Streams ───────────────────────────────────
  static Stream<int> unreadCountStream(String userId) {
    if (userId.isEmpty) return Stream.value(0);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  static Stream<int> unreadCountForGroup({
    required String userId,
    required String groupKey,
  }) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('groupKey', isEqualTo: groupKey)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}

// ── Notification Popup Widget ─────────────────────
// WhatsApp-style overlay popup for foreground
class _NotificationPopup extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String deepLink;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationPopup({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.deepLink,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<_NotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    ));
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeIn,
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color accent bar
                      Container(
                        height: 3,
                        color: widget.color,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                      height: 1.3,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                      height: 1.4,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Dismiss
                            GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFF999999),
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
      ),
    );
  }
}
