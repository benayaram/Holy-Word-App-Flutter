import 'package:flutter/material.dart';
import 'prayer_wall_screen.dart';
import 'testimonials_screen.dart';
import 'church_finder_screen.dart';
import 'event_calendar_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCommunityCard(
            context,
            title: 'Prayer Wall',
            subtitle: 'Share your requests and pray for others',
            icon: Icons.volunteer_activism, // Hand holding heart
            color: Colors.orange.shade100,
            iconColor: Colors.deepOrange,
            loadingColor: Colors.deepOrange.withOpacity(0.2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrayerWallScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildCommunityCard(
            context,
            title: 'Testimonials',
            subtitle: 'Read and share inspiring stories of faith',
            icon: Icons.format_quote_rounded,
            color: Colors.blue.shade100,
            iconColor: Colors.blue.shade800,
            loadingColor: Colors.blue.withOpacity(0.2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TestimonialsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildCommunityCard(
            context,
            title: 'Church Finder',
            subtitle: 'Find a place of worship near you',
            icon: Icons.church,
            color: Colors.purple.shade100,
            iconColor: Colors.purple.shade800,
            loadingColor: Colors.purple.withOpacity(0.2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ChurchFinderScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildCommunityCard(
            context,
            title: 'Event Calendar',
            subtitle: 'Stay updated with upcoming events',
            icon: Icons.calendar_month_rounded,
            color: Colors.teal.shade100,
            iconColor: Colors.teal.shade800,
            loadingColor: Colors.teal.withOpacity(0.2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const EventCalendarScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Color loadingColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: loadingColor,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
