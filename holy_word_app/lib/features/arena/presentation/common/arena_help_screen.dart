import 'package:flutter/material.dart';
import '../arena_theme.dart';

class ArenaHelpScreen extends StatefulWidget {
  const ArenaHelpScreen({super.key});

  @override
  State<ArenaHelpScreen> createState() => _ArenaHelpScreenState();
}

class _ArenaHelpScreenState extends State<ArenaHelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('Bible Arena Help & Flow Guide', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ArenaTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.swap_calls_rounded), text: 'User Flow'),
            Tab(icon: Icon(Icons.quiz_rounded), text: 'Bible Quiz'),
            Tab(icon: Icon(Icons.church_rounded), text: 'Sermon Hub'),
            Tab(icon: Icon(Icons.psychology_rounded), text: 'Scripture Memory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserFlowTab(),
          _buildQuizTab(),
          _buildSermonTab(),
          _buildMemoryTab(),
        ],
      ),
    );
  }

  Widget _buildUserFlowTab() {
    final flowSteps = [
      _FlowStep(
        stepNumber: '1',
        title: 'Choose Your Role & Join Churches',
        description: 'Pastors toggle the pastor flag under Profile, allowing them to create a customized church profile with contact details, address, cover photos, and sermon composing permissions. Normal members follow their favorite local or global churches.',
        icon: Icons.person_add_rounded,
        color: ArenaTheme.primary,
      ),
      _FlowStep(
        stepNumber: '2',
        title: 'Sermon Composing & Quiz Builder',
        description: 'Pastors use the high-fidelity composer to write sermon summaries, customize wrong choices for targeted quiz questions, preview the layout in markdown format, and hit publish!',
        icon: Icons.edit_note_rounded,
        color: ArenaTheme.accent,
      ),
      _FlowStep(
        stepNumber: '3',
        title: 'Instant Push Alerts',
        description: 'Publishing sermon notes triggers instant cloud push notifications to every member subscribed to that church. Tapping the notification takes members directly to the Sermon Notes Hub!',
        icon: Icons.notifications_active_rounded,
        color: ArenaTheme.xpGold,
      ),
      _FlowStep(
        stepNumber: '4',
        title: 'Read, Learn & Earn XP',
        description: 'Members read through pastor\'s notes and play the sermon quiz. Answering correctly awards valuable XP, helps you level up from a Seeker to a Disciple, and increases your ranking!',
        icon: Icons.emoji_events_rounded,
        color: ArenaTheme.success,
      ),
      _FlowStep(
        stepNumber: '5',
        title: 'Share Achievements & Cards',
        description: 'Generate high-fidelity, downloadable victory achievement cards. Share your Bible quiz scores, trivia battle wins, and milestone ranks with friends and family!',
        icon: Icons.share_rounded,
        color: ArenaTheme.quizCyan,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ArenaTheme.primary.withOpacity(0.15), ArenaTheme.accent.withOpacity(0.15)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.insights_rounded, color: ArenaTheme.primary, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interactive User Flow Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Understand the cycle of community engagement, bible studying, and sharing in Holy Word App.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: flowSteps.length,
            itemBuilder: (context, index) {
              final step = flowSteps[index];
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [step.color, step.color.withOpacity(0.6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: step.color.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              step.stepNumber,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        if (index < flowSteps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.white.withOpacity(0.15),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step.icon, color: step.color, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.description,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureOverviewCard(
            title: 'Bible Quiz Solo Mode',
            description: 'Test your understanding of Scripture across multiple categories and difficulties. Ideal for personal meditation and growing in daily knowledge.',
            icon: Icons.quiz_rounded,
            color: ArenaTheme.primary,
          ),
          const SizedBox(height: 20),
          const Text('Quiz Mechanics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildInstructionBullet(
            icon: Icons.timer_rounded,
            title: 'Adaptive Timer',
            description: 'You have 15 seconds for regular multiple-choice questions, and 6 seconds for True/False questions. Think quickly!',
          ),
          _buildInstructionBullet(
            icon: Icons.bolt_rounded,
            title: 'Streak Multipliers',
            description: 'Get consecutive questions right to build a streak! High streaks multiply your final XP output.',
          ),
          _buildInstructionBullet(
            icon: Icons.dynamic_feed_rounded,
            title: 'Relaxed Category Queries',
            description: 'Never get stuck! If a specific category or difficulty runs out of seeded questions, our backend automatically relaxes filters to supply relevant general questions.',
          ),
          const SizedBox(height: 24),
          const Text('Difficulty Multipliers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.5),
            },
            border: TableBorder.all(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04)),
                children: const [
                  Padding(padding: EdgeInsets.all(10), child: Text('Difficulty', style: TextStyle(color: ArenaTheme.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('XP Per Correct', style: TextStyle(color: ArenaTheme.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('Time Limit', style: TextStyle(color: ArenaTheme.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Easy', style: TextStyle(color: Colors.white, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('5 XP', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('20 seconds', style: TextStyle(color: Colors.white70, fontSize: 12))),
                ],
              ),
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Normal', style: TextStyle(color: Colors.white, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('10 XP', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('15 seconds', style: TextStyle(color: Colors.white70, fontSize: 12))),
                ],
              ),
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text('Hard', style: TextStyle(color: Colors.white, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('20 XP', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(10), child: Text('10 seconds', style: TextStyle(color: Colors.white70, fontSize: 12))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSermonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureOverviewCard(
            title: 'Sermon Notes & Church Profiles',
            description: 'Connect pastors and members through instant notes sharing, customizable questionnaires, and digital interactive church profile cards.',
            icon: Icons.church_rounded,
            color: ArenaTheme.sermonPink,
          ),
          const SizedBox(height: 20),
          const Text('Pastors Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildInstructionBullet(
            icon: Icons.add_business_rounded,
            title: 'Church Profile Customization',
            description: 'Upload high-fidelity details: cover photo, address, description, and contact email/phone. Members tapping your church chip will see your custom card widget.',
          ),
          _buildInstructionBullet(
            icon: Icons.draw_rounded,
            title: 'Custom Questions & Wrong Options',
            description: 'Don\'t leave answers to chance! Explicitly type out wrong choice distractors for your congregation, or click switch to let Gemini AI draft them.',
          ),
          _buildInstructionBullet(
            icon: Icons.notification_add_rounded,
            title: 'Silent Broadcast Alerts',
            description: 'Publishing automatically pushes notifications. Subscribers clicking the push are taken directly to the reading note.',
          ),
          const SizedBox(height: 24),
          const Text('Members Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildInstructionBullet(
            icon: Icons.search_rounded,
            title: 'Follow Multiple Churches',
            description: 'Search registered churches from the dropdown menu in your Profile. Follow as many congregations as you participate in.',
          ),
          _buildInstructionBullet(
            icon: Icons.star_rounded,
            title: 'Retain & Test Knowledge',
            description: 'Read the pastor\'s structured key takeaways, and answer the sermon quiz to lock in the lesson. Complete notes and gain points!',
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureOverviewCard(
            title: 'Scripture Memory Progression',
            description: 'Engage with daily Bible verses through 5 unique cognitive steps. Proven to increase memorization retention rate by 300%.',
            icon: Icons.psychology_rounded,
            color: ArenaTheme.memoryPurple,
          ),
          const SizedBox(height: 20),
          const Text('The 5 Progression Levels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildProgressLevelCard(
            level: 'Level 1',
            name: 'Flashcards',
            description: 'Read the full verse. Tap the card to flip and view coordinates. Repeat aloud to get a mental picture.',
            color: Colors.purpleAccent,
          ),
          _buildProgressLevelCard(
            level: 'Level 2',
            name: 'Word Jumble',
            description: 'Words of the scripture are shuffled. Rearrange them by dragging and dropping or selecting in correct order.',
            color: Colors.blueAccent,
          ),
          _buildProgressLevelCard(
            level: 'Level 3',
            name: 'Missing Blanks',
            description: 'Key words are omitted. Choose correct options or fill in the blanks using helper keywords.',
            color: Colors.orangeAccent,
          ),
          _buildProgressLevelCard(
            level: 'Level 4',
            name: 'First Letter Mode',
            description: 'Only the first letter of each word remains. Attempt to read the full verse using letters as cognitive triggers.',
            color: Colors.tealAccent,
          ),
          _buildProgressLevelCard(
            level: 'Level 5',
            name: 'Typing Master',
            description: 'The final boss! Type the verse from memory with minimum typos. Lock in your achievement and claim maximum XP!',
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureOverviewCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBullet({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArenaTheme.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLevelCard({
    required String level,
    required String name,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              level,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep {
  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _FlowStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
