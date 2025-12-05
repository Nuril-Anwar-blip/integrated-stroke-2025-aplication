import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import 'maps_route_screen.dart';
import '../ui/dialogs/app_dialogs.dart';

class EmergencyAlertScreen extends StatelessWidget {
  const EmergencyAlertScreen({
    super.key,
    required this.alert,
    required this.emergencyService,
    this.familyWhatsappNumber,
    this.familySmsNumber,
  });

  final EmergencyAlertData alert;
  final EmergencyService emergencyService;
  final String? familyWhatsappNumber;
  final String? familySmsNumber;

  /// Helper to show the reusable dialog and navigate to route screen when chosen.
  static Future<void> show(
    BuildContext context, {
    required EmergencyAlertData alert,
    required EmergencyService emergencyService,
  }) async {
    // Ensure polyline is ready if hospital exists
    var points = alert.routePoints;
    if (points.isEmpty && alert.nearestHospital != null) {
      points = await emergencyService.fetchRoutePolyline(
        origin: alert.location,
        destination: alert.nearestHospital!.location,
      );
    }

    final goToRoute = await AppDialogs.showEmergencyAlert(context, alert);
    if (goToRoute == true && alert.nearestHospital != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MapsRouteScreen(
            userLocation: alert.location,
            hospital: alert.nearestHospital!,
            routePoints: points,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospital = alert.nearestHospital;
    final message = emergencyService.buildEmergencyMessage(
      alert.bpm,
      alert.location,
      hospital: hospital,
    );

    return AlertDialog(
      title: const Text('Detak jantung melebihi batas!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BPM: ${alert.bpm} (> $HEART_RATE_EMERGENCY_THRESHOLD)'),
          Text(
            'Lokasi: ${alert.location.latitude.toStringAsFixed(5)}, '
            '${alert.location.longitude.toStringAsFixed(5)}',
          ),
          Text('Waktu: ${alert.triggeredAt.toLocal().toIso8601String()}'),
          if (hospital != null) ...[
            const SizedBox(height: 12),
            Text('RS Terdekat: ${hospital.name}'),
            Text('Alamat: ${hospital.address}'),
            if (hospital.distanceMeters != null)
              Text(
                'Jarak: ${(hospital.distanceMeters! / 1000).toStringAsFixed(2)} km',
              ),
            TextButton(
              onPressed: () async {
                var points = alert.routePoints;
                if (points.isEmpty) {
                  points = await emergencyService.fetchRoutePolyline(
                    origin: alert.location,
                    destination: hospital.location,
                  );
                }
                // ignore: use_build_context_synchronously
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MapsRouteScreen(
                      userLocation: alert.location,
                      hospital: hospital,
                      routePoints: points,
                    ),
                  ),
                );
              },
              child: const Text('Lihat rute'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        TextButton(
          onPressed: () => emergencyService.launchEmergencyCall(),
          child: Text('Call ${emergencyService.emergencyNumber}'),
        ),
        if (familyWhatsappNumber != null)
          TextButton(
            onPressed: () =>
                emergencyService.launchWhatsApp(familyWhatsappNumber!, message),
            child: const Text('WhatsApp Keluarga'),
          ),
        if (familySmsNumber != null)
          TextButton(
            onPressed: () =>
                emergencyService.sendSms(familySmsNumber!, message),
            child: const Text('SMS Lokasi'),
          ),
      ],
    );
  }

}
