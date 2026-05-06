// Auth Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');

// POST /api/auth/register - Create or update user profile after Firebase auth
router.post('/register', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { uid, email, name, picture } = req.user;
    const { displayName, language, churchId } = req.body;

    const existingUser = await db.collection('users').findOne({ firebaseUid: uid });

    if (existingUser) {
      // Update existing user
      const update = {
        $set: {
          displayName: displayName || name || existingUser.displayName,
          email: email || existingUser.email,
          photoUrl: picture || existingUser.photoUrl,
          updatedAt: new Date(),
        },
      };
      if (language) update.$set.language = language;
      if (churchId) update.$set.churchId = churchId;

      await db.collection('users').updateOne({ firebaseUid: uid }, update);
      const updatedUser = await db.collection('users').findOne({ firebaseUid: uid });
      return res.json({ user: sanitizeUser(updatedUser), isNew: false });
    }

    // Create new user
    const newUser = {
      firebaseUid: uid,
      email: email || null,
      displayName: displayName || name || 'Anonymous',
      photoUrl: picture || null,
      language: language || 'en',
      xp: 0,
      level: 'Seeker',
      battleWins: 0,
      battleLosses: 0,
      winStreak: 0,
      bestWinStreak: 0,
      versesMemorized: 0,
      quizzesCompleted: 0,
      totalCorrectAnswers: 0,
      totalAnswers: 0,
      churchId: churchId || null,
      isPastor: false,
      fcmToken: null,
      badges: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await db.collection('users').insertOne(newUser);
    return res.status(201).json({ user: sanitizeUser(newUser), isNew: true });
  } catch (err) {
    console.error('Auth register error:', err);
    return res.status(500).json({ error: 'Failed to register user' });
  }
});

// PUT /api/auth/fcm-token - Update FCM token
router.put('/fcm-token', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    await db.collection('users').updateOne(
      { firebaseUid: req.user.uid },
      { $set: { fcmToken: token, updatedAt: new Date() } }
    );

    return res.json({ success: true });
  } catch (err) {
    console.error('FCM token update error:', err);
    return res.status(500).json({ error: 'Failed to update FCM token' });
  }
});

// PUT /api/auth/church - Join or leave a church
router.put('/church', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { churchId } = req.body;

    await db.collection('users').updateOne(
      { firebaseUid: req.user.uid },
      { $set: { churchId: churchId || null, updatedAt: new Date() } }
    );

    return res.json({ success: true });
  } catch (err) {
    console.error('Church update error:', err);
    return res.status(500).json({ error: 'Failed to update church' });
  }
});

function sanitizeUser(user) {
  const { _id, ...rest } = user;
  return { id: _id.toString(), ...rest };
}

module.exports = router;
