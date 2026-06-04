import 'package:flutter/material.dart';

import '../../constants/constants.dart';
import '../active/active_screen.dart';
import '../home/screen/volunteer_feed.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

/// The volunteer-facing app shell: a persistent bottom navigation bar wrapping
/// the four volunteer tabs.
///
/// Tabs are kept alive with an [IndexedStack] so each one preserves its scroll
/// position and local state when the user switches away and back. The MAP tab
/// is a placeholder ([MapPlaceholderScreen]) a teammate will replace.
class VolunteerShell extends StatefulWidget {
  const VolunteerShell({super.key});

  @override
  State<VolunteerShell> createState() => _VolunteerShellState();
}

class _VolunteerShellState extends State<VolunteerShell> {
  int _index = 0;

  static const _tabs = <_NavTab>[
    _NavTab(icon: Icons.format_list_bulleted_rounded, label: 'Feed'),
    _NavTab(icon: Icons.map_outlined, label: 'Map'),
    _NavTab(icon: Icons.check_circle_outline, label: 'Active'),
    _NavTab(icon: Icons.person_outline, label: 'Profile'),
  ];

  // Built once and kept alive by the IndexedStack.
  static const _screens = <Widget>[
    VolunteerFeedScreen(),
    MapPlaceholderScreen(),
    ActiveScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _BottomNav(
        tabs: _tabs,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<_NavTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == index;
              final color =
                  selected ? AppColors.navActive : AppColors.textSecondary;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
