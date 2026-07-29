// lib/models/notification_model.dart
//
// DESIGN DECISIONS:
// 1. Added NotificationType enum -adding new types
//    requires only 1 line here + 1 in service
// 2. Added deepLink field -enables tap navigation
//    to any screen without hardcoding routes
// 3. Added groupKey -enables WhatsApp-style grouping
//    (e.g., all order notifications group together)
// 4. Added metadata map -flexible extra data per type
//    (e.g., order ID, crop name, price) without
//    changing model schema for every new type
// 5. Added priority -controls popup visibility

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Notification Types ────────────────────────────
// Add new types here -zero other changes needed
// unless you want custom icon/color
enum NotificationType {
  // Mandi
  mandiRate,

  // Orders (full lifecycle)
  orderPlaced,
  orderConfirmed,
  orderPacked,
  orderReadyForDispatch,
  orderOutForDelivery,
  orderDelivered,

  // Crops
  cropListingPosted,
  newCropsAvailable,

  // Business
  subscriptionApproved,
  subscriptionExpiring,
  businessVerified,

  // Social
  chatMessage,

  // Promotions
  promotional,

  // System
  systemAlert,
  dealerDigest,

  // Fallback
  unknown,
}

// ── Priority Levels ───────────────────────────────
enum NotificationPriority {
  low, // No popup, just badge
  normal, // Popup for 3s
  high, // Popup for 5s + sound
  urgent, // Persistent popup
}

// ── Model ─────────────────────────────────────────
class NotificationModel {
  final String notificationId;
  final String userId;
  final String role;
  final NotificationType type;
  final String title;
  final String message;
  final String deepLink; // e.g. '/orders/abc123'
  final String referenceId;
  final String referenceType;
  final String groupKey; // Groups notifications
  final Map<String, dynamic> metadata; // Flexible extras
  final NotificationPriority priority;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.role,
    required this.type,
    required this.title,
    required this.message,
    this.deepLink = '',
    this.referenceId = '',
    this.referenceType = 'none',
    this.groupKey = '',
    this.metadata = const {},
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.createdAt,
  });

  // ── Type helpers ──────────────────────────────
  // Single source of truth for icon/color/group
  // Add new type → add case here only

  static IconData iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.mandiRate:
        return Icons.trending_up;
      case NotificationType.orderPlaced:
        return Icons.shopping_cart;
      case NotificationType.orderConfirmed:
        return Icons.check_circle;
      case NotificationType.orderPacked:
        return Icons.inventory_2;
      case NotificationType.orderReadyForDispatch:
        return Icons.local_shipping;
      case NotificationType.orderOutForDelivery:
        return Icons.delivery_dining;
      case NotificationType.orderDelivered:
        return Icons.done_all;
      case NotificationType.cropListingPosted:
        return Icons.grass;
      case NotificationType.newCropsAvailable:
        return Icons.eco;
      case NotificationType.subscriptionApproved:
        return Icons.workspace_premium;
      case NotificationType.subscriptionExpiring:
        return Icons.timer;
      case NotificationType.businessVerified:
        return Icons.verified;
      case NotificationType.chatMessage:
        return Icons.message;
      case NotificationType.promotional:
        return Icons.local_offer;
      case NotificationType.systemAlert:
        return Icons.info;
      case NotificationType.dealerDigest:
        return Icons.summarize;
      default:
        return Icons.notifications;
    }
  }

  static Color colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.mandiRate:
        return const Color(0xFF00695C);
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
      case NotificationType.orderPacked:
      case NotificationType.orderReadyForDispatch:
      case NotificationType.orderOutForDelivery:
        return const Color(0xFF1565C0);
      case NotificationType.orderDelivered:
        return const Color(0xFF2E7D32);
      case NotificationType.cropListingPosted:
      case NotificationType.newCropsAvailable:
        return const Color(0xFF388E3C);
      case NotificationType.subscriptionApproved:
        return const Color(0xFF6A1B9A);
      case NotificationType.subscriptionExpiring:
        return Colors.orange;
      case NotificationType.businessVerified:
        return Colors.lightBlue;
      case NotificationType.chatMessage:
        return const Color(0xFF25D366);
      case NotificationType.promotional:
        return const Color(0xFFE65100);
      case NotificationType.systemAlert:
        return Colors.grey;
      case NotificationType.dealerDigest:
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF388E3C);
    }
  }

  // Group key determines WhatsApp-style grouping
  static String groupKeyFor(NotificationType type) {
    switch (type) {
      case NotificationType.mandiRate:
        return 'mandi';
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
      case NotificationType.orderPacked:
      case NotificationType.orderReadyForDispatch:
      case NotificationType.orderOutForDelivery:
      case NotificationType.orderDelivered:
        return 'orders';
      case NotificationType.cropListingPosted:
      case NotificationType.newCropsAvailable:
        return 'crops';
      case NotificationType.subscriptionApproved:
      case NotificationType.subscriptionExpiring:
        return 'subscription';
      case NotificationType.businessVerified:
        return 'business';
      case NotificationType.chatMessage:
        return 'chat';
      case NotificationType.promotional:
        return 'offers';
      case NotificationType.dealerDigest:
        return 'digest';
      default:
        return 'general';
    }
  }

  static String labelFor(String groupKey) {
    const labels = {
      'mandi': '📊 منڈی ریٹس',
      'orders': '📦 آرڈرز',
      'crops': '🌾 فصلیں',
      'subscription': '⭐ سبسکرپشن',
      'business': '🏢 بزنس',
      'chat': '💬 پیغامات',
      'offers': '🎁 آفرز',
      'digest': '📋 روزانہ خلاصہ',
      'general': '🔔 عمومی',
    };
    return labels[groupKey] ?? '🔔 اطلاعات';
  }

  // ── Serialization ─────────────────────────────
  factory NotificationModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationModel(
      notificationId: id,
      userId: data['userId'] ?? '',
      role: data['role'] ?? '',
      type: NotificationModel.typeFromString(data['type'] ?? ''),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      deepLink: data['deepLink'] ?? '',
      referenceId: data['referenceId'] ?? '',
      referenceType: data['referenceType'] ?? 'none',
      groupKey: data['groupKey'] ??
          groupKeyFor(NotificationModel.typeFromString(data['type'] ?? '')),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      priority:
          NotificationModel.priorityFromString(data['priority'] ?? 'normal'),
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
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
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        notificationId: notificationId,
        userId: userId,
        role: role,
        type: type,
        title: title,
        message: message,
        deepLink: deepLink,
        referenceId: referenceId,
        referenceType: referenceType,
        groupKey: groupKey,
        metadata: metadata,
        priority: priority,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  static NotificationType typeFromString(String value) {
    try {
      return NotificationType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return NotificationType.unknown;
    }
  }

  static NotificationPriority priorityFromString(String value) {
    try {
      return NotificationPriority.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return NotificationPriority.normal;
    }
  }
}
