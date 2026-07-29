// lib/features/notifications/viewmodels/notification_viewmodel.dart
//
// CHANGES FROM ORIGINAL:
// 1. Added groupedNotifications getter -powers
//    WhatsApp-style grouped UI
// 2. Added filterByGroup() -lets UI filter by type
// 3. Added real-time stream (replaces one-time load)
// 4. Added unread counts per group
// 5. Preserved all original methods

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── State ─────────────────────────────────────
  List<NotificationModel> _notifications = [];
  bool isLoading = false;
  String _userId = '';
  int unreadCount = 0;
  String? _activeGroupFilter;
  StreamSubscription? _streamSub;
  StreamSubscription? _unreadSub;

  // ── Getters ───────────────────────────────────
  List<NotificationModel> get notifications => _activeGroupFilter == null
      ? _notifications
      : _notifications.where((n) => n.groupKey == _activeGroupFilter).toList();

  // Groups notifications WhatsApp-style
  // Returns: { 'orders': [n1, n2], 'crops': [n3] }
  Map<String, List<NotificationModel>> get groupedNotifications {
    final map = <String, List<NotificationModel>>{};
    for (final n in _notifications) {
      map.putIfAbsent(n.groupKey, () => []).add(n);
    }
    return map;
  }

  // Unread count per group
  Map<String, int> get unreadPerGroup {
    final map = <String, int>{};
    for (final n in _notifications) {
      if (!n.isRead) {
        map[n.groupKey] = (map[n.groupKey] ?? 0) + 1;
      }
    }
    return map;
  }

  List<String> get activeGroups => groupedNotifications.keys.toList();

  String? get activeGroupFilter => _activeGroupFilter;

  // ── Constructor ───────────────────────────────
  NotificationViewModel() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    if (_userId.isNotEmpty) {
      _subscribeToNotifications();
      _listenUnreadCount();
    }
  }

  // ── Real-time stream ──────────────────────────
  // CHANGE: Replaced one-time load with live stream
  // Notifications update instantly when new ones arrive
  void _subscribeToNotifications() {
    _streamSub?.cancel();
    _streamSub = _db
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snap) {
        _notifications = snap.docs
            .map((d) => NotificationModel.fromMap(d.id, d.data()))
            .toList();
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        isLoading = false;
        notifyListeners();
      },
    );

    isLoading = true;
    notifyListeners();
  }

  void _listenUnreadCount() {
    _unreadSub?.cancel();
    _unreadSub = NotificationService.unreadCountStream(_userId).listen((count) {
      unreadCount = count;
      notifyListeners();
    });
  }

  // ── Filtering ─────────────────────────────────
  void filterByGroup(String? groupKey) {
    _activeGroupFilter = groupKey;
    notifyListeners();
  }

  void clearFilter() {
    _activeGroupFilter = null;
    notifyListeners();
  }

  // ── Actions ───────────────────────────────────
  // PRESERVED from original -same API
  Future<void> loadNotifications() async {
    // Now handled by stream -kept for compatibility
    if (_userId.isEmpty) return;
    _subscribeToNotifications();
  }

  Future<void> markAsRead(String id) async {
    await NotificationService.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.notificationId == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead(_userId);
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> markGroupAsRead(String groupKey) async {
    await NotificationService.markGroupAsRead(
      userId: _userId,
      groupKey: groupKey,
    );
  }

  // ── Stream (for backward compat) ──────────────
  Stream<List<NotificationModel>> notificationsStream() {
    if (_userId.isEmpty) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map((d) => NotificationModel.fromMap(d.id, d.data()))
            .toList());
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }
}
