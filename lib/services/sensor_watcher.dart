import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'emergency_service.dart';

class SensorWatcher extends ChangeNotifier {
  SensorWatcher({
    required EmergencyService emergencyService,
    SupabaseClient? client,
    this.heartRateThreshold = 120,
  })  : _emergencyService = emergencyService,
        _client = client ?? Supabase.instance.client;

  final EmergencyService _emergencyService;
  final SupabaseClient _client;
  final int heartRateThreshold;

  RealtimeChannel? _channel;
  int? lastHeartRate;
  LatLng? lastLocation;
  bool loadingEmergency = false;
  String? errorMessage;
  EmergencyAlertData? pendingAlert;

  bool get isListening => _channel != null;

  Future<void> startListening() async {
    if (_channel != null) return;
    final channel = _client.channel('sensor_data_listener');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sensor_data',
      callback: (payload) => _handlePayload(payload),
    );
    channel.subscribe();
    _channel = channel;
  }

  Future<void> _handlePayload(PostgresChangePayload payload) async {
    try {
      final record = payload.newRecord;
      final hr = _asInt(record['heart_rate'] ?? record['bpm']);
      final lat = _asDouble(record['latitude'] ?? record['lat']);
      final lng = _asDouble(record['longitude'] ?? record['lng']);
      if (hr != null) {
        lastHeartRate = hr;
      }
      if (lat != null && lng != null) {
        lastLocation = LatLng(lat, lng);
      }
      notifyListeners();

      if (hr != null && lat != null && lng != null && hr > heartRateThreshold) {
        await _triggerEmergency(hr, LatLng(lat, lng));
      }
    } catch (e) {
      errorMessage = 'Gagal memproses data sensor: $e';
      notifyListeners();
    }
  }

  Future<void> _triggerEmergency(int heartRate, LatLng origin) async {
    if (loadingEmergency) return;
    loadingEmergency = true;
    notifyListeners();
    try {
      final nearest = await _emergencyService.findNearestHospitalBasic(origin) ??
          (await _emergencyService.findNearbyHospitals(origin, initialRadius: 10000))
              .firstOrNull;
      if (nearest == null) {
        errorMessage = 'Tidak ditemukan rumah sakit dalam radius 20 km.';
        loadingEmergency = false;
        notifyListeners();
        return;
      }

      final route = await _emergencyService.fetchRoutePolyline(
        origin: origin,
        destination: nearest.location,
      );

      pendingAlert = EmergencyAlertData(
        bpm: heartRate,
        location: origin,
        triggeredAt: DateTime.now(),
        nearestHospital: nearest,
        routePoints: route,
      );
    } finally {
      loadingEmergency = false;
      notifyListeners();
    }
  }

  void consumeAlert() {
    pendingAlert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
    super.dispose();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
