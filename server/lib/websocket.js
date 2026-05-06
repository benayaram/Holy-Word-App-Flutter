// WebSocket Battle Room Manager
const { WebSocketServer } = require('ws');
const { getDB } = require('./db');
const { ObjectId } = require('mongodb');

// Active battle rooms: battleId -> { players: Map<userId, ws>, state }
const battleRooms = new Map();
// User -> battleId mapping for quick lookup
const userBattleMap = new Map();

function initWebSocket(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    let userId = null;

    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });

    ws.on('message', async (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        await handleMessage(ws, msg, () => userId, (id) => { userId = id; });
      } catch (err) {
        ws.send(JSON.stringify({ event: 'error', data: { message: err.message } }));
      }
    });

    ws.on('close', () => {
      if (userId) {
        handleDisconnect(userId);
      }
    });

    ws.on('error', (err) => {
      console.error('WebSocket error:', err.message);
    });
  });

  // Heartbeat: ping every 30s, terminate dead connections
  const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (!ws.isAlive) return ws.terminate();
      ws.isAlive = false;
      ws.ping();
    });
  }, 30000);

  wss.on('close', () => clearInterval(interval));

  console.log('✅ WebSocket server initialized');
  return wss;
}

async function handleMessage(ws, msg, getUserId, setUserId) {
  const { event, data } = msg;

  switch (event) {
    case 'auth': {
      // Client sends Firebase UID after connecting
      setUserId(data.userId);
      ws.send(JSON.stringify({ event: 'auth:success', data: { userId: data.userId } }));
      break;
    }

    case 'battle:join': {
      const userId = getUserId();
      if (!userId) {
        ws.send(JSON.stringify({ event: 'error', data: { message: 'Not authenticated' } }));
        return;
      }

      const { battleId } = data;
      await joinBattleRoom(battleId, userId, ws);
      break;
    }

    case 'battle:answer': {
      const userId = getUserId();
      if (!userId) return;

      const { battleId, questionIndex, answer, timeMs } = data;
      await handleBattleAnswer(battleId, userId, questionIndex, answer, timeMs);
      break;
    }

    case 'battle:ready': {
      const userId = getUserId();
      if (!userId) return;

      const { battleId } = data;
      await handlePlayerReady(battleId, userId);
      break;
    }

    default:
      ws.send(JSON.stringify({ event: 'error', data: { message: `Unknown event: ${event}` } }));
  }
}

async function joinBattleRoom(battleId, userId, ws) {
  const db = getDB();
  const battle = await db.collection('battles').findOne({ _id: new ObjectId(battleId) });

  if (!battle) {
    ws.send(JSON.stringify({ event: 'error', data: { message: 'Battle not found' } }));
    return;
  }

  // Create room if doesn't exist
  if (!battleRooms.has(battleId)) {
    battleRooms.set(battleId, {
      players: new Map(),
      questions: battle.questionIds || [],
      currentQuestion: 0,
      scores: {},
      answers: {},
      readyPlayers: new Set(),
    });
  }

  const room = battleRooms.get(battleId);
  room.players.set(userId, ws);
  room.scores[userId] = 0;
  room.answers[userId] = [];
  userBattleMap.set(userId, battleId);

  // Notify all players in room
  broadcastToRoom(battleId, {
    event: 'battle:player_joined',
    data: {
      userId,
      playerCount: room.players.size,
      playersNeeded: 2,
    },
  });

  // If both players are in, notify ready check
  if (room.players.size === 2) {
    broadcastToRoom(battleId, {
      event: 'battle:ready_check',
      data: { message: 'Both players connected. Send battle:ready when ready.' },
    });
  }
}

async function handlePlayerReady(battleId, userId) {
  const room = battleRooms.get(battleId);
  if (!room) return;

  room.readyPlayers.add(userId);

  if (room.readyPlayers.size === 2) {
    // Both ready — start the battle
    await startBattle(battleId);
  }
}

async function startBattle(battleId) {
  const room = battleRooms.get(battleId);
  if (!room) return;

  const db = getDB();

  // Fetch questions
  const questionIds = room.questions.map(id =>
    typeof id === 'string' ? new ObjectId(id) : id
  );
  const questions = await db.collection('questions').find({
    _id: { $in: questionIds },
  }).toArray();

  room.questionData = questions;
  room.currentQuestion = 0;
  room.startTime = Date.now();

  // Update battle status in DB
  await db.collection('battles').updateOne(
    { _id: new ObjectId(battleId) },
    { $set: { status: 'active', startedAt: new Date() } }
  );

  // Send first question
  sendQuestion(battleId, 0);
}

function sendQuestion(battleId, index) {
  const room = battleRooms.get(battleId);
  if (!room || !room.questionData || index >= room.questionData.length) {
    // All questions done
    endBattle(battleId);
    return;
  }

  const q = room.questionData[index];
  room.currentQuestion = index;
  room.questionStartTime = Date.now();

  // Clear answer tracking for this question
  room.currentAnswers = new Set();

  const timeLimit = q.type === 'true_false' ? 6000 : 15000;

  broadcastToRoom(battleId, {
    event: 'battle:question',
    data: {
      questionIndex: index,
      totalQuestions: room.questionData.length,
      type: q.type,
      questionEn: q.questionEn,
      questionTe: q.questionTe,
      options: q.options,
      optionsTe: q.optionsTe,
      timeLimit,
    },
  });

  // Auto-advance if time expires
  room.questionTimer = setTimeout(() => {
    // Mark unanswered players as wrong
    room.players.forEach((ws, playerId) => {
      if (!room.currentAnswers.has(playerId)) {
        room.answers[playerId].push({
          questionIndex: index,
          answer: -1,
          correct: false,
          timeMs: timeLimit,
        });
      }
    });

    broadcastToRoom(battleId, {
      event: 'battle:time_up',
      data: {
        questionIndex: index,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        explanationTe: q.explanationTe,
        scores: room.scores,
      },
    });

    // Next question after 3s delay
    setTimeout(() => sendQuestion(battleId, index + 1), 3000);
  }, timeLimit);
}

async function handleBattleAnswer(battleId, userId, questionIndex, answer, timeMs) {
  const room = battleRooms.get(battleId);
  if (!room || !room.questionData) return;

  // Prevent double answering
  if (room.currentAnswers.has(userId)) return;
  room.currentAnswers.add(userId);

  const q = room.questionData[questionIndex];
  const correct = answer === q.correctAnswer;

  if (correct) {
    // Bonus points for speed: max 10 points, faster = more
    const timeLimit = q.type === 'true_false' ? 6000 : 15000;
    const speedBonus = Math.max(0, Math.floor((1 - timeMs / timeLimit) * 5));
    room.scores[userId] += 10 + speedBonus;
  }

  room.answers[userId].push({
    questionIndex,
    answer,
    correct,
    timeMs,
  });

  // Notify opponent that this player answered
  room.players.forEach((ws, playerId) => {
    if (playerId !== userId) {
      ws.send(JSON.stringify({
        event: 'battle:opponent_answered',
        data: { questionIndex, correct, timeMs },
      }));
    }
  });

  // Send score update to answering player
  const playerWs = room.players.get(userId);
  if (playerWs) {
    playerWs.send(JSON.stringify({
      event: 'battle:answer_result',
      data: {
        questionIndex,
        correct,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        explanationTe: q.explanationTe,
        scores: room.scores,
      },
    }));
  }

  // If both players answered, advance immediately
  if (room.currentAnswers.size >= room.players.size) {
    clearTimeout(room.questionTimer);

    broadcastToRoom(battleId, {
      event: 'battle:score_update',
      data: { scores: room.scores },
    });

    // Next question after 2s
    setTimeout(() => sendQuestion(battleId, questionIndex + 1), 2000);
  }
}

async function endBattle(battleId) {
  const room = battleRooms.get(battleId);
  if (!room) return;

  const db = getDB();
  const playerIds = Array.from(room.players.keys());

  // Determine winner
  let winnerId = null;
  if (playerIds.length === 2) {
    const [p1, p2] = playerIds;
    if (room.scores[p1] > room.scores[p2]) winnerId = p1;
    else if (room.scores[p2] > room.scores[p1]) winnerId = p2;
    // else tie — winnerId stays null
  }

  // Calculate XP earned
  const xpEarned = {};
  playerIds.forEach((pid) => {
    let xp = 0;
    const answers = room.answers[pid] || [];
    xp += answers.filter(a => a.correct).length * 10; // 10 XP per correct
    if (pid === winnerId) xp += 50; // Win bonus
    xpEarned[pid] = xp;
  });

  // Update battle in DB
  const updateData = {
    status: 'completed',
    winnerId,
    completedAt: new Date(),
  };

  // Add player answers
  if (playerIds[0]) {
    updateData.player1Score = room.scores[playerIds[0]] || 0;
    updateData.player1Answers = room.answers[playerIds[0]] || [];
  }
  if (playerIds[1]) {
    updateData.player2Score = room.scores[playerIds[1]] || 0;
    updateData.player2Answers = room.answers[playerIds[1]] || [];
  }

  await db.collection('battles').updateOne(
    { _id: new ObjectId(battleId) },
    { $set: updateData }
  );

  // Update user stats + XP
  for (const pid of playerIds) {
    const isWinner = pid === winnerId;
    const update = {
      $inc: {
        xp: xpEarned[pid],
        battleWins: isWinner ? 1 : 0,
        battleLosses: isWinner ? 0 : (winnerId ? 1 : 0),
      },
    };

    if (isWinner) {
      update.$inc.winStreak = 1;
    } else if (winnerId) {
      update.$set = { winStreak: 0 };
    }

    await db.collection('users').updateOne({ firebaseUid: pid }, update);

    // Update level based on new XP
    const user = await db.collection('users').findOne({ firebaseUid: pid });
    if (user) {
      const newLevel = calculateLevel(user.xp + xpEarned[pid], user.versesMemorized || 0);
      await db.collection('users').updateOne(
        { firebaseUid: pid },
        { $set: { level: newLevel } }
      );
    }
  }

  // Broadcast results
  broadcastToRoom(battleId, {
    event: 'battle:complete',
    data: {
      winnerId,
      scores: room.scores,
      xpEarned,
      answers: room.answers,
    },
  });

  // Cleanup room after 10s
  setTimeout(() => {
    battleRooms.delete(battleId);
    playerIds.forEach(pid => userBattleMap.delete(pid));
  }, 10000);
}

function handleDisconnect(userId) {
  const battleId = userBattleMap.get(userId);
  if (!battleId) return;

  const room = battleRooms.get(battleId);
  if (!room) return;

  room.players.delete(userId);

  // Notify remaining player
  broadcastToRoom(battleId, {
    event: 'battle:player_disconnected',
    data: { userId, message: 'Opponent disconnected' },
  });

  // If no players left, cleanup
  if (room.players.size === 0) {
    clearTimeout(room.questionTimer);
    battleRooms.delete(battleId);
  }

  userBattleMap.delete(userId);
}

function broadcastToRoom(battleId, message) {
  const room = battleRooms.get(battleId);
  if (!room) return;

  const payload = JSON.stringify(message);
  room.players.forEach((ws) => {
    if (ws.readyState === 1) { // WebSocket.OPEN
      ws.send(payload);
    }
  });
}

function calculateLevel(xp, versesMemorized) {
  if (versesMemorized >= 365) return 'Living Word';
  if (xp >= 5000) return 'Apostle';
  if (xp >= 2000) return 'Elder';
  if (xp >= 500) return 'Disciple';
  return 'Seeker';
}

module.exports = { initWebSocket, battleRooms };
