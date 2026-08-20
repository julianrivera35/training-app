import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/rest_timer_sheet.dart';
import 'today_screen.dart';
import 'week_screen.dart';
import 'nutrition_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  static const _screens = [
    TodayScreen(),
    WeekScreen(),
    NutritionScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      body: IndexedStack(
        index: p.tabIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RestMiniBar(),
          BottomNavigationBar(
        currentIndex: p.tabIndex,
        onTap: p.setTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today_outlined),     activeIcon: Icon(Icons.today),       label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week_outlined), activeIcon: Icon(Icons.calendar_view_week), label: 'Semana'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: 'Nutrición'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_outlined), activeIcon: Icon(Icons.show_chart), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),   activeIcon: Icon(Icons.settings),   label: 'Ajustes'),
        ],
          ),
        ],
      ),
    );
  }
}
