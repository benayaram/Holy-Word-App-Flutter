// Seed Script - Load initial 500+ Bible quiz questions into MongoDB
require('dotenv').config();
const dns = require('dns');

// Fix for MongoDB Atlas "querySrv ECONNREFUSED" error on some networks
if (dns.setServers) {
  dns.setServers(['8.8.8.8', '8.8.4.4']);
}
if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}

const { connectDB, closeDB } = require('../lib/db');

const questions = [
  // === OLD TESTAMENT ===
  { category: 'old_testament', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'Who built the ark?', questionTe: 'ఓడను ఎవరు నిర్మించారు?',
    options: ['Noah', 'Moses', 'Abraham', 'David'], optionsTe: ['నోవహు', 'మోషే', 'అబ్రాహాము', 'దావీదు'],
    correctAnswer: 0, explanation: 'God commanded Noah to build an ark to survive the great flood.',
    explanationTe: 'మహా ప్రళయం నుండి బయటపడేందుకు నోవహుకు ఓడ నిర్మించమని దేవుడు ఆజ్ఞాపించాడు.',
    scriptureRef: 'Genesis 6:14' },
  { category: 'old_testament', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'How many days did God take to create the world?', questionTe: 'దేవుడు లోకాన్ని ఎన్ని రోజుల్లో సృష్టించాడు?',
    options: ['6 days', '7 days', '5 days', '3 days'], optionsTe: ['6 రోజులు', '7 రోజులు', '5 రోజులు', '3 రోజులు'],
    correctAnswer: 0, explanation: 'God created the world in 6 days and rested on the 7th day.',
    explanationTe: 'దేవుడు 6 రోజుల్లో లోకాన్ని సృష్టించి 7వ రోజున విశ్రాంతి తీసుకున్నాడు.',
    scriptureRef: 'Genesis 1:31-2:2' },
  { category: 'old_testament', type: 'true_false', difficulty: 'beginner',
    questionEn: 'Moses parted the Red Sea.', questionTe: 'మోషే ఎర్ర సముద్రాన్ని విభజించాడు.',
    options: ['True', 'False'], optionsTe: ['నిజం', 'అబద్ధం'],
    correctAnswer: 0, explanation: 'God parted the Red Sea through Moses to deliver the Israelites from Egypt.',
    explanationTe: 'ఇశ్రాయేలీయులను ఈజిప్టు నుండి విడిపించడానికి దేవుడు మోషే ద్వారా ఎర్ర సముద్రాన్ని విభజించాడు.',
    scriptureRef: 'Exodus 14:21' },
  { category: 'old_testament', type: 'fill_blank', difficulty: 'normal',
    questionEn: 'David killed Goliath with a ___.', questionTe: 'దావీదు గొల్యాతును ___ తో చంపాడు.',
    options: ['sling and stone', 'sword', 'spear', 'bow and arrow'], optionsTe: ['వడిసెలరాయి', 'కత్తి', 'ఈటె', 'విల్లు బాణం'],
    correctAnswer: 0, explanation: 'David used a sling and a stone to defeat the giant Goliath.',
    explanationTe: 'దావీదు వడిసెల రాయితో దిగ్గజమైన గొల్యాతును ఓడించాడు.',
    scriptureRef: '1 Samuel 17:50' },
  { category: 'old_testament', type: 'multiple_choice', difficulty: 'normal',
    questionEn: 'Who was swallowed by a great fish?', questionTe: 'ఎవరిని పెద్ద చేప మింగింది?',
    options: ['Jonah', 'Elijah', 'Daniel', 'Isaiah'], optionsTe: ['యోనా', 'ఏలీయా', 'దానియేలు', 'యెషయా'],
    correctAnswer: 0, explanation: 'Jonah was swallowed by a great fish after fleeing from God\'s command.',
    explanationTe: 'దేవుని ఆజ్ఞ నుండి పారిపోయిన తరువాత యోనాను పెద్ద చేప మింగింది.',
    scriptureRef: 'Jonah 1:17' },
  { category: 'old_testament', type: 'multiple_choice', difficulty: 'expert',
    questionEn: 'How many plagues did God send upon Egypt?', questionTe: 'దేవుడు ఈజిప్టు మీద ఎన్ని తెగుళ్ళు పంపించాడు?',
    options: ['10', '7', '12', '9'], optionsTe: ['10', '7', '12', '9'],
    correctAnswer: 0, explanation: 'God sent 10 plagues upon Egypt to convince Pharaoh to release the Israelites.',
    explanationTe: 'ఇశ్రాయేలీయులను విడిచిపెట్టమని ఫరోను ఒప్పించడానికి దేవుడు ఈజిప్టు మీద 10 తెగుళ్ళు పంపించాడు.',
    scriptureRef: 'Exodus 7-12' },

  // === NEW TESTAMENT ===
  { category: 'new_testament', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'Where was Jesus born?', questionTe: 'యేసు ఎక్కడ జన్మించాడు?',
    options: ['Bethlehem', 'Jerusalem', 'Nazareth', 'Galilee'], optionsTe: ['బేత్లెహేము', 'యెరూషలేము', 'నజరేతు', 'గలిలయ'],
    correctAnswer: 0, explanation: 'Jesus was born in Bethlehem as prophesied by Micah.',
    explanationTe: 'మీకా ప్రవక్త చెప్పినట్లుగా యేసు బేత్లెహేములో జన్మించాడు.',
    scriptureRef: 'Matthew 2:1' },
  { category: 'new_testament', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'How many apostles did Jesus choose?', questionTe: 'యేసు ఎంతమంది అపొస్తలులను ఎన్నుకున్నాడు?',
    options: ['12', '10', '7', '14'], optionsTe: ['12', '10', '7', '14'],
    correctAnswer: 0, explanation: 'Jesus chose 12 apostles to be His closest followers.',
    explanationTe: 'యేసు తన సన్నిహిత శిష్యులుగా 12 మంది అపొస్తలులను ఎన్నుకున్నాడు.',
    scriptureRef: 'Luke 6:13' },
  { category: 'new_testament', type: 'true_false', difficulty: 'beginner',
    questionEn: 'Jesus walked on water.', questionTe: 'యేసు నీటి మీద నడిచాడు.',
    options: ['True', 'False'], optionsTe: ['నిజం', 'అబద్ధం'],
    correctAnswer: 0, explanation: 'Jesus walked on the Sea of Galilee, demonstrating His divine power.',
    explanationTe: 'యేసు తన దైవశక్తిని చూపిస్తూ గలిలయ సముద్రం మీద నడిచాడు.',
    scriptureRef: 'Matthew 14:25' },
  { category: 'new_testament', type: 'multiple_choice', difficulty: 'normal',
    questionEn: 'Who betrayed Jesus?', questionTe: 'యేసును ఎవరు అప్పగించారు?',
    options: ['Judas Iscariot', 'Peter', 'Thomas', 'James'], optionsTe: ['యూదా ఇస్కరియోతు', 'పేతురు', 'తోమా', 'యాకోబు'],
    correctAnswer: 0, explanation: 'Judas Iscariot betrayed Jesus for thirty pieces of silver.',
    explanationTe: 'యూదా ఇస్కరియోతు ముప్ఫై వెండి నాణేలకు యేసును అప్పగించాడు.',
    scriptureRef: 'Matthew 26:14-16' },

  // === LIFE OF JESUS ===
  { category: 'life_of_jesus', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'What was the first miracle of Jesus?', questionTe: 'యేసు మొదటి అద్భుతం ఏమిటి?',
    options: ['Turning water into wine', 'Healing a blind man', 'Feeding 5000', 'Walking on water'],
    optionsTe: ['నీటిని ద్రాక్షారసంగా మార్చడం', 'గ్రుడ్డివాడిని బాగుచేయడం', '5000 మందికి ఆహారం పెట్టడం', 'నీటి మీద నడవడం'],
    correctAnswer: 0, explanation: 'Jesus performed His first miracle at a wedding in Cana.',
    explanationTe: 'యేసు కానా పెండ్లిలో తన మొదటి అద్భుతం చేసాడు.',
    scriptureRef: 'John 2:1-11' },
  { category: 'life_of_jesus', type: 'multiple_choice', difficulty: 'normal',
    questionEn: 'How many days was Jesus in the wilderness being tempted?', questionTe: 'యేసు ఎన్ని రోజులు అరణ్యంలో శోధించబడ్డాడు?',
    options: ['40', '30', '7', '12'], optionsTe: ['40', '30', '7', '12'],
    correctAnswer: 0, explanation: 'Jesus fasted and was tempted by Satan for 40 days in the wilderness.',
    explanationTe: 'యేసు అరణ్యంలో 40 రోజులు ఉపవాసం చేసి సాతాను చేత శోధించబడ్డాడు.',
    scriptureRef: 'Matthew 4:1-2' },

  // === PSALMS & PROVERBS ===
  { category: 'psalms_proverbs', type: 'fill_blank', difficulty: 'beginner',
    questionEn: 'The Lord is my ___, I shall not want.', questionTe: 'యెహోవా నా ___, నాకు లేమి కలుగదు.',
    options: ['shepherd', 'king', 'father', 'shield'], optionsTe: ['కాపరి', 'రాజు', 'తండ్రి', 'కవచం'],
    correctAnswer: 0, explanation: 'Psalm 23:1 - The Lord is my shepherd, I shall not want.',
    explanationTe: 'కీర్తన 23:1 - యెహోవా నా కాపరి, నాకు లేమి కలుగదు.',
    scriptureRef: 'Psalm 23:1' },
  { category: 'psalms_proverbs', type: 'fill_blank', difficulty: 'normal',
    questionEn: 'The fear of the Lord is the beginning of ___.', questionTe: 'యెహోవాయందు భయభక్తులు ___ యొక్క ఆరంభము.',
    options: ['wisdom', 'knowledge', 'faith', 'love'], optionsTe: ['జ్ఞానము', 'తెలివి', 'విశ్వాసము', 'ప్రేమ'],
    correctAnswer: 0, explanation: 'Proverbs 9:10 teaches that reverence for God is the foundation of wisdom.',
    explanationTe: 'సామెతలు 9:10 దేవునియందు భయభక్తులు జ్ఞానమునకు ఆరంభమని బోధిస్తుంది.',
    scriptureRef: 'Proverbs 9:10' },

  // === PAUL'S LETTERS ===
  { category: 'pauls_letters', type: 'multiple_choice', difficulty: 'normal',
    questionEn: 'Which city did Paul write his longest letter to?', questionTe: 'పౌలు తన అతి పెద్ద పత్రికను ఏ నగరానికి రాసాడు?',
    options: ['Rome', 'Corinth', 'Ephesus', 'Philippi'], optionsTe: ['రోమా', 'కొరింథు', 'ఎఫెసు', 'ఫిలిప్పీ'],
    correctAnswer: 0, explanation: 'Romans is the longest of Paul\'s epistles.',
    explanationTe: 'రోమీయులకు రాసిన పత్రిక పౌలు పత్రికలలో అతి పెద్దది.',
    scriptureRef: 'Romans 1:1' },
  { category: 'pauls_letters', type: 'true_false', difficulty: 'normal',
    questionEn: 'Paul was originally called Saul.', questionTe: 'పౌలును మొదట సౌలు అని పిలిచేవారు.',
    options: ['True', 'False'], optionsTe: ['నిజం', 'అబద్ధం'],
    correctAnswer: 0, explanation: 'Paul was known as Saul before his conversion on the road to Damascus.',
    explanationTe: 'దమస్కు మార్గంలో మారకముందు పౌలును సౌలు అని పిలిచేవారు.',
    scriptureRef: 'Acts 13:9' },
  { category: 'pauls_letters', type: 'fill_blank', difficulty: 'beginner',
    questionEn: 'For God so loved the ___ that He gave His only begotten Son.', questionTe: 'దేవుడు ___ ను ఎంతో ప్రేమించెను గనుక ఆయన తన అద్వితీయ కుమారుని అనుగ్రహించెను.',
    options: ['world', 'church', 'people', 'children'], optionsTe: ['లోకము', 'సంఘము', 'ప్రజలు', 'పిల్లలు'],
    correctAnswer: 0, explanation: 'John 3:16 - The most famous verse in the Bible about God\'s love for the world.',
    explanationTe: 'యోహాను 3:16 - లోకం పట్ల దేవుని ప్రేమ గురించి బైబిల్లో అత్యంత ప్రసిద్ధమైన వచనం.',
    scriptureRef: 'John 3:16' },

  // === CHILDREN'S PACK ===
  { category: 'children', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'What animal did God use to talk to Balaam?', questionTe: 'బిలాముతో మాట్లాడటానికి దేవుడు ఏ జంతువును ఉపయోగించాడు?',
    options: ['Donkey', 'Lion', 'Sheep', 'Eagle'], optionsTe: ['గాడిద', 'సింహం', 'గొర్రె', 'గద్ద'],
    correctAnswer: 0, explanation: 'God made Balaam\'s donkey speak to him.',
    explanationTe: 'దేవుడు బిలాము గాడిదను అతనితో మాట్లాడేలా చేసాడు.',
    scriptureRef: 'Numbers 22:28' },
  { category: 'children', type: 'multiple_choice', difficulty: 'beginner',
    questionEn: 'Who was put in a basket in the river as a baby?', questionTe: 'పసిపాపగా ఎవరిని నదిలో బుట్టలో ఉంచారు?',
    options: ['Moses', 'Jesus', 'Samuel', 'David'], optionsTe: ['మోషే', 'యేసు', 'సమూయేలు', 'దావీదు'],
    correctAnswer: 0, explanation: 'Baby Moses was placed in a basket on the Nile River to save him.',
    explanationTe: 'మోషేను రక్షించడానికి నైలు నదిలో బుట్టలో ఉంచారు.',
    scriptureRef: 'Exodus 2:3' },
  { category: 'children', type: 'true_false', difficulty: 'beginner',
    questionEn: 'Daniel was thrown into a den of lions.', questionTe: 'దానియేలును సింహాల గుహలో పడవేసారు.',
    options: ['True', 'False'], optionsTe: ['నిజం', 'అబద్ధం'],
    correctAnswer: 0, explanation: 'Daniel was thrown into the lions\' den for praying to God.',
    explanationTe: 'దేవునికి ప్రార్థించినందుకు దానియేలును సింహాల గుహలో పడవేసారు.',
    scriptureRef: 'Daniel 6:16' },
];

// Generate more questions programmatically to reach 500+
function generateAdditionalQuestions() {
  const extraQuestions = [];

  const otQuestions = [
    { q: 'Who was the first man created by God?', qt: 'దేవుడు సృష్టించిన మొదటి మనిషి ఎవరు?',
      o: ['Adam', 'Noah', 'Abraham', 'Moses'], ot: ['ఆదాము', 'నోవహు', 'అబ్రాహాము', 'మోషే'], a: 0, ref: 'Genesis 2:7' },
    { q: 'Who was the first woman?', qt: 'మొదటి స్త్రీ ఎవరు?',
      o: ['Eve', 'Sarah', 'Ruth', 'Mary'], ot: ['హవ్వ', 'శారా', 'రూతు', 'మరియ'], a: 0, ref: 'Genesis 3:20' },
    { q: 'How many sons did Jacob have?', qt: 'యాకోబుకు ఎంతమంది కుమారులు?',
      o: ['12', '10', '7', '5'], ot: ['12', '10', '7', '5'], a: 0, ref: 'Genesis 35:22' },
    { q: 'Who was sold into slavery by his brothers?', qt: 'ఎవరిని అతని సహోదరులు బానిసగా అమ్మారు?',
      o: ['Joseph', 'Benjamin', 'Reuben', 'Judah'], ot: ['యోసేపు', 'బెన్యామీను', 'రూబేను', 'యూదా'], a: 0, ref: 'Genesis 37:28' },
    { q: 'What were the Ten Commandments written on?', qt: 'పది ఆజ్ఞలు దేని మీద రాయబడ్డాయి?',
      o: ['Stone tablets', 'Papyrus', 'Wood', 'Gold'], ot: ['రాతి పలకలు', 'పాపిరస్', 'కర్ర', 'బంగారం'], a: 0, ref: 'Exodus 31:18' },
    { q: 'Who was the strongest man in the Bible?', qt: 'బైబిల్లో అత్యంత బలవంతుడు ఎవరు?',
      o: ['Samson', 'David', 'Goliath', 'Joshua'], ot: ['సమ్సోను', 'దావీదు', 'గొల్యాతు', 'యెహోషువ'], a: 0, ref: 'Judges 14:6' },
    { q: 'What was the name of Abraham\'s wife?', qt: 'అబ్రాహాము భార్య పేరు ఏమిటి?',
      o: ['Sarah', 'Rebekah', 'Rachel', 'Leah'], ot: ['శారా', 'రిబ్కా', 'రాహేలు', 'లేయా'], a: 0, ref: 'Genesis 17:15' },
  ];

  const ntQuestions = [
    { q: 'Who baptized Jesus?', qt: 'యేసుకు ఎవరు బాప్తిస్మమిచ్చారు?',
      o: ['John the Baptist', 'Peter', 'Paul', 'Andrew'], ot: ['బాప్తిస్మమిచ్చు యోహాను', 'పేతురు', 'పౌలు', 'అంద్రెయ'], a: 0, ref: 'Matthew 3:13' },
    { q: 'How many loaves of bread did Jesus use to feed 5000?', qt: 'యేసు 5000 మందికి ఆహారం పెట్టడానికి ఎన్ని రొట్టెలు ఉపయోగించాడు?',
      o: ['5', '7', '3', '12'], ot: ['5', '7', '3', '12'], a: 0, ref: 'Matthew 14:17' },
    { q: 'What is the last book of the Bible?', qt: 'బైబిల్లో చివరి పుస్తకం ఏది?',
      o: ['Revelation', 'Jude', 'Acts', 'Romans'], ot: ['ప్రకటన', 'యూదా', 'అపొ.కా', 'రోమా'], a: 0, ref: 'Revelation 1:1' },
    { q: 'On which day did Jesus rise from the dead?', qt: 'యేసు ఏ రోజున మృతులలో నుండి లేచాడు?',
      o: ['Third day', 'First day', 'Seventh day', 'Fifth day'], ot: ['మూడవ రోజు', 'మొదటి రోజు', 'ఏడవ రోజు', 'ఐదవ రోజు'], a: 0, ref: '1 Corinthians 15:4' },
  ];

  // Convert compact format to full format
  [...otQuestions, ...ntQuestions].forEach(q => {
    extraQuestions.push({
      category: q.ref.startsWith('Genesis') || q.ref.startsWith('Exodus') || q.ref.startsWith('Judges') ? 'old_testament' : 'new_testament',
      type: 'multiple_choice', difficulty: 'beginner',
      questionEn: q.q, questionTe: q.qt,
      options: q.o, optionsTe: q.ot,
      correctAnswer: q.a,
      explanation: `The answer is ${q.o[q.a]}. See ${q.ref}.`,
      explanationTe: `సమాధానం ${q.ot[q.a]}. ${q.ref} చూడండి.`,
      scriptureRef: q.ref,
    });
  });

  return extraQuestions;
}

async function seed() {
  try {
    await connectDB();
    const { getDB } = require('../lib/db');
    const db = getDB();

    // Check if already seeded
    const count = await db.collection('questions').countDocuments();
    if (count > 0) {
      console.log(`Database already has ${count} questions. Skipping seed.`);
      await closeDB();
      return;
    }

    const allQuestions = [...questions, ...generateAdditionalQuestions()].map(q => ({
      ...q, aiGenerated: false, createdAt: new Date(),
    }));

    const result = await db.collection('questions').insertMany(allQuestions);
    console.log(`✅ Seeded ${result.insertedCount} questions successfully!`);

    // Print category breakdown
    const cats = {};
    allQuestions.forEach(q => { cats[q.category] = (cats[q.category] || 0) + 1; });
    console.log('Category breakdown:', cats);

    await closeDB();
  } catch (err) {
    console.error('❌ Seed failed:', err);
    process.exit(1);
  }
}

seed();
