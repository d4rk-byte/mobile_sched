import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/configs/theme.dart';
import 'ui/auth/screens/screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'widgets/faculty_profile_completion_dialog.dart';
import 'services/class_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize class notifications
  await ClassNotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      key: ValueKey(authState.isAuthenticated),
      title: 'Faculty Dashboard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    // Show loading screen while initializing auth
    if (!authState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show main screen if authenticated, otherwise login
    return authState.isAuthenticated ? const MainScreen() : const WelcomePage();
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  bool _isProfileDialogVisible = false;
  bool _profilePromptHandled = false;
  static const _screens = <Widget>[
    DashboardScreen(),
    ScheduleScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _promptProfileCompletionIfNeeded(AuthState authState) {
    final shouldPrompt = authState.isAuthenticated &&
        authState.isFaculty &&
        authState.user != null &&
        !authState.user!.profileComplete;

    if (!shouldPrompt) {
      _profilePromptHandled = false;
      return;
    }

    if (_isProfileDialogVisible || _profilePromptHandled) {
      return;
    }

    _profilePromptHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      _isProfileDialogVisible = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: FacultyProfileCompletionDialog(),
        ),
      );
      _isProfileDialogVisible = false;

      if (!mounted) {
        return;
      }

      final refreshedState = ref.read(authProvider);
      final needsAnotherPrompt = refreshedState.isAuthenticated &&
          refreshedState.isFaculty &&
          refreshedState.user != null &&
          !refreshedState.user!.profileComplete;

      if (needsAnotherPrompt) {
        _profilePromptHandled = false;
        _promptProfileCompletionIfNeeded(refreshedState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final unreadNotificationCount =
        ref.watch(effectiveUnreadNotificationCountProvider);
    _promptProfileCompletionIfNeeded(authState);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home_outlined),
            activeIcon: _buildNavIcon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.calendar_month_outlined),
            activeIcon: _buildNavIcon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              Icons.notifications_none_rounded,
              badgeCount: unreadNotificationCount,
            ),
            activeIcon: _buildNavIcon(
              Icons.notifications_rounded,
              badgeCount: unreadNotificationCount,
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline_rounded),
            activeIcon: _buildNavIcon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, {int badgeCount = 0}) {
    return SizedBox(
      width: 30,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(icon, size: 24),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -6,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  _formatBadgeCount(badgeCount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatBadgeCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return '$count';
  }
}
