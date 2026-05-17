// MongoDB Atlas Connection Singleton
const { MongoClient } = require('mongodb');

let client = null;
let db = null;
let indexesCreated = false;

async function connectDB() {
  if (db) return db;

  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI environment variable is not set');
  }

  client = new MongoClient(uri, {
    maxPoolSize: 10,
    minPoolSize: 2,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
  });

  await client.connect();
  db = client.db('holy_word_arena');

  // Create indexes only once per process lifetime
  if (!indexesCreated) {
    await createIndexes(db);
    indexesCreated = true;
  }

  console.log('✅ Connected to MongoDB Atlas');
  return db;
}

async function createIndexes(database) {
  try {
    // Users
    await database.collection('users').createIndex({ firebaseUid: 1 }, { unique: true });
    await database.collection('users').createIndex({ xp: -1 });
    await database.collection('users').createIndex({ churchId: 1 });
    await database.collection('users').createIndex({ fcmToken: 1 });

    // Questions
    await database.collection('questions').createIndex({ category: 1, difficulty: 1 });
    await database.collection('questions').createIndex({ type: 1 });

    // Battles
    await database.collection('battles').createIndex({ inviteCode: 1 });
    await database.collection('battles').createIndex({ status: 1 });
    await database.collection('battles').createIndex({ player1Id: 1 });
    await database.collection('battles').createIndex({ player2Id: 1 });
    await database.collection('battles').createIndex({ 'matchmaking.status': 1 });

    // Tournaments
    await database.collection('tournaments').createIndex({ code: 1 }, { unique: true });
    await database.collection('tournaments').createIndex({ churchId: 1 });

    // Sermon Quizzes
    await database.collection('sermon_quizzes').createIndex({ churchId: 1 });
    await database.collection('sermon_quizzes').createIndex({ createdAt: -1 });

    // Memory Progress
    await database.collection('memory_progress').createIndex(
      { userId: 1, bookId: 1, chapter: 1, verse: 1 },
      { unique: true }
    );
    await database.collection('memory_progress').createIndex({ userId: 1 });

    // Leaderboard entries
    await database.collection('leaderboards').createIndex({ type: 1, score: -1 });
    await database.collection('leaderboards').createIndex({ userId: 1, type: 1 });

    console.log('✅ Database indexes created');
  } catch (err) {
    console.warn('⚠️ Index creation warning (may already exist):', err.message);
  }
}

function getDB() {
  if (!db) {
    throw new Error('Database not initialized. Call connectDB() first.');
  }
  return db;
}

async function closeDB() {
  if (client) {
    await client.close();
    client = null;
    db = null;
    console.log('🔌 MongoDB connection closed');
  }
}

module.exports = { connectDB, getDB, closeDB };
