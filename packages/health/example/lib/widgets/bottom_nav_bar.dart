import 'package:flutter/material.dart';
import '../utils/colors1.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      label: '',
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.gradientLightBlue.withOpacity(0.25) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.gradientBlue : AppColors.iconInactive,
              size: isActive ? 28 : 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.gradientBlue : AppColors.iconInactive,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap, // ✅ Call parent’s onTap
          selectedFontSize: 0,
          unselectedFontSize: 0,
          items: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: "Home",
              isActive: currentIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: "Profile",
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.notifications_none,
              activeIcon: Icons.notifications,
              label: "Alerts",
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: "Settings",
              isActive: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }
}
