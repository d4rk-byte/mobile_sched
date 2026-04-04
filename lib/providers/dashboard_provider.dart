// lib/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import 'api_provider.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getFacultyDashboard();
  return DashboardData.fromJson(response);
});

final dashboardRefreshProvider = StateProvider<bool>((ref) => false);

final refreshedDashboardProvider = FutureProvider<DashboardData>((ref) async {
  // This will rebuild when refreshedDashboardProvider.notifier.update() is called
  final apiService = ref.watch(apiServiceProvider);
  ref.watch(dashboardRefreshProvider);
  final response = await apiService.getFacultyDashboard();
  return DashboardData.fromJson(response);
});
