// Sermon Notes Challenge Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');
const { sendToChurch } = require('../../lib/push');
const { generateSermonQuestions } = require('../../lib/ai');
const { ObjectId } = require('mongodb');

// POST /api/sermons/create - Pastor creates a sermon quiz
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { title, keyPoints, churchId, language = 'en' } = req.body;

    if (!title || !keyPoints || !churchId) {
      return res.status(400).json({ error: 'title, keyPoints, and churchId are required' });
    }

    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (!user?.isPastor) {
      return res.status(403).json({ error: 'Only pastors can create sermon quizzes' });
    }

    // Generate quiz questions from key points using Gemini AI or use custom user questions
    let questions = [];
    if (req.body.questions && Array.isArray(req.body.questions) && req.body.questions.length > 0) {
      questions = req.body.questions;
    } else {
      try {
        questions = await generateSermonQuestions(keyPoints, title, language);
      } catch (aiErr) {
        console.error('AI sermon question gen failed, using key points as fallback:', aiErr.message);
        // Fallback: create simple questions from key points
        questions = keyPoints.map((point, idx) => ({
          question: `What was key point #${idx + 1} of the sermon "${title}"?`,
          questionTe: `"${title}" ప్రసంగంలో #${idx + 1} ముఖ్య అంశం ఏమిటి?`,
          options: [point, 'Not mentioned', 'Something else', 'None of the above'],
          optionsTe: [point, 'ప్రస్తావించలేదు', 'మరొకటి', 'పైవేవీ కావు'],
          correctAnswer: 0,
          keyPointIndex: idx,
        }));
      }
    }

    const sermonQuiz = {
      churchId,
      pastorId: req.user.uid,
      title,
      keyPoints,
      questions,
      completedBy: [],
      language,
      createdAt: new Date(),
      notificationSentAt: null,
    };

    const result = await db.collection('sermon_quizzes').insertOne(sermonQuiz);

    // Auto-send notifications to church members
    try {
      const pushResult = await sendToChurch(
        churchId,
        '📖 New Sermon Notes Available!',
        `New Sermon Notes posted by Pastor ${user.displayName} for ${churchId}`,
        { type: 'sermon_quiz', sermonQuizId: result.insertedId.toString() },
        req.user.uid
      );
      if (pushResult && pushResult.success > 0) {
        sermonQuiz.notificationSentAt = new Date();
        await db.collection('sermon_quizzes').updateOne(
          { _id: result.insertedId },
          { $set: { notificationSentAt: sermonQuiz.notificationSentAt } }
        );
      }
      console.log(`Auto-sent notification to ${pushResult.success} members`);
    } catch (pushErr) {
      console.error('Failed to auto-send push notification:', pushErr.message);
    }

    return res.status(201).json({
      sermonQuizId: result.insertedId.toString(),
      questionCount: questions.length,
    });
  } catch (err) {
    console.error('Create sermon quiz error:', err);
    return res.status(500).json({ error: 'Failed to create sermon quiz' });
  }
});

// POST /api/sermons/:id/notify - Send push notification to church members
router.post('/:id/notify', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const quiz = await db.collection('sermon_quizzes').findOne({ _id: new ObjectId(req.params.id) });
    if (!quiz) return res.status(404).json({ error: 'Sermon quiz not found' });
    if (quiz.pastorId !== req.user.uid) return res.status(403).json({ error: 'Only the creator can send notifications' });

    const result = await sendToChurch(
      quiz.churchId,
      '📖 Sermon Quiz Available!',
      `Test your memory from "${quiz.title}" — Can you remember the key points?`,
      { type: 'sermon_quiz', sermonQuizId: req.params.id },
      req.user.uid
    );

    await db.collection('sermon_quizzes').updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: { notificationSentAt: new Date() } }
    );

    return res.json({ success: true, notificationsSent: result.success });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to send notifications' });
  }
});

// GET /api/sermons/pending - Get unanswered sermon quizzes for current user
router.get('/pending', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    
    const churchIds = user?.churchIds || (user?.churchId ? [user.churchId] : []);
    if (churchIds.length === 0) return res.json({ quizzes: [] });

    const quizzes = await db.collection('sermon_quizzes').find({
      churchId: { $in: churchIds },
      'completedBy.userId': { $ne: req.user.uid },
    }).sort({ createdAt: -1 }).limit(20).toArray();

    return res.json({
      quizzes: quizzes.map(q => ({
        id: q._id.toString(),
        title: q.title,
        keyPointCount: q.keyPoints.length,
        questionCount: q.questions.length,
        completedCount: q.completedBy.length,
        createdAt: q.createdAt,
      })),
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch pending quizzes' });
  }
});

// GET /api/sermons/:id - Get sermon quiz with questions
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const quiz = await db.collection('sermon_quizzes').findOne({ _id: new ObjectId(req.params.id) });
    if (!quiz) return res.status(404).json({ error: 'Sermon quiz not found' });

    // Check if user already completed
    const completed = quiz.completedBy.find(c => c.userId === req.user.uid);

    return res.json({
      quiz: {
        id: quiz._id.toString(), title: quiz.title,
        keyPoints: quiz.keyPoints,
        questions: quiz.questions.map(q => ({
          question: q.question, questionTe: q.questionTe,
          options: q.options, optionsTe: q.optionsTe,
          // Only include answers if already completed
          ...(completed ? { correctAnswer: q.correctAnswer } : {}),
        })),
        completedCount: quiz.completedBy.length,
        userCompleted: !!completed,
        userScore: completed?.score || null,
        createdAt: quiz.createdAt,
      },
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch sermon quiz' });
  }
});

// POST /api/sermons/:id/submit - Submit sermon quiz answers
router.post('/:id/submit', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { answers } = req.body; // [answerIndex, ...]
    if (!answers || !Array.isArray(answers))
      return res.status(400).json({ error: 'answers array required' });

    // Reject unanswered questions (placeholder value -1)
    if (answers.some(a => a === -1 || a === null || a === undefined))
      return res.status(400).json({ error: 'All questions must be answered' });

    const quiz = await db.collection('sermon_quizzes').findOne({ _id: new ObjectId(req.params.id) });
    if (!quiz) return res.status(404).json({ error: 'Sermon quiz not found' });

    // Check if already completed
    if (quiz.completedBy.find(c => c.userId === req.user.uid))
      return res.status(400).json({ error: 'Already completed this quiz' });

    // Score the answers
    let correct = 0;
    const results = quiz.questions.map((q, idx) => {
      const isCorrect = answers[idx] === q.correctAnswer;
      if (isCorrect) correct++;
      return { correct: isCorrect, correctAnswer: q.correctAnswer };
    });

    // Save completion
    await db.collection('sermon_quizzes').updateOne(
      { _id: new ObjectId(req.params.id) },
      { $push: { completedBy: { userId: req.user.uid, score: correct, completedAt: new Date() } } }
    );

    // Award XP
    const xp = correct * 10;
    await db.collection('users').updateOne(
      { firebaseUid: req.user.uid },
      { $inc: { xp, totalAnswers: answers.length, totalCorrectAnswers: correct } }
    );

    return res.json({
      score: correct, total: quiz.questions.length,
      accuracy: Math.round((correct / quiz.questions.length) * 100),
      xpEarned: xp, results,
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to submit answers' });
  }
});

// GET /api/sermons/:id/stats - Pastor views completion stats
router.get('/:id/stats', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const quiz = await db.collection('sermon_quizzes').findOne({ _id: new ObjectId(req.params.id) });
    if (!quiz) return res.status(404).json({ error: 'Quiz not found' });
    if (quiz.pastorId !== req.user.uid) return res.status(403).json({ error: 'Only creator can view stats' });

    const totalMembers = await db.collection('users').countDocuments({ churchId: quiz.churchId });
    const completions = quiz.completedBy;
    const avgScore = completions.length > 0
      ? completions.reduce((sum, c) => sum + c.score, 0) / completions.length
      : 0;

    // Resolve names
    const userIds = completions.map(c => c.userId);
    const users = await db.collection('users').find({ firebaseUid: { $in: userIds } },
      { projection: { firebaseUid: 1, displayName: 1 } }).toArray();
    const nameMap = {}; users.forEach(u => { nameMap[u.firebaseUid] = u.displayName; });

    return res.json({
      totalMembers, completedCount: completions.length,
      completionRate: Math.round((completions.length / Math.max(totalMembers, 1)) * 100),
      averageScore: Math.round(avgScore * 10) / 10,
      completions: completions.map(c => ({
        displayName: nameMap[c.userId] || 'Anonymous',
        score: c.score, completedAt: c.completedAt,
      })),
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

module.exports = router;
