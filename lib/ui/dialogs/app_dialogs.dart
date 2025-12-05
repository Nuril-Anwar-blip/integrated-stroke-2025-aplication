import 'package:flutter/material.dart';
import '../../services/emergency_service.dart';

class AppDialogs {
  static const double _radius = 16;

  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Berhasil',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AnimatedDialog(
        child: _BaseDialog(
          title: title,
          message: message,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String message,
    String title = 'Terjadi Kesalahan',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AnimatedDialog(
        child: _BaseDialog(
          title: title,
          message: message,
          icon: Icons.error,
          iconColor: Colors.red,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String message,
    String title = 'Konfirmasi',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _AnimatedDialog(
        child: _BaseDialog(
          title: title,
          message: message,
          icon: Icons.help,
          iconColor: Colors.blue,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showLoading(
    BuildContext context, {
    String message = 'Memuat...',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AnimatedDialog(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<bool?> showEmergencyAlert(
    BuildContext context,
    EmergencyAlertData alert, {
    String title = 'Peringatan Darurat',
  }) {
    final hospital = alert.nearestHospital;
    return showDialog<bool>(
      context: context,
      builder: (_) => _AnimatedDialog(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_radius),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BPM: ${alert.bpm}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Lokasi: ${alert.location.latitude.toStringAsFixed(5)}, '
                      '${alert.location.longitude.toStringAsFixed(5)}',
                    ),
                    const SizedBox(height: 8),
                    if (hospital != null) ...[
                      Text(
                        'RS Terdekat: ${hospital.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(hospital.address),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Lihat Rute'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BaseDialog extends StatelessWidget {
  const _BaseDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.actions,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDialogs._radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDialog extends StatefulWidget {
  const _AnimatedDialog({required this.child});

  final Widget child;

  @override
  State<_AnimatedDialog> createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<_AnimatedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
