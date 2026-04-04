// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/schedule_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: dashboardAsync.when(
        data: (dashboard) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dashboard.academicYear != null
                          ? '${dashboard.academicYear!.year}, ${dashboard.academicYear!.semester} Semester'
                          : 'No active academic period',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stat Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.9,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    StatCard(
                      label: 'Teaching Hours',
                      value: '${dashboard.stats.totalHours}',
                      helper: 'Per week',
                      backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                      iconColor: const Color(0xFF3B82F6),
                      icon: Icons.access_time,
                    ),
                    StatCard(
                      label: 'Active Classes',
                      value: '${dashboard.stats.activeClasses}',
                      helper: 'Current term',
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                      iconColor: const Color(0xFF10B981),
                      icon: Icons.book,
                    ),
                    StatCard(
                      label: 'Total Students',
                      value: '${dashboard.stats.totalStudents}',
                      helper: 'Across classes',
                      backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
                      iconColor: const Color(0xFFF59E0B),
                      icon: Icons.people,
                    ),
                    StatCard(
                      label: 'Today\'s Classes',
                      value: '${dashboard.stats.todayCount}',
                      helper: 'Classes today',
                      backgroundColor: const Color(0xFFA855F7).withOpacity(0.1),
                      iconColor: const Color(0xFFA855F7),
                      icon: Icons.calendar_today,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's Schedule
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to full schedule
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (dashboard.todaySchedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No classes today',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: dashboard.todaySchedules
                        .map(
                          (schedule) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScheduleTile(
                              schedule: schedule,
                              onTap: () {
                                // Navigate to schedule details
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
