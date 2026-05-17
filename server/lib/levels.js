// Centralized level calculation for Holy Word Arena
// Used by questions.js, memory.js, and websocket.js

function calcLevel(xp, versesMemorized) {
  if (versesMemorized >= 365) return 'Living Word';
  if (xp >= 5000) return 'Apostle';
  if (xp >= 2000) return 'Elder';
  if (xp >= 500) return 'Disciple';
  return 'Seeker';
}

module.exports = { calcLevel };
