import 'package:flutter/material.dart';

class FloatingNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;
  final String? photoUrl;
  final VoidCallback? onSosTap;

  const FloatingNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.body,
    this.photoUrl,
    this.onSosTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Stack(
        children: [
          body,
          // Floating Navbar
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 8,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.groups_rounded,
                    label: 'Komunitas',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                    isDark: isDark,
                  ),
                  // SOS Button (Center)
                  GestureDetector(
                    onTap: onSosTap,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sos_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                    isDark: isDark,
                    photoUrl: photoUrl,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final String? photoUrl;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = isDark ? Colors.grey[500] : Colors.grey[400];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null && label == 'Profil')
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? activeColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl!.isNotEmpty
                      ? Image.network(photoUrl!, fit: BoxFit.cover)
                      : Icon(icon, size: 20, color: inactiveColor),
                ),
              )
            else
              Icon(
                icon,
                size: 24,
                color: isActive ? activeColor : inactiveColor,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

