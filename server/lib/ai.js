// Gemini AI Question Generator
const { GoogleGenerativeAI } = require('@google/generative-ai');

let genAI = null;

function getGenAI() {
  if (!genAI) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is not set');
    }
    genAI = new GoogleGenerativeAI(apiKey);
  }
  return genAI;
}

/**
 * Generate quiz questions from a Bible passage
 * @param {string} passage - The Bible passage text
 * @param {string} reference - The Bible reference (e.g., "John 3:16")
 * @param {string} category - Question category
 * @param {string} difficulty - beginner|normal|expert
 * @param {number} count - Number of questions to generate
 * @param {string} language - 'en' or 'te' (Telugu)
 * @returns {Array} Array of question objects
 */
async function generateQuestions(passage, reference, category, difficulty, count = 5, language = 'en') {
  const ai = getGenAI();
  const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });

  const difficultyDescriptions = {
    beginner: 'Simple, straightforward questions suitable for children and new believers. Focus on basic facts.',
    normal: 'Moderate difficulty for regular Bible readers. Include context and connections between verses.',
    expert: 'Advanced theological questions for seminary-level students. Include deep interpretation and cross-references.',
  };

  const languageInstruction = language === 'te'
    ? 'Generate ALL text in Telugu (తెలుగు). Questions, options, and explanations must all be in Telugu.'
    : 'Generate all text in English.';

  const prompt = `You are a Bible quiz question generator. Generate exactly ${count} quiz questions from this Bible passage.

PASSAGE: "${passage}"
REFERENCE: ${reference}
CATEGORY: ${category}
DIFFICULTY: ${difficultyDescriptions[difficulty] || difficultyDescriptions.normal}
${languageInstruction}

Generate a JSON array of questions. Each question must follow this EXACT format:
[
  {
    "type": "multiple_choice",
    "questionEn": "Question text in English",
    "questionTe": "Question text in Telugu",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "optionsTe": ["Telugu A", "Telugu B", "Telugu C", "Telugu D"],
    "correctAnswer": 0,
    "explanation": "Why this is the correct answer with scripture reference",
    "explanationTe": "Telugu explanation",
    "scriptureRef": "${reference}"
  }
]

Mix question types:
- "multiple_choice": 4 options, one correct
- "true_false": 2 options ["True", "False"], correctAnswer is 0 (True) or 1 (False)
- "fill_blank": options should be 4 possible words to fill the blank marked with ___

Rules:
1. correctAnswer is the 0-based index of the correct option
2. Every question MUST have a scripture-backed explanation
3. Make questions engaging and educational
4. For Telugu, use proper Telugu Bible terminology
5. Return ONLY valid JSON array, no other text

Return ONLY the JSON array:`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response;
    let text = response.text();

    // Clean up response - extract JSON from markdown code blocks if present
    text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    const questions = JSON.parse(text);

    // Validate and enhance each question
    return questions.map((q, idx) => ({
      category: category,
      type: q.type || 'multiple_choice',
      difficulty: difficulty,
      questionEn: q.questionEn || q.question || '',
      questionTe: q.questionTe || '',
      options: q.options || [],
      optionsTe: q.optionsTe || [],
      correctAnswer: typeof q.correctAnswer === 'number' ? q.correctAnswer : 0,
      explanation: q.explanation || '',
      explanationTe: q.explanationTe || '',
      scriptureRef: q.scriptureRef || reference,
      aiGenerated: true,
      createdAt: new Date(),
    }));
  } catch (err) {
    console.error('❌ Gemini question generation failed:', err.message);
    throw new Error(`AI question generation failed: ${err.message}`);
  }
}

/**
 * Generate sermon quiz questions from key points
 * @param {Array<string>} keyPoints - Array of sermon key points
 * @param {string} sermonTitle - Title of the sermon
 * @param {string} language - 'en' or 'te'
 * @returns {Array} Array of question objects
 */
async function generateSermonQuestions(keyPoints, sermonTitle, language = 'en') {
  const ai = getGenAI();
  const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });

  const languageInstruction = language === 'te'
    ? 'Generate ALL text in Telugu (తెలుగు).'
    : 'Generate all text in English.';

  const prompt = `Generate exactly ${keyPoints.length} multiple-choice quiz questions based on these sermon key points.

SERMON TITLE: "${sermonTitle}"
KEY POINTS:
${keyPoints.map((p, i) => `${i + 1}. ${p}`).join('\n')}
${languageInstruction}

Each question should test whether someone was paying attention to the sermon.
Return a JSON array with this format:
[
  {
    "question": "Question text",
    "questionTe": "Telugu question text",
    "options": ["A", "B", "C", "D"],
    "optionsTe": ["Telugu A", "Telugu B", "Telugu C", "Telugu D"],
    "correctAnswer": 0,
    "keyPointIndex": 0
  }
]

Return ONLY valid JSON:`;

  try {
    const result = await model.generateContent(prompt);
    let text = result.response.text();
    text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    return JSON.parse(text);
  } catch (err) {
    console.error('❌ Sermon question generation failed:', err.message);
    throw new Error(`Sermon question generation failed: ${err.message}`);
  }
}

module.exports = { generateQuestions, generateSermonQuestions };
