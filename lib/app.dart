import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/report/screens/report_screen.dart';
import 'features/scan/screens/scan_screen.dart';
import 'features/settings/screens/meal_time_setup_screen.dart';
import 'features/settings/screens/settings_screen.dart';

/// Widget gốc của ứng dụng CareLens
class CareLensApp extends StatelessWidget {
  const CareLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: const Locale('vi', 'VN'),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.scan: (_) => const ScanScreen(),
        AppRoutes.report: (_) => const ReportScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}

/// Shell điều hướng chính với BottomNavigationBar (3 tab)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _checkedMealTimes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMealTimesSetup());
  }

  /// Nếu meal_times_set = false (lần đầu cài app), buộc người dùng thiết lập giờ ăn.
  Future<void> _checkMealTimesSetup() async {
    if (_checkedMealTimes) return;
    _checkedMealTimes = true;

    final prefs = await SharedPreferences.getInstance();
    final isSet = prefs.getBool(AppKeys.mealTimesSet) ?? false;

    if (!isSet && mounted) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MealTimeSetupScreen(isFirstLaunch: true),
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
          barrierDismissible: false,
          fullscreenDialog: true,
        ),
      );
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.scan);
      return;
    }
    setState(() => _selectedIndex = index == 2 ? 1 : index);
  }

  int get _effectiveIndex => _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppConstants.animNormal,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _effectiveIndex == 0 ? const HomeScreen() : const ReportScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.navyMid, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _effectiveIndex == 0 ? 0 : 2,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_rounded),
              activeIcon: Icon(Icons.medication_rounded, size: 32),
              label: 'Lịch thuốc',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_rounded),
              activeIcon: Icon(Icons.camera_alt_rounded, size: 32),
              label: 'Quét ảnh',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded, size: 32),
              label: 'Báo cáo',
            ),
          ],
        ),
      ),
    );
  }
}
