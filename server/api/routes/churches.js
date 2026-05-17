const express = require('express');
const router = express.Router();
const { getDB } = require('../../lib/db');
const { authMiddleware } = require('../../lib/auth');

// GET /api/churches - Get list of all available churches in the system
router.get('/', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    
    // Fetch unique church names from all users' churchIds arrays
    const userChurches = await db.collection('users').distinct('churchIds');
    
    // Fetch church names from created profiles
    const profileChurches = await db.collection('church_profiles').distinct('name');
    
    const defaultChurches = [
      'Holy Word Cathedral',
      'Grace Community Church',
      'Calvary Chapel',
      'Redeemer Presbyterian',
      'Bethel Church'
    ];
    
    // Combine, deduplicate, and sort alphabetically
    const combined = Array.from(
      new Set([...defaultChurches, ...userChurches, ...profileChurches])
    ).filter(Boolean).sort();
    
    return res.json({ churches: combined });
  } catch (err) {
    console.error('Fetch churches error:', err);
    return res.status(500).json({ error: 'Failed to fetch churches list' });
  }
});

// GET /api/churches/profile/:name - Fetch a church profile by name
router.get('/profile/:name', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const churchName = req.params.name;
    
    let profile = await db.collection('church_profiles').findOne({ name: churchName });
    
    // Fallback/Mock profile if it hasn't been custom created yet
    if (!profile) {
      profile = {
        name: churchName,
        pastorName: 'Senior Pastor',
        location: 'Main Sanctuary, City Center',
        description: 'A welcoming bible-believing community dedicated to fellowship, worship, and deep scripture study.',
        imageUrl: 'https://images.unsplash.com/photo-1438032005730-c779502df39b?q=80&w=600&auto=format&fit=crop',
        contact: 'office@' + churchName.toLowerCase().replace(/[^a-z0-9]/g, '') + '.org',
        createdAt: new Date(),
        isPlaceholder: true,
      };
    }
    
    return res.json({ profile });
  } catch (err) {
    console.error('Get church profile error:', err);
    return res.status(500).json({ error: 'Failed to fetch church profile' });
  }
});

// POST /api/churches/profile - Create or update a church profile (Pastors only)
router.post('/profile', authMiddleware, async (req, res) => {
  try {
    const db = getDB();
    const { name, location, description, imageUrl, contact } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Church name is required' });
    }
    
    // Ensure requesting user is a pastor
    const user = await db.collection('users').findOne({ firebaseUid: req.user.uid });
    if (!user || !user.isPastor) {
      return res.status(403).json({ error: 'Only pastors can edit church profiles' });
    }
    
    const profileData = {
      name,
      pastorId: req.user.uid,
      pastorName: user.displayName,
      location: location || 'Main Sanctuary, City Center',
      description: description || 'A welcoming Bible-based community.',
      imageUrl: imageUrl || 'https://images.unsplash.com/photo-1438032005730-c779502df39b?q=80&w=600&auto=format&fit=crop',
      contact: contact || user.email || '',
      updatedAt: new Date()
    };
    
    // Upsert the profile based on the unique church name
    await db.collection('church_profiles').updateOne(
      { name },
      { 
        $set: profileData,
        $setOnInsert: { createdAt: new Date() }
      },
      { upsert: true }
    );
    
    return res.json({ success: true, message: 'Church profile saved successfully' });
  } catch (err) {
    console.error('Save church profile error:', err);
    return res.status(500).json({ error: 'Failed to save church profile' });
  }
});

module.exports = router;
