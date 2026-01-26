import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppBarWithActions extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final bool showLanguageToggle;

  const AppBarWithActions({
    super.key,
    required this.title,
    this.actions,
    this.showThemeToggle = true,
    this.showLanguageToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(title),
      elevation: 0,
      actions: [
        if (showLanguageToggle)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: const Icon(Icons.language_rounded),
                tooltip: 'Ubah Bahasa',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur perubahan bahasa akan segera hadir'),
                    ),
                  );
                },
              );
            },
          ),
        if (showThemeToggle)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip: themeProvider.isDarkMode
                    ? 'Mode Terang'
                    : 'Mode Gelap',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

