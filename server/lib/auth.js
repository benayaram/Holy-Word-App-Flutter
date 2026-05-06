// Firebase Admin SDK - Auth verification + FCM
const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized) return;

  try {
    const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

    if (serviceAccountBase64) {
      const serviceAccount = JSON.parse(
        Buffer.from(serviceAccountBase64, 'base64').toString('utf-8')
      );
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      // Fallback: try Application Default Credentials (for local dev)
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    }

    initialized = true;
    console.log('✅ Firebase Admin initialized');
  } catch (err) {
    console.error('❌ Firebase Admin init failed:', err.message);
    throw err;
  }
}

// Verify Firebase ID token from client
async function verifyToken(idToken) {
  initFirebase();
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (err) {
    console.error('Token verification failed:', err.message);
    return null;
  }
}

// Express middleware: attach user to req
async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = authHeader.split('Bearer ')[1];
  const decoded = await verifyToken(token);

  if (!decoded) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  req.user = {
    uid: decoded.uid,
    email: decoded.email || null,
    name: decoded.name || null,
    picture: decoded.picture || null,
  };

  next();
}

// Optional auth - doesn't fail if no token, just sets req.user = null
async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    req.user = null;
    return next();
  }

  const token = authHeader.split('Bearer ')[1];
  const decoded = await verifyToken(token);
  req.user = decoded ? { uid: decoded.uid, email: decoded.email, name: decoded.name } : null;
  next();
}

module.exports = { initFirebase, verifyToken, authMiddleware, optionalAuth };
