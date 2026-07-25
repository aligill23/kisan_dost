const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────
// HELPER — Send FCM to a user by userId
// ─────────────────────────────────────────────────
async function sendPushToUser(userId, payload) {
  try {
    const userDoc = await db
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) return;

    const tokens = userDoc.data().fcmTokens || [];
    if (tokens.length === 0) return;

    const message = {
      tokens: tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: payload.channelId || "default",
          sound: "default",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
          notificationCount: 1,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      data: {
        title: payload.title,
        body: payload.body,
        type: payload.type || "general",
        deepLink: payload.deepLink || "",
        priority: payload.priority || "normal",
        ...(payload.metadata || {}),
      },
    };

    const response = await messaging.sendEachForMulticast(message);

    // Remove invalid tokens
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, i) => {
        if (!resp.success) {
          if (
            resp.error.code ===
              "messaging/invalid-registration-token" ||
            resp.error.code ===
              "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(tokens[i]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await db
          .collection("users")
          .doc(userId)
          .update({
            fcmTokens:
              admin.firestore.FieldValue.arrayRemove(
                ...invalidTokens
              ),
          });
      }
    }

    console.log(
      `Sent to ${userId}: ${response.successCount} success, ${response.failureCount} failed`
    );
  } catch (error) {
    console.error(`Error sending to ${userId}:`, error);
  }
}

// ─────────────────────────────────────────────────
// HELPER — Save notification to Firestore
// ─────────────────────────────────────────────────
async function saveNotification(userId, role, data) {
  try {
    await db.collection("notifications").add({
      userId: userId,
      role: role,
      type: data.type,
      title: data.title,
      message: data.body,
      deepLink: data.deepLink || "",
      groupKey: data.groupKey || "general",
      metadata: data.metadata || {},
      priority: data.priority || "normal",
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Error saving notification:", error);
  }
}

// ─────────────────────────────────────────────────
// TRIGGER 1 — NEW ORDER PLACED
// Fires when order added → notify dealer
// ─────────────────────────────────────────────────
exports.onOrderPlaced = functions
  .firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;
    const dealerId = order.dealerId || "";
    const buyerName = order.buyerName || "ایک کسان";
    const productName = order.productName || "پروڈکٹ";
    const quantity = order.quantity || "";

    if (!dealerId) return null;

    const payload = {
      title: "🛒 نیا آرڈر آ گیا!",
      body: `${buyerName} نے ${quantity} ${productName} کا آرڈر دیا ہے`,
      type: "orderPlaced",
      channelId: "orders",
      deepLink: "/orders",
      groupKey: "orders",
      priority: "high",
      metadata: {
        orderId: orderId,
        buyerName: buyerName,
        product: productName,
      },
    };

    await saveNotification(dealerId, "dealer", payload);
    await sendPushToUser(dealerId, payload);

    return null;
  });

// ─────────────────────────────────────────────────
// TRIGGER 2 — ORDER COMPLETED → notify farmer
// ─────────────────────────────────────────────────
exports.onOrderCompleted = functions
  .firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only fire when status changes to completed
    if (
      before.status === after.status ||
      after.status !== "completed"
    ) {
      return null;
    }

    const buyerId = after.buyerId || "";
    const productName = after.productName || "پروڈکٹ";
    const orderId = context.params.orderId;

    if (!buyerId) return null;

    const payload = {
      title: "  آرڈر مکمل ہو گیا!",
      body: `آپ کا ${productName} کا آرڈر ڈیلر نے مکمل کر دیا ہے`,
      type: "orderDelivered",
      channelId: "orders",
      deepLink: "/orders",
      groupKey: "orders",
      priority: "high",
      metadata: {
        orderId: orderId,
        product: productName,
      },
    };

    await saveNotification(buyerId, "farmer", payload);
    await sendPushToUser(buyerId, payload);

    return null;
  });

// ─────────────────────────────────────────────────
// TRIGGER 3 — NEW PRODUCT ADDED
// Fires when dealer adds product → notify farmers
// ─────────────────────────────────────────────────
exports.onProductAdded = functions
  .firestore
  .document("products/{productId}")
  .onCreate(async (snap, context) => {
    const product = snap.data();
    const productId = context.params.productId;
    const productName = product.name || "نئی مصنوعات";
    const dealerName = product.dealerName || "ڈیلر";
    const price = product.price || 0;
    const category = product.category || "";

    // Get all farmers
    const farmers = await db
      .collection("users")
      .where("role", "==", "farmer")
      .get();

    if (farmers.empty) return null;

    const payload = {
      title: `🛒 نئی مصنوعات دستیاب!`,
      body: `${dealerName} نے ${productName} شامل کیا — PKR ${price}`,
      type: "newCropsAvailable",
      channelId: "products",
      deepLink: "/marketplace",
      groupKey: "offers",
      priority: "normal",
      metadata: {
        productId: productId,
        productName: productName,
        price: price.toString(),
        category: category,
      },
    };

    // Batch save + send (max 500 at once)
    const batch = db.batch();
    const notifPromises = [];

    for (const farmer of farmers.docs) {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: farmer.id,
        role: "farmer",
        type: payload.type,
        title: payload.title,
        message: payload.body,
        deepLink: payload.deepLink,
        groupKey: payload.groupKey,
        metadata: payload.metadata,
        priority: payload.priority,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      notifPromises.push(sendPushToUser(farmer.id, payload));
    }

    await batch.commit();
    await Promise.allSettled(notifPromises);

    return null;
  });

// ─────────────────────────────────────────────────
// TRIGGER 4 — MANDI RATE UPDATED
// Fires when admin updates mandi rate → notify all farmers
// ─────────────────────────────────────────────────
exports.onMandiRateUpdated = functions
  .firestore
  .document("mandi_rates/{rateId}")
  .onWrite(async (change, context) => {
    // Skip deletes
    if (!change.after.exists) return null;

    const rate = change.after.data();
    const cropName = rate.cropName || "فصل";
    const price = rate.pricePerMund || 0;
    const district = rate.district || "";
    const trend = rate.trend || "stable";
    const rateId = context.params.rateId;

    const trendEmoji =
      trend === "up" ? "📈" : trend === "down" ? "📉" : "➡️";
    const trendText =
      trend === "up" ? "اوپر" : trend === "down" ? "نیچے" : "مستحکم";

    // Get all farmers
    const farmers = await db
      .collection("users")
      .where("role", "==", "farmer")
      .get();

    if (farmers.empty) return null;

    const payload = {
      title: `${trendEmoji} منڈی ریٹ اپ ڈیٹ`,
      body: `${cropName} (${district}): PKR ${price} فی من — قیمت ${trendText}`,
      type: "mandiRate",
      channelId: "mandi",
      deepLink: "/mandi",
      groupKey: "mandi",
      priority: "high",
      metadata: {
        cropName: cropName,
        price: price.toString(),
        district: district,
        trend: trend,
        rateId: rateId,
      },
    };

    // Save to all farmers + send FCM
    const batch = db.batch();
    const notifPromises = [];

    for (const farmer of farmers.docs) {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: farmer.id,
        role: "farmer",
        type: payload.type,
        title: payload.title,
        message: payload.body,
        deepLink: payload.deepLink,
        groupKey: payload.groupKey,
        metadata: payload.metadata,
        priority: payload.priority,
        isRead: false,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });
      notifPromises.push(sendPushToUser(farmer.id, payload));
    }

    // Also notify subscribed arhtis
    const arhtis = await db
      .collection("users")
      .where("role", "==", "arhti")
      .where("subscriptionStatus", "==", "active")
      .get();

    for (const arhti of arhtis.docs) {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: arhti.id,
        role: "arhti",
        type: payload.type,
        title: payload.title,
        message: payload.body,
        deepLink: payload.deepLink,
        groupKey: payload.groupKey,
        metadata: payload.metadata,
        priority: payload.priority,
        isRead: false,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });
      notifPromises.push(sendPushToUser(arhti.id, payload));
    }

    await batch.commit();
    await Promise.allSettled(notifPromises);

    console.log(
      `Mandi rate notification sent to ${farmers.size} farmers`
    );

    return null;
  });

// ─────────────────────────────────────────────────
// TRIGGER 5 — NEW CROP POSTED by farmer
// Fires when crop posted → notify subscribed arhtis
// ─────────────────────────────────────────────────
exports.onCropPosted = functions
  .firestore
  .document("crops/{cropId}")
  .onCreate(async (snap, context) => {
    const crop = snap.data();
    const cropId = context.params.cropId;
    const cropType = crop.cropType || "فصل";
    const district = crop.district || "";
    const quantity = crop.quantity || "";
    const price = crop.expectedPrice || 0;

    // Get subscribed arhtis
    const arhtis = await db
      .collection("users")
      .where("role", "==", "arhti")
      .where("subscriptionStatus", "==", "active")
      .get();

    if (arhtis.empty) return null;

    const payload = {
      title: "🌾 نئی فصل دستیاب!",
      body: `${cropType} — ${quantity} من — ${district} سے — PKR ${price}`,
      type: "cropListingPosted",
      channelId: "crops",
      deepLink: "/crops",
      groupKey: "crops",
      priority: "high",
      metadata: {
        cropId: cropId,
        cropType: cropType,
        district: district,
        quantity: quantity.toString(),
        price: price.toString(),
      },
    };

    const batch = db.batch();
    const notifPromises = [];

    for (const arhti of arhtis.docs) {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: arhti.id,
        role: "arhti",
        type: payload.type,
        title: payload.title,
        message: payload.body,
        deepLink: payload.deepLink,
        groupKey: payload.groupKey,
        metadata: payload.metadata,
        priority: payload.priority,
        isRead: false,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });
      notifPromises.push(sendPushToUser(arhti.id, payload));
    }

    await batch.commit();
    await Promise.allSettled(notifPromises);

    return null;
  });

// ─────────────────────────────────────────────────
// TRIGGER 6 — SUBSCRIPTION APPROVED
// Fires when admin approves subscription
// ─────────────────────────────────────────────────
exports.onSubscriptionApproved = functions
  .firestore
  .document("subscriptions/{subId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (
      before.status === after.status ||
      after.status !== "active"
    ) {
      return null;
    }

    const userId = after.userId || "";
    const role = after.role || "user";

    if (!userId) return null;

    const payload = {
      title: " سبسکرپشن منظور!",
      body: "آپ کی ماہانہ سبسکرپشن فعال ہو گئی ہے۔ تمام سہولیات استعمال کریں",
      type: "subscriptionApproved",
      channelId: "subscription",
      deepLink: "/dashboard",
      groupKey: "subscription",
      priority: "high",
    };

    await saveNotification(userId, role, payload);
    await sendPushToUser(userId, payload);

    return null;
  });

// ─────────────────────────────────────────────────
// TRIGGER 7 — NOTIFICATIONS COLLECTION
// Fires when notification added → sends FCM push
// This is the UNIVERSAL trigger for all manual sends
// ─────────────────────────────────────────────────
exports.onNotificationCreated = functions
  .firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const notif = snap.data();

    // Skip if already pushed (to avoid double push)
    if (notif.pushed === true) return null;

    const userId = notif.userId || "";
    if (!userId) return null;

    const payload = {
      title: notif.title || "",
      body: notif.message || "",
      type: notif.type || "general",
      channelId: notif.groupKey || "default",
      deepLink: notif.deepLink || "",
      groupKey: notif.groupKey || "general",
      priority: notif.priority || "normal",
      metadata: notif.metadata || {},
    };

    // Mark as pushed to prevent double send
    await snap.ref.update({ pushed: true });

    await sendPushToUser(userId, payload);

    return null;
  });