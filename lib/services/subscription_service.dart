// subscription_service.dart replace karo:

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> isSubscriptionActive() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final prefsUserId = prefs.getString('userId') ?? '';
      final userId = (uid != null && uid.isNotEmpty) ? uid : prefsUserId;

      debugPrint('🔍 Checking subscription for: $userId');

      if (userId.isEmpty) {
        debugPrint('❌ userId empty');
        return false;
      }

      // ── Step 1: Users doc check ──────────────
      final userDoc = await _db.collection('users').doc(userId).get();

      debugPrint('📄 Users doc exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final status = data['subscriptionStatus'] ?? '';
        final expiry = data['subscriptionExpiry'];

        debugPrint('📋 subscriptionStatus: "$status"');
        debugPrint('📋 subscriptionExpiry: $expiry');
        debugPrint('📋 expiry type: ${expiry?.runtimeType}');

        if (status == 'active') {
          // ✅ No expiry = active
          if (expiry == null) {
            debugPrint('✅ Active — no expiry set');
            return true;
          }

          // ✅ Handle both Timestamp and String
          DateTime? expiryDate;

          if (expiry is Timestamp) {
            expiryDate = expiry.toDate();
          } else if (expiry is String && expiry.isNotEmpty) {
            try {
              expiryDate = DateTime.parse(expiry);
            } catch (_) {
              debugPrint('⚠️ Cannot parse expiry string: $expiry');
            }
          }

          debugPrint('📅 Expiry date: $expiryDate');
          debugPrint('📅 Now: ${DateTime.now()}');

          if (expiryDate == null) {
            // Parse nahi hua — active maano
            debugPrint('✅ Active — expiry unparseable');
            return true;
          }

          if (DateTime.now().isBefore(expiryDate)) {
            debugPrint('✅ Active — valid until $expiryDate');
            return true;
          }

          // Expired
          debugPrint('❌ Expired at $expiryDate');
          await _db
              .collection('users')
              .doc(userId)
              .update({'subscriptionStatus': 'expired'});
          return false;
        }

        debugPrint('❌ Status is not active: "$status"');
      }

      // ── Step 2: Subscriptions collection ─────
      debugPrint('🔍 Checking subscriptions collection...');

      final subQuery = await _db
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      debugPrint('📚 Subscriptions found: ${subQuery.docs.length}');

      if (subQuery.docs.isNotEmpty) {
        final subData = subQuery.docs.first.data();
        debugPrint('📋 Sub data: $subData');

        final expiryStr = subData['subscriptionExpiryDate']?.toString() ?? '';

        // ✅ Sync to users doc
        await _db.collection('users').doc(userId).set({
          'subscriptionStatus': 'active',
          if (expiryStr.isNotEmpty)
            'subscriptionExpiry': Timestamp.fromDate(
              DateTime.parse(expiryStr),
            ),
        }, SetOptions(merge: true));

        debugPrint('✅ Subscription active — synced!');
        return true;
      }

      debugPrint('❌ No active subscription found');
      return false;
    } catch (e, stack) {
      debugPrint('💥 SubscriptionService ERROR: $e');
      debugPrint('Stack: $stack');
      // ✅ Error pe false nahi — true return karo
      // Taake subscription wale block na hon
      return true;
    }
  }
}
