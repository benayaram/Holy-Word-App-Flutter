// User Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');

// GET /api/users/me - Get current user profile + stats
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });

    if (!user) {
      return res.status(404).json({ error: 'User not found. Please register first.' });
    }

    // Compute additional stats
    const battleCount = await db.collection('battles').countDocuments({
      $or: [{ player1Id: req.user.uid }, { player2Id: req.user.uid }],
      status: 'completed',
    });

    const memoryProgress = await db.collection('memory_progress').find({
      userId: req.user.uid,
    }).toArray();

    const versesAtLevel5 = memoryProgress.filter(m => m.currentLevel >= 5).length;

    const { _id, ...userData } = user;
    return res.json({
      user: {
        id: _id.toString(),
        ...userData,
        stats: {
          totalBattles: battleCount,
          versesInProgress: memoryProgress.length,
          versesFullyMemorized: versesAtLevel5,
          accuracy: user.totalAnswers > 0
            ? Math.round((user.totalCorrectAnswers / user.totalAnswers) * 100)
            : 0,
        },
      },
    });
  } catch (err) {
    console.error('Get user error:', err);
    return res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// GET /api/users/leaderboard - Global and church leaderboards
router.get('/leaderboard', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { type = 'global', churchId, limit = 20 } = req.query;

    let query = {};
    if (type === 'church' && churchId) {
      query.churchId = churchId;
    }

    const users = await db.collection('users')
      .find(query)
      .sort({ xp: -1 })
      .limit(parseInt(limit))
      .project({
        firebaseUid: 1,
        displayName: 1,
        photoUrl: 1,
        xp: 1,
        level: 1,
        battleWins: 1,
        winStreak: 1,
        versesMemorized: 1,
      })
      .toArray();

    // Find current user rank
    const currentUserXp = await db.collection('users').findOne(
      { firebaseUid: req.user.uid },
      { projection: { xp: 1 } }
    );

    let rank = 0;
    if (currentUserXp) {
      rank = await db.collection('users').countDocuments({
        ...query,
        xp: { $gt: currentUserXp.xp },
      }) + 1;
    }

    return res.json({
      leaderboard: users.map((u, idx) => ({
        rank: idx + 1,
        userId: u.firebaseUid,
        displayName: u.displayName,
        photoUrl: u.photoUrl,
        xp: u.xp,
        level: u.level,
        battleWins: u.battleWins,
        winStreak: u.winStreak,
        versesMemorized: u.versesMemorized,
      })),
      currentUserRank: rank,
    });
  } catch (err) {
    console.error('Leaderboard error:', err);
    return res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

// GET /api/users/profile/:userId - Get another user's public profile
router.get('/profile/:userId', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const user = await db.collection('users').findOne(
      { firebaseUid: req.params.userId },
      {
        projection: {
          firebaseUid: 1,
          displayName: 1,
          photoUrl: 1,
          xp: 1,
          level: 1,
          battleWins: 1,
          battleLosses: 1,
          winStreak: 1,
          bestWinStreak: 1,
          versesMemorized: 1,
          badges: 1,
          createdAt: 1,
        },
      }
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const { _id, ...userData } = user;
    return res.json({ user: { id: _id.toString(), ...userData } });
  } catch (err) {
    console.error('Profile error:', err);
    return res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

module.exports = router;
