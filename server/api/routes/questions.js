// Questions Routes
const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');
const { generateQuestions } = require('../../lib/ai');
const { calcLevel } = require('../../lib/levels');
const { ObjectId } = require('mongodb');

// GET /api/questions - Fetch random quiz questions (no answers for battle)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { category, difficulty = 'normal', type, limit = 10 } = req.query;
    const query = {};
    if (category) query.category = category;
    if (difficulty) query.difficulty = difficulty;
    if (type) query.type = type;

    const questions = await db.collection('questions')
      .aggregate([{ $match: query }, { $sample: { size: parseInt(limit) } }])
      .toArray();

    return res.json({
      questions: questions.map(q => ({
        id: q._id.toString(), type: q.type, category: q.category,
        difficulty: q.difficulty, questionEn: q.questionEn, questionTe: q.questionTe,
        options: q.options, optionsTe: q.optionsTe, scriptureRef: q.scriptureRef,
      })),
    });
  } catch (err) {
    console.error('Get questions error:', err);
    return res.status(500).json({ error: 'Failed to fetch questions' });
  }
});

// GET /api/questions/with-answers - Fetch questions WITH answers (solo quiz)
router.get('/with-answers', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { category, difficulty = 'normal', type, limit = 10 } = req.query;
    const query = {};
    if (category) query.category = category;
    if (difficulty) query.difficulty = difficulty;
    if (type) query.type = type;

    const questions = await db.collection('questions')
      .aggregate([{ $match: query }, { $sample: { size: parseInt(limit) } }])
      .toArray();

    return res.json({
      questions: questions.map(q => ({
        id: q._id.toString(), type: q.type, category: q.category,
        difficulty: q.difficulty, questionEn: q.questionEn, questionTe: q.questionTe,
        options: q.options, optionsTe: q.optionsTe,
        correctAnswer: q.correctAnswer, explanation: q.explanation,
        explanationTe: q.explanationTe, scriptureRef: q.scriptureRef,
      })),
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch questions' });
  }
});

// POST /api/questions/submit-quiz - Submit complete solo quiz
router.post('/submit-quiz', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { answers } = req.body; // [{ questionId, answer, timeMs }]
    if (!answers || !Array.isArray(answers))
      return res.status(400).json({ error: 'answers array required' });

    const qIds = answers.map(a => new ObjectId(a.questionId));
    const questions = await db.collection('questions').find({ _id: { $in: qIds } }).toArray();
    const qMap = {}; questions.forEach(q => { qMap[q._id.toString()] = q; });

    let correct = 0;
    const results = answers.map(a => {
      const q = qMap[a.questionId];
      if (!q) return { questionId: a.questionId, correct: false };
      const isCorrect = a.answer === q.correctAnswer;
      if (isCorrect) correct++;
      return { questionId: a.questionId, correct: isCorrect, correctAnswer: q.correctAnswer,
        explanation: q.explanation, explanationTe: q.explanationTe, scriptureRef: q.scriptureRef };
    });

    const xp = correct * 10;
    await db.collection('users').updateOne({ firebaseUid: req.user.uid }, {
      $inc: { totalAnswers: answers.length, totalCorrectAnswers: correct, quizzesCompleted: 1, xp },
      $set: { updatedAt: new Date() },
    });

    // Update level
    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (user) {
      const lvl = calcLevel(user.xp, user.versesMemorized || 0);
      if (lvl !== user.level) await db.collection('users').updateOne(
        { firebaseUid: req.user.uid }, { $set: { level: lvl } });
    }

    return res.json({ score: correct, total: answers.length,
      accuracy: Math.round((correct / answers.length) * 100), xpEarned: xp, results });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to submit quiz' });
  }
});

// POST /api/questions/generate - AI-generate new questions
router.post('/generate', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { passage, reference, category, difficulty, count = 5, language = 'en' } = req.body;
    if (!passage || !reference)
      return res.status(400).json({ error: 'passage and reference required' });

    let questions = [];
    try {
      questions = await generateQuestions(
        passage, reference, category || 'general', difficulty || 'normal', count, language);
      if (questions.length > 0) await db.collection('questions').insertMany(questions);
    } catch (aiErr) {
      console.warn('Gemini API failed, falling back to premade questions:', aiErr.message);
      // Fallback: Fetch random premade questions matching the category/difficulty
      const query = {};
      if (category) query.category = category;
      if (difficulty) query.difficulty = difficulty;
      
      let fallbackQuestions = await db.collection('questions')
        .aggregate([{ $match: query }, { $sample: { size: parseInt(count) } }])
        .toArray();
        
      // If we don't have enough matching questions, get ANY random questions to fill the gap
      if (fallbackQuestions.length < count) {
        const moreQuestions = await db.collection('questions')
          .aggregate([{ $sample: { size: parseInt(count) - fallbackQuestions.length } }])
          .toArray();
        fallbackQuestions = [...fallbackQuestions, ...moreQuestions];
      }
      
      questions = fallbackQuestions.map(q => {
        // Map _id to id so it matches the expected model format
        const { _id, ...rest } = q;
        return { id: _id.toString(), ...rest };
      });
      
      return res.json({ generated: 0, fallback: true, questions });
    }

    return res.json({ generated: questions.length, fallback: false, questions });
  } catch (err) {
    return res.status(500).json({ error: 'Generation completely failed: ' + err.message });
  }
});

// GET /api/questions/categories
router.get('/categories', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const cats = await db.collection('questions').aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } }, { $sort: { count: -1 } },
    ]).toArray();
    return res.json({ categories: cats.map(c => ({ name: c._id, count: c.count })) });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch categories' });
  }
});



module.exports = router;
