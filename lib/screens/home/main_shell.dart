import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/communities')) return 2;
    if (location.startsWith('/status')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, selected: selectedIndex == 0, onTap: () => context.go('/home')),
                _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chats', index: 1, selected: selectedIndex == 1, onTap: () => context.go('/chats')),
                _NavItem(icon: Icons.public_rounded, label: 'Communities', index: 2, selected: selectedIndex == 2, onTap: () => context.go('/communities')),
                _NavItem(icon: Icons.circle_rounded, label: 'Status', index: 3, selected: selectedIndex == 3, onTap: () => context.go('/status')),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, selected: selectedIndex == 4, onTap: () => context.go('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
