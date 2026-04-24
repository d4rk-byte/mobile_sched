import 'dart:async';

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
import 'providers/schedule_provider.dart';
import 'widgets/app_opening_loading_screen.dart';
import 'widgets/faculty_profile_completion_dialog.dart';
import 'services/class_notification_service.dart';

const _kMinimumOpeningDuration = Duration(milliseconds: 3200);
const _kHomeTransitionDuration = Duration(milliseconds: 700);
const _kOpeningExitOverlayDuration = Duration(milliseconds: 180);
const _kOpeningExitOverlayMaxOpacity = 0.08;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final Timer _minimumOpeningTimer;
  bool _minimumOpeningElapsed = false;

  @override
  void initState() {
    super.initState();
    unawaited(ClassNotificationService().initialize());
    _minimumOpeningTimer = Timer(_kMinimumOpeningDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _minimumOpeningElapsed = true;
      });
    });
  }

  @override
  void dispose() {
    _minimumOpeningTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final showOpeningLoading =
        !_minimumOpeningElapsed || !authState.isInitialized;

    final homeChild = showOpeningLoading
        ? const AppOpeningLoadingScreen()
        : authState.isAuthenticated
            ? const MainScreen()
            : const WelcomePage();

    return AnimatedSwitcher(
      duration: _kHomeTransitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final isOpeningChild = child.key == const ValueKey('opening-loading');
        final isExitingOpening =
            isOpeningChild && animation.status == AnimationStatus.reverse;

        final fadeAnimation = isOpeningChild
            ? CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.82, curve: Curves.easeOutCubic),
                reverseCurve:
                    const Interval(0.0, 0.82, curve: Curves.easeOutCubic),
              )
            : animation;

        final overlayStart = (1 -
                (_kOpeningExitOverlayDuration.inMilliseconds /
                    _kHomeTransitionDuration.inMilliseconds))
            .clamp(0.0, 1.0)
            .toDouble();

        final openingOverlayOpacity = isExitingOpening
            ? Tween<double>(begin: 0, end: _kOpeningExitOverlayMaxOpacity)
                .animate(
                CurvedAnimation(
                  parent: ReverseAnimation(fadeAnimation),
                  curve: Interval(overlayStart, 1, curve: Curves.easeOutCubic),
                ),
              )
            : kAlwaysDismissedAnimation;

        final scale = Tween<double>(begin: 0.988, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scale, child: child),
            ),
            if (isExitingOpening)
              IgnorePointer(
                child: FadeTransition(
                  opacity: openingOverlayOpacity,
                  child: const ColoredBox(color: Color(0xFF030303)),
                ),
              ),
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey(
          showOpeningLoading
              ? 'opening-loading'
              : authState.isAuthenticated
                  ? 'main'
                  : 'welcome',
        ),
        child: homeChild,
      ),
    );
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

  void _refreshScheduleData() {
    final semester = ref.read(selectedSemesterProvider);
    ref.invalidate(scheduleProvider(semester));
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.whiteColor,
          border: Border(
            top: BorderSide(color: Color(0xFFF0F2F5), width: 1),
          ),
        ),
        child: BottomNavigationBar(
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            _refreshScheduleData();
          }

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
            activeIcon: _buildNavIcon(Icons.home_rounded, isSelected: true),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.calendar_month_outlined),
            activeIcon: _buildNavIcon(Icons.calendar_month_rounded, isSelected: true),
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
              isSelected: true,
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person_outline_rounded),
            activeIcon: _buildNavIcon(Icons.person_rounded, isSelected: true),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, {int badgeCount = 0, bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 26,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey<int>(badgeCount),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
                ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          width: isSelected ? 4 : 0,
          height: isSelected ? 4 : 0,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  String _formatBadgeCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return '$count';
  }
}
