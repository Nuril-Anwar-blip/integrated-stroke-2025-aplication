import 'package:flutter/material.dart';
import 'package:integrated_stroke/modules/emergency_call/emergency_call_screen.dart';
import 'package:integrated_stroke/styles/colors/app_color.dart';
import 'package:integrated_stroke/modules/emergency_location/emergency_location_screen.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget? body;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (body != null) body!,
          // Label “Emergency” overlay (bebas overflow)
          Positioned(bottom: 72, left: 0, right: 0, child: Center()),
        ],
      ),

      // 🆘 FAB Tengah = Tombol Emergency utama
      floatingActionButton: FloatingActionButton(
        heroTag: "emergency_fab",
        backgroundColor: const Color(0xFFFF3B30),
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyCallScreen()),
          );
        },
        child: const Icon(
          Icons.local_phone_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: _BottomBar(currentIndex: currentIndex, onTap: onTap),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 10,
      color: Colors.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 60, // ✅ sedikit lebih tinggi supaya lega
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.people_alt_outlined,
                label: 'Komunitas',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              const SizedBox(width: 48), // ruang FAB tengah
              _NavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profil',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
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
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;
    final color = selected ? AppColor.primary : Colors.black54;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown, // ✅ biar auto menyesuaikan ruang
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Icon(icon, color: color, size: 22)),
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
