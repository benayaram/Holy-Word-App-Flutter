// Tournament Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');
const { sendToChurch } = require('../../lib/push');
const { ObjectId } = require('mongodb');

// POST /api/tournaments/create - Pastor creates tournament
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { name, churchId } = req.body;
    if (!name || !churchId) return res.status(400).json({ error: 'name and churchId required' });

    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (!user?.isPastor) return res.status(403).json({ error: 'Only pastors can create tournaments' });

    // Generate 6-character code
    const code = Math.random().toString(36).substring(2, 8).toUpperCase();

    const tournament = {
      churchId, name, code, createdBy: req.user.uid,
      participants: [req.user.uid],
      brackets: [], status: 'registration',
      winnerId: null, createdAt: new Date(),
    };

    const result = await db.collection('tournaments').insertOne(tournament);

    // Notify church members
    await sendToChurch(churchId, '🏆 Tournament Created!',
      `${name} — Join with code: ${code}`,
      { type: 'tournament_created', tournamentId: result.insertedId.toString(), code },
      req.user.uid
    );

    return res.status(201).json({ tournamentId: result.insertedId.toString(), code });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to create tournament' });
  }
});

// POST /api/tournaments/:code/join
router.post('/:code/join', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const tournament = await db.collection('tournaments').findOne({
      code: req.params.code.toUpperCase(), status: 'registration',
    });
    if (!tournament) return res.status(404).json({ error: 'Tournament not found or registration closed' });

    if (tournament.participants.includes(req.user.uid))
      return res.status(400).json({ error: 'Already registered' });

    await db.collection('tournaments').updateOne(
      { _id: tournament._id },
      { $push: { participants: req.user.uid } }
    );

    return res.json({ success: true, participantCount: tournament.participants.length + 1 });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to join tournament' });
  }
});

// POST /api/tournaments/:id/start - Start the tournament (generate brackets)
router.post('/:id/start', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const tournament = await db.collection('tournaments').findOne({ _id: new ObjectId(req.params.id) });
    if (!tournament) return res.status(404).json({ error: 'Tournament not found' });
    if (tournament.createdBy !== req.user.uid) return res.status(403).json({ error: 'Only creator can start' });
    if (tournament.participants.length < 2) return res.status(400).json({ error: 'Need at least 2 participants' });

    // Shuffle participants
    const shuffled = [...tournament.participants].sort(() => Math.random() - 0.5);

    // Generate bracket matches for round 1
    const matches = [];
    for (let i = 0; i < shuffled.length; i += 2) {
      matches.push({
        matchId: new ObjectId().toString(),
        player1: shuffled[i],
        player2: shuffled[i + 1] || null, // Bye if odd
        winnerId: shuffled[i + 1] ? null : shuffled[i], // Auto-win for bye
        battleId: null,
      });
    }

    const brackets = [{ round: 1, roundName: getRoundName(shuffled.length, 1), matches }];

    await db.collection('tournaments').updateOne(
      { _id: tournament._id },
      { $set: { brackets, status: 'active', startedAt: new Date() } }
    );

    await sendToChurch(tournament.churchId, '🏆 Tournament Started!',
      `${tournament.name} has begun! Check your first match.`,
      { type: 'tournament_started', tournamentId: tournament._id.toString() }
    );

    return res.json({ brackets });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to start tournament' });
  }
});

// POST /api/tournaments/:id/advance - Report match result and advance bracket
router.post('/:id/advance', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { matchId, winnerId } = req.body;
    if (!matchId || !winnerId) {
      return res.status(400).json({ error: 'matchId and winnerId are required' });
    }

    // Atomically set the winner on the specific match
    const updateResult = await db.collection('tournaments').updateOne(
      { _id: new ObjectId(req.params.id), 'brackets.matches.matchId': matchId },
      { $set: { 'brackets.$[round].matches.$[match].winnerId': winnerId } },
      { arrayFilters: [{ 'round.matches.matchId': matchId }, { 'match.matchId': matchId }] }
    );

    if (updateResult.matchedCount === 0) {
      return res.status(404).json({ error: 'Tournament or match not found' });
    }

    // Re-fetch to check if round is complete
    const tournament = await db.collection('tournaments').findOne({ _id: new ObjectId(req.params.id) });
    if (!tournament) return res.status(404).json({ error: 'Tournament not found' });

    const currentRound = tournament.brackets[tournament.brackets.length - 1];
    const allComplete = currentRound.matches.every(m => m.winnerId);

    if (allComplete) {
      const winners = currentRound.matches.map(m => m.winnerId).filter(Boolean);

      if (winners.length === 1) {
        // Tournament complete
        await db.collection('tournaments').updateOne(
          { _id: tournament._id },
          { $set: { winnerId: winners[0], status: 'completed', completedAt: new Date() } }
        );

        // Award XP to winner
        await db.collection('users').updateOne(
          { firebaseUid: winners[0] },
          { $inc: { xp: 100 }, $push: { badges: { type: 'tournament_champion', name: tournament.name, date: new Date() } } }
        );
      } else {
        // Generate next round
        const nextMatches = [];
        for (let i = 0; i < winners.length; i += 2) {
          nextMatches.push({
            matchId: new ObjectId().toString(),
            player1: winners[i],
            player2: winners[i + 1] || null,
            winnerId: winners[i + 1] ? null : winners[i],
            battleId: null,
          });
        }
        const nextRoundNum = tournament.brackets.length + 1;
        await db.collection('tournaments').updateOne(
          { _id: tournament._id },
          { $push: { brackets: { round: nextRoundNum, roundName: getRoundName(tournament.participants.length, nextRoundNum), matches: nextMatches } } }
        );
      }
    }

    // Return updated state
    const updated = await db.collection('tournaments').findOne({ _id: new ObjectId(req.params.id) });
    return res.json({ brackets: updated.brackets, status: updated.status, winnerId: updated.winnerId });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to advance tournament' });
  }
});

// GET /api/tournaments/:id
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const tournament = await db.collection('tournaments').findOne({ _id: new ObjectId(req.params.id) });
    if (!tournament) return res.status(404).json({ error: 'Tournament not found' });

    // Resolve participant names
    const userIds = tournament.participants;
    const users = await db.collection('users').find({ firebaseUid: { $in: userIds } },
      { projection: { firebaseUid: 1, displayName: 1, photoUrl: 1, level: 1 } }).toArray();
    const userMap = {}; users.forEach(u => { userMap[u.firebaseUid] = u; });

    return res.json({ tournament: { ...tournament, id: tournament._id.toString(), participantDetails: userMap } });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch tournament' });
  }
});

function getRoundName(totalPlayers, round) {
  const remaining = totalPlayers / Math.pow(2, round - 1);
  if (remaining <= 2) return 'Final';
  if (remaining <= 4) return 'Semifinal';
  if (remaining <= 8) return 'Quarterfinal';
  return `Round ${round}`;
}

module.exports = router;
