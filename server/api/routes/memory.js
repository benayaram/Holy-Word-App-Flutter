// Memory Progress Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');

// GET /api/memory/progress - Get all memory verse progress for current user
router.get('/progress', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const progress = await db.collection('memory_progress').find({
      userId: req.user.uid,
    }).sort({ updatedAt: -1 }).toArray();

    return res.json({
      verses: progress.map(p => ({
        id: p._id.toString(),
        bookId: p.bookId, chapter: p.chapter, verse: p.verse,
        reference: p.reference, verseText: p.verseText,
        currentLevel: p.currentLevel,
        completedLevels: p.completedLevels,
        bestTimeMs: p.bestTimeMs,
        language: p.language,
        createdAt: p.createdAt, updatedAt: p.updatedAt,
      })),
      totalVerses: progress.length,
      fullyMemorized: progress.filter(p => p.currentLevel >= 5).length,
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch progress' });
  }
});

// POST /api/memory/progress - Save or update memory level completion
router.post('/progress', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { bookId, chapter, verse, reference, verseText, level, timeMs, language = 'en' } = req.body;

    if (!bookId || !chapter || !verse || !level) {
      return res.status(400).json({ error: 'bookId, chapter, verse, and level are required' });
    }

    const existing = await db.collection('memory_progress').findOne({
      userId: req.user.uid, bookId, chapter, verse,
    });

    if (existing) {
      // Update existing progress
      const update = {
        $set: { currentLevel: Math.max(existing.currentLevel, level), updatedAt: new Date() },
        $addToSet: { completedLevels: level },
      };

      // Update best time for level 5 only
      if (level === 5 && timeMs) {
        if (!existing.bestTimeMs || timeMs < existing.bestTimeMs) {
          update.$set.bestTimeMs = timeMs;
        }
      }

      await db.collection('memory_progress').updateOne({ _id: existing._id }, update);
    } else {
      // Create new entry
      await db.collection('memory_progress').insertOne({
        userId: req.user.uid,
        bookId, chapter, verse, reference: reference || '',
        verseText: verseText || '',
        currentLevel: level,
        completedLevels: [level],
        bestTimeMs: level === 5 ? timeMs : null,
        language,
        createdAt: new Date(), updatedAt: new Date(),
      });
    }

    // Update user's versesMemorized count
    const fullyMemorized = await db.collection('memory_progress').countDocuments({
      userId: req.user.uid, currentLevel: { $gte: 5 },
    });

    const xpEarned = 25; // 25 XP per level completed
    await db.collection('users').updateOne(
      { firebaseUid: req.user.uid },
      {
        $set: { versesMemorized: fullyMemorized, updatedAt: new Date() },
        $inc: { xp: xpEarned },
      }
    );

    // Check level update
    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (user) {
      let newLevel = 'Seeker';
      if (fullyMemorized >= 365) newLevel = 'Living Word';
      else if (user.xp >= 5000) newLevel = 'Apostle';
      else if (user.xp >= 2000) newLevel = 'Elder';
      else if (user.xp >= 500) newLevel = 'Disciple';

      if (newLevel !== user.level) {
        await db.collection('users').updateOne(
          { firebaseUid: req.user.uid },
          { $set: { level: newLevel } }
        );
      }
    }

    // Check verse milestones and award badges
    const milestoneBadges = [10, 50, 100, 365];
    for (const milestone of milestoneBadges) {
      if (fullyMemorized >= milestone) {
        const hasBadge = user?.badges?.some(b => b.type === `verses_${milestone}`);
        if (!hasBadge) {
          await db.collection('users').updateOne(
            { firebaseUid: req.user.uid },
            { $push: { badges: { type: `verses_${milestone}`, name: `${milestone} Verses Memorized`, date: new Date() } } }
          );
        }
      }
    }

    return res.json({ success: true, xpEarned, versesMemorized: fullyMemorized });
  } catch (err) {
    console.error('Save memory progress error:', err);
    return res.status(500).json({ error: 'Failed to save progress' });
  }
});

// DELETE /api/memory/progress/:id - Remove a verse from memory practice
router.delete('/progress/:id', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { ObjectId } = require('mongodb');
    await db.collection('memory_progress').deleteOne({
      _id: new ObjectId(req.params.id), userId: req.user.uid,
    });
    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to delete progress' });
  }
});

// GET /api/memory/leaderboard - Memory verse leaderboard
router.get('/leaderboard', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { churchId, limit = 20 } = req.query;

    const query = {};
    if (churchId) query.churchId = churchId;

    const users = await db.collection('users').find(query)
      .sort({ versesMemorized: -1 })
      .limit(parseInt(limit))
      .project({ firebaseUid: 1, displayName: 1, photoUrl: 1, versesMemorized: 1, level: 1 })
      .toArray();

    return res.json({
      leaderboard: users.map((u, idx) => ({
        rank: idx + 1, userId: u.firebaseUid,
        displayName: u.displayName, photoUrl: u.photoUrl,
        versesMemorized: u.versesMemorized, level: u.level,
      })),
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

module.exports = router;
