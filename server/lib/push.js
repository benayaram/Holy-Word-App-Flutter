// FCM Push Notification Service
const admin = require('firebase-admin');
const { getDB } = require('./db');

/**
 * Send push notification to a specific user
 */
async function sendToUser(userId, title, body, data = {}) {
  try {
    const db = getDB();
    const user = await db.collection('users').findOne({ firebaseUid: userId });

    if (!user || !user.fcmToken) {
      console.warn(`No FCM token for user ${userId}`);
      return false;
    }

    const message = {
      token: user.fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'arena_channel',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ Push sent to ${userId}: ${response}`);
    return true;
  } catch (err) {
    if (err.code === 'messaging/registration-token-not-registered') {
      // Token expired, remove it
      const db = getDB();
      await db.collection('users').updateOne(
        { firebaseUid: userId },
        { $set: { fcmToken: null } }
      );
      console.warn(`Removed expired FCM token for ${userId}`);
    } else {
      console.error(`❌ Push failed for ${userId}:`, err.message);
    }
    return false;
  }
}

/**
 * Send push notification to multiple users (e.g., church members)
 */
async function sendToMultiple(userIds, title, body, data = {}) {
  const db = getDB();
  const users = await db.collection('users').find({
    firebaseUid: { $in: userIds },
    fcmToken: { $ne: null },
  }).toArray();

  const tokens = users.map(u => u.fcmToken).filter(Boolean);

  if (tokens.length === 0) {
    console.warn('No valid FCM tokens found');
    return { success: 0, failure: 0 };
  }

  const message = {
    notification: { title, body },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'arena_channel',
        sound: 'default',
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...message,
    });

    console.log(`✅ Multicast: ${response.successCount} sent, ${response.failureCount} failed`);

    // Clean up expired tokens
    response.responses.forEach((resp, idx) => {
      if (resp.error && resp.error.code === 'messaging/registration-token-not-registered') {
        db.collection('users').updateOne(
          { fcmToken: tokens[idx] },
          { $set: { fcmToken: null } }
        );
      }
    });

    return { success: response.successCount, failure: response.failureCount };
  } catch (err) {
    console.error('❌ Multicast push failed:', err.message);
    return { success: 0, failure: tokens.length };
  }
}

/**
 * Send to all members of a church
 */
async function sendToChurch(churchId, title, body, data = {}, excludeUserId = null) {
  const db = getDB();
  const query = { churchId, fcmToken: { $ne: null } };
  if (excludeUserId) {
    query.firebaseUid = { $ne: excludeUserId };
  }

  const users = await db.collection('users').find(query).toArray();
  const userIds = users.map(u => u.firebaseUid);

  if (userIds.length === 0) return { success: 0, failure: 0 };

  return sendToMultiple(userIds, title, body, data);
}

module.exports = { sendToUser, sendToMultiple, sendToChurch };
