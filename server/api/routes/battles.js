// Battle Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');
const { sendToUser } = require('../../lib/push');
const { ObjectId } = require('mongodb');
const { v4: uuidv4 } = require('uuid');

// POST /api/battles/create - Create a new battle
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { type = 'friend', category, difficulty = 'normal' } = req.body;

    // Fetch 10 random questions for the battle
    const query = { difficulty };
    if (category) query.category = category;

    const questions = await db.collection('questions')
      .aggregate([{ $match: query }, { $sample: { size: 10 } }])
      .toArray();

    if (questions.length < 5) {
      return res.status(400).json({ error: 'Not enough questions available for this category/difficulty' });
    }

    const inviteCode = uuidv4().substring(0, 8).toUpperCase();

    const battle = {
      type,
      status: 'waiting',
      player1Id: req.user.uid,
      player2Id: null,
      questionIds: questions.map(q => q._id),
      player1Answers: [],
      player2Answers: [],
      player1Score: 0,
      player2Score: 0,
      winnerId: null,
      inviteCode,
      category: category || 'mixed',
      difficulty,
      createdAt: new Date(),
      completedAt: null,
    };

    const result = await db.collection('battles').insertOne(battle);

    return res.status(201).json({
      battleId: result.insertedId.toString(),
      inviteCode,
      type,
      questionCount: questions.length,
      shareLink: `holyword://arena/battle/${inviteCode}`,
    });
  } catch (err) {
    console.error('Create battle error:', err);
    return res.status(500).json({ error: 'Failed to create battle' });
  }
});

// POST /api/battles/join - Join a battle by invite code
router.post('/join', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { inviteCode } = req.body;

    if (!inviteCode) return res.status(400).json({ error: 'inviteCode required' });

    const battle = await db.collection('battles').findOne({
      inviteCode: inviteCode.toUpperCase(),
      status: 'waiting',
    });

    if (!battle) return res.status(404).json({ error: 'Battle not found or already started' });
    if (battle.player1Id === req.user.uid)
      return res.status(400).json({ error: 'Cannot join your own battle' });

    await db.collection('battles').updateOne(
      { _id: battle._id },
      { $set: { player2Id: req.user.uid, status: 'active', updatedAt: new Date() } }
    );

    // Notify player 1
    const player1 = await db.collection('users').findOne({ firebaseUid: battle.player1Id });
    const joiner = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (player1) {
      await sendToUser(battle.player1Id,
        '⚔️ Battle Accepted!',
        `${joiner?.displayName || 'Someone'} accepted your Bible Trivia challenge!`,
        { type: 'battle_joined', battleId: battle._id.toString() }
      );
    }

    return res.json({
      battleId: battle._id.toString(),
      opponent: { displayName: player1?.displayName, photoUrl: player1?.photoUrl },
      questionCount: battle.questionIds.length,
    });
  } catch (err) {
    console.error('Join battle error:', err);
    return res.status(500).json({ error: 'Failed to join battle' });
  }
});

// POST /api/battles/matchmake - Find a random opponent
router.post('/matchmake', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { category, difficulty = 'normal' } = req.body;

    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Look for existing waiting battle from another player at similar level
    const xpRange = Math.max(100, user.xp * 0.2);
    const waitingBattle = await db.collection('battles').findOne({
      type: 'random',
      status: 'waiting',
      player1Id: { $ne: req.user.uid },
      difficulty,
    });

    if (waitingBattle) {
      // Join existing battle
      await db.collection('battles').updateOne(
        { _id: waitingBattle._id },
        { $set: { player2Id: req.user.uid, status: 'active', updatedAt: new Date() } }
      );

      const opponent = await db.collection('users').findOne({ firebaseUid: waitingBattle.player1Id });
      await sendToUser(waitingBattle.player1Id,
        '⚔️ Opponent Found!',
        `A worthy challenger has appeared! Battle starting now.`,
        { type: 'battle_matched', battleId: waitingBattle._id.toString() }
      );

      return res.json({
        battleId: waitingBattle._id.toString(),
        matched: true,
        opponent: { displayName: opponent?.displayName, photoUrl: opponent?.photoUrl, level: opponent?.level },
      });
    }

    // No match — create a new waiting battle
    const query = { difficulty };
    if (category) query.category = category;
    const questions = await db.collection('questions')
      .aggregate([{ $match: query }, { $sample: { size: 10 } }]).toArray();

    const inviteCode = uuidv4().substring(0, 8).toUpperCase();
    const battle = {
      type: 'random', status: 'waiting', player1Id: req.user.uid, player2Id: null,
      questionIds: questions.map(q => q._id), player1Answers: [], player2Answers: [],
      player1Score: 0, player2Score: 0, winnerId: null, inviteCode,
      category: category || 'mixed', difficulty, createdAt: new Date(), completedAt: null,
    };

    const result = await db.collection('battles').insertOne(battle);

    return res.json({
      battleId: result.insertedId.toString(),
      matched: false,
      message: 'Waiting for opponent...',
    });
  } catch (err) {
    console.error('Matchmake error:', err);
    return res.status(500).json({ error: 'Matchmaking failed' });
  }
});

// GET /api/battles/:id - Get battle state
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const battle = await db.collection('battles').findOne({ _id: new ObjectId(req.params.id) });
    if (!battle) return res.status(404).json({ error: 'Battle not found' });

    // Get player names
    const p1 = await db.collection('users').findOne({ firebaseUid: battle.player1Id },
      { projection: { displayName: 1, photoUrl: 1, level: 1 } });
    const p2 = battle.player2Id
      ? await db.collection('users').findOne({ firebaseUid: battle.player2Id },
        { projection: { displayName: 1, photoUrl: 1, level: 1 } })
      : null;

    return res.json({
      battle: {
        id: battle._id.toString(), type: battle.type, status: battle.status,
        player1: { id: battle.player1Id, ...(p1 || {}) },
        player2: battle.player2Id ? { id: battle.player2Id, ...(p2 || {}) } : null,
        player1Score: battle.player1Score, player2Score: battle.player2Score,
        winnerId: battle.winnerId, inviteCode: battle.inviteCode,
        questionCount: battle.questionIds.length,
        category: battle.category, difficulty: battle.difficulty,
        createdAt: battle.createdAt, completedAt: battle.completedAt,
      },
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch battle' });
  }
});

// GET /api/battles/history - Get user's battle history
router.get('/', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { limit = 20, offset = 0 } = req.query;
    const battles = await db.collection('battles').find({
      $or: [{ player1Id: req.user.uid }, { player2Id: req.user.uid }],
      status: 'completed',
    }).sort({ completedAt: -1 }).skip(parseInt(offset)).limit(parseInt(limit)).toArray();

    return res.json({ battles: battles.map(b => ({
      id: b._id.toString(), type: b.type, winnerId: b.winnerId,
      player1Score: b.player1Score, player2Score: b.player2Score,
      isWinner: b.winnerId === req.user.uid, completedAt: b.completedAt,
    })) });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch history' });
  }
});

module.exports = router;
