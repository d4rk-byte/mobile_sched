import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/configs/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Faculty Dashboard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: authState.isAuthenticated
          ? const MainScreen()
          : const LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(
            () {
              _selectedIndex = index;
            },
          );
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/ic_home.png', width: 28),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/ic_calendar.png', width: 28),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/ic_checklist.png', width: 28),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/ic_notification.png', width: 28),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/ic_profile.png', width: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ScheduleScreen();
      case 2:
        return const ClassesScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }
}
