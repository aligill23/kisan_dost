import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> isSubscriptionActive() async {
    try {
      // ✅ Step 1 — Firebase Auth UID lo
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // ✅ Step 2 — SharedPrefs se bhi lo fallback
      final prefs = await SharedPreferences.getInstance();
      final prefsUserId = prefs.getString('userId') ?? '';

      // Use jo bhi available ho
      final userId = (uid != null && uid.isNotEmpty) ? uid : prefsUserId;

      if (userId.isEmpty) {
        return false;
      }

      // ✅ Step 3 — PEHLE user document check karo
      // Yeh fast hai aur rules issue nahi
      final userDoc = await _db.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final status = data['subscriptionStatus'] ?? '';
        final expiry = data['subscriptionExpiry'];

        if (status == 'active') {
          // Expiry check karo
          if (expiry != null) {
            final expiryDate = (expiry as Timestamp).toDate();
            if (DateTime.now().isBefore(expiryDate)) {
              return true; // ✅ Active!
            }
            // Expired — update karo
            await _db
                .collection('users')
                .doc(userId)
                .update({'subscriptionStatus': 'expired'});
            return false;
          }
          // Koi expiry nahi — active maano
          return true;
        }
      }

      // ✅ Step 4 — subscriptions collection bhi check
      // (fallback)
      try {
        final subQuery = await _db
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (subQuery.docs.isNotEmpty) {
          // ✅ Subscription mili — user doc update karo
          final subData = subQuery.docs.first.data();
          final expiryStr = subData['subscriptionExpiryDate']?.toString() ?? '';

          await _db.collection('users').doc(userId).update({
            'subscriptionStatus': 'active',
            if (expiryStr.isNotEmpty)
              'subscriptionExpiry': Timestamp.fromDate(
                DateTime.parse(expiryStr),
              ),
          });

          return true;
        }
      } catch (e) {
        // Rules block kar sakti hain — ignore
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
