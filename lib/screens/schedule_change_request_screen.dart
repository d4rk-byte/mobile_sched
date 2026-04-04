// lib/screens/schedule_change_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';

class ScheduleChangeRequestScreen extends ConsumerWidget {
  const ScheduleChangeRequestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Change Requests'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Approved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Requests list
              const Center(
                child: Text(
                  'Loading requests...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open new request form
        },
        label: const Text('New Request'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      onSelected: (selected) {
        // Filter requests
      },
    );
  }
}
