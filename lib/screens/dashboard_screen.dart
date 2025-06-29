import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _totalAppointments = 0;
  int _pendingAppointments = 0;
  int _completedAppointments = 0;
  List<Map<String, dynamic>> _recentDoctors = [];
  bool _loading = true;

  List<Map<String, dynamic>> _recentAppointments = [];
  Map<String, dynamic>? _nextAppointment;

  final List<Map<String, dynamic>> _healthInsights = [
    {
      'title': 'Blood Pressure',
      'value': '120/80',
      'status': 'Normal',
      'color': Color(0xFF48bb78),
      'icon': Icons.favorite,
      'trend': 'stable',
    },
    {
      'title': 'BMI',
      'value': '23.5',
      'status': 'Healthy',
      'color': Color(0xFF48bb78),
      'icon': Icons.fitness_center,
      'trend': 'improving',
    },
    {
      'title': 'Last Check-up',
      'value': '2 weeks ago',
      'status': 'Recent',
      'color': Color(0xFF667eea),
      'icon': Icons.medical_services,
      'trend': 'stable',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load appointments data
        final appointmentsQuery =
            await FirebaseFirestore.instance
                .collection('appointments')
                .where('patientDocID', isEqualTo: user.uid)
                .orderBy('dateTime', descending: true)
                .get();

        final appointments = appointmentsQuery.docs;
        _totalAppointments = appointments.length;
        _pendingAppointments =
            appointments
                .where((doc) => (doc.data()['status'] ?? '') == 'pending')
                .length;
        _completedAppointments =
            appointments
                .where((doc) => (doc.data()['status'] ?? '') == 'completed')
                .length;

        // Load recent appointments (last 3)
        _recentAppointments =
            appointments.take(3).map((doc) {
              final data = doc.data();
              return {...data, 'id': doc.id};
            }).toList();

        // Find next upcoming appointment
        final upcomingAppointments =
            appointments.where((doc) {
              final data = doc.data();
              final dateTime = parseFirestoreDate(data['dateTime']);
              return dateTime.isAfter(DateTime.now());
            }).toList();

        if (upcomingAppointments.isNotEmpty) {
          // Sort by date and get the closest one
          upcomingAppointments.sort((a, b) {
            final dateA = parseFirestoreDate(a.data()['dateTime']);
            final dateB = parseFirestoreDate(b.data()['dateTime']);
            return dateA.compareTo(dateB);
          });
          _nextAppointment = {
            ...upcomingAppointments.first.data(),
            'id': upcomingAppointments.first.id,
          };
        }

        // Load all doctors
        final doctorsQuery =
            await FirebaseFirestore.instance.collection('doctors').get();

        _recentDoctors = doctorsQuery.docs.map((doc) => doc.data()).toList();
      }
    } catch (e) {
      // Handle error silently for demo
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.of(context).pushNamed('/doctors');
        break;
      case 2:
        Navigator.of(context).pushNamed('/appointments');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // App Header
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 40,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'EHealth Desktop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FirebaseAuth.instance.currentUser?.email?.split(
                              '@',
                            )[0] ??
                            'User',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Navigation Menu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard,
                          title: 'Dashboard',
                          isSelected: _selectedIndex == 0,
                          onTap: () => _onNavigationTap(0),
                        ),
                        _SidebarItem(
                          icon: Icons.local_hospital,
                          title: 'Find Doctors',
                          isSelected: _selectedIndex == 1,
                          onTap: () => _onNavigationTap(1),
                        ),
                        _SidebarItem(
                          icon: Icons.calendar_today,
                          title: 'My Appointments',
                          isSelected: _selectedIndex == 2,
                          onTap: () => _onNavigationTap(2),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        _SidebarItem(
                          icon: Icons.settings,
                          title: 'Settings',
                          isSelected: false,
                          onTap: () {},
                        ),
                        _SidebarItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          isSelected: false,
                          onTap: () => FirebaseAuth.instance.signOut(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFf7fafc), Color(0xFFedf2f7)],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting!',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Welcome to your health dashboard',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(now),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryBlock(
                            title: 'Total Doctors',
                            value: '12',
                            icon: Icons.medical_services,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _SummaryBlock(
                            title: 'Total Appointments',
                            value: '34',
                            icon: Icons.calendar_today,
                            color: Color(0xFF48bb78),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _SummaryBlock(
                            title: 'Pending',
                            value: '3',
                            icon: Icons.schedule,
                            color: Color(0xFFf6ad55),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _SummaryBlock(
                            title: 'Completed',
                            value: '29',
                            icon: Icons.check_circle,
                            color: Color(0xFF805ad5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_circle_outline,
                            title: 'Book Appointment',
                            subtitle: 'Schedule a new visit',
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.people_outline,
                            title: 'View Doctors',
                            subtitle: 'Browse all doctors',
                            color: Color(0xFF48bb78),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.download_outlined,
                            title: 'Download Report',
                            subtitle: 'Get your health summary',
                            color: Color(0xFFf6ad55),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.settings,
                            title: 'Settings',
                            subtitle: 'Manage your account',
                            color: Color(0xFF805ad5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Health Insights
                    const Text(
                      'Health Insights',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _HealthInsightCard(
                            icon: Icons.favorite,
                            title: 'Blood Pressure',
                            value: '120/80',
                            status: 'Normal',
                            color: Color(0xFF48bb78),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _HealthInsightCard(
                            icon: Icons.fitness_center,
                            title: 'BMI',
                            value: '23.5',
                            status: 'Healthy',
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _HealthInsightCard(
                            icon: Icons.medical_services,
                            title: 'Last Check-up',
                            value: '2 weeks ago',
                            status: 'Recent',
                            color: Color(0xFFf6ad55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RecentActivityList(),
                    const SizedBox(height: 40),

                    Center(
                      child: Text(
                        'Your health at a glance',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<Map<String, dynamic>?> _fetchDoctor(int doctorId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('doctors')
              .where('id', isEqualTo: doctorId)
              .limit(1)
              .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }
}

// Summary Block Widget
class _SummaryBlock extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryBlock({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sidebar Item Widget
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF667eea).withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isSelected
                      ? Border.all(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                      )
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected ? const Color(0xFF667eea) : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF667eea) : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Health Insight Card Widget
class _HealthInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String status;
  final Color color;

  const _HealthInsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Recent Activity List Widget
class _RecentActivityList extends StatelessWidget {
  final List<Map<String, String>> _activities = const [
    {
      'icon': 'event_available',
      'title': 'Appointment Confirmed',
      'desc': 'Your appointment with Dr. Smith is confirmed.',
      'time': 'Today, 10:00 AM',
    },
    {
      'icon': 'file_download',
      'title': 'Report Downloaded',
      'desc': 'You downloaded your blood test report.',
      'time': 'Yesterday, 3:45 PM',
    },
    {
      'icon': 'edit',
      'title': 'Profile Updated',
      'desc': 'You updated your profile information.',
      'time': '2 days ago',
    },
    {
      'icon': 'medical_services',
      'title': 'New Doctor Added',
      'desc': 'Dr. Emily joined your care team.',
      'time': '3 days ago',
    },
  ];

  const _RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activities.length,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final activity = _activities[i];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconFromString(activity['icon']!),
                color: const Color(0xFF667eea),
              ),
            ),
            title: Text(
              activity['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3748),
              ),
            ),
            subtitle: Text(
              activity['desc']!,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            trailing: Text(
              activity['time']!,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFromString(String iconName) {
  switch (iconName) {
    case 'event_available':
      return Icons.event_available;
    case 'file_download':
      return Icons.file_download;
    case 'edit':
      return Icons.edit;
    case 'medical_services':
      return Icons.medical_services;
    default:
      return Icons.info_outline;
  }
}

DateTime parseFirestoreDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
