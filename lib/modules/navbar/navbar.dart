import 'package:flutter/material.dart';

/// ===============================================================
/// CUSTOM NAVBAR (STYLE VIDEO)
/// ===============================================================
/// - Rounded / pill navbar
/// - Active tab punya background
/// - Profile tab pakai foto user (avatar)
/// - SOS tidak ada di navbar
/// ===============================================================
class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;

  /// avatar untuk tab profile
  final String? photoUrl;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.body,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: body,
      bottomNavigationBar: _PillNavbar(
        currentIndex: currentIndex,
        onTap: onTap,
        photoUrl: photoUrl,
      ),
    );
  }
}

class _PillNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? photoUrl;

  const _PillNavbar({
    required this.currentIndex,
    required this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavPillItem(
                  isActive: currentIndex == 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  activeColor: theme.primaryColor,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavPillItem(
                  isActive: currentIndex == 1,
                  icon: Icons.groups_rounded,
                  label: 'Komunitas',
                  activeColor: theme.primaryColor,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _NavPillItem(
                  isActive: currentIndex == 2,
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  activeColor: theme.primaryColor,
                  onTap: () => onTap(2),
                ),
              ),
              Expanded(
                child: _ProfileNavItem(
                  isActive: currentIndex == 3,
                  label: 'Profil',
                  activeColor: theme.primaryColor,
                  photoUrl: photoUrl,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey[500];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isActive ? activeColor : inactive),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isActive ? activeColor : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavItem extends StatelessWidget {
  final bool isActive;
  final String label;
  final Color activeColor;
  final String? photoUrl;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.isActive,
    required this.label,
    required this.activeColor,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey[500];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? activeColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? Image.network(photoUrl!, fit: BoxFit.cover)
                    : Icon(
                        Icons.person,
                        color: isActive ? activeColor : inactive,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isActive ? activeColor : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
