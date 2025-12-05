// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'smartwatch_heart_rate_service.dart';
import 'smartwatch_location_service.dart';

const int HEART_RATE_EMERGENCY_THRESHOLD = 120;

class EmergencyService {
  EmergencyService({
    required this.placesApiKey,
    SupabaseClient? supabaseClient,
    http.Client? httpClient,
    this.emergencyNumber = '112',
    this.defaultWhatsappNumber,
    this.defaultSmsNumber,
    this.defaultRadiusMeters = 5000,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _http = httpClient ?? http.Client();

  final String placesApiKey;
  final SupabaseClient _supabase;
  final http.Client _http;
  final String emergencyNumber;
  final String? defaultWhatsappNumber;
  final String? defaultSmsNumber;
  final int defaultRadiusMeters;

  /// Basic nearest hospital search using Nearby Search (keyword=hospital, radius=10km).
  /// Returns first result (assumed nearest) and enriches with phone (if available).
  Future<NearbyHospital?> findNearestHospitalBasic(
    LatLng origin, {
    int radius = 10000,
  }) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${origin.latitude},${origin.longitude}'
      '&radius=$radius&keyword=hospital&key=$placesApiKey',
    );
    try {
      final res = await _http.get(uri);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>? ?? {};
      final loc = geometry['location'] as Map<String, dynamic>? ?? {};
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      String? phone;
      if (first['place_id'] != null) {
        phone = await _getPhoneNumber(first['place_id'].toString());
      }

      final hospitalLoc = LatLng(lat, lng);
      return NearbyHospital(
        name: first['name']?.toString() ?? 'Rumah Sakit',
        address:
            (first['vicinity'] ?? first['formatted_address'] ?? '-').toString(),
        location: hospitalLoc,
        placeId: first['place_id']?.toString(),
        distanceMeters: _haversine(origin, hospitalLoc),
        phoneNumber: phone,
      );
    } catch (_) {
      return null;
    }
  }

  /// Robust hospital search with multi-type fallback and radius expansion.
  /// Tries nearbysearch with multiple types, then textsearch as last resort.
  Future<List<NearbyHospital>> findNearbyHospitals(
    LatLng origin, {
    int initialRadius = 5000,
  }) async {
    final radii = <int>{
      initialRadius,
      10000,
      20000,
    }.where((r) => r > 0 && r <= 50000).toList();

    final searchSteps = <_SearchStep>[
      _SearchStep(type: 'hospital', keyword: 'rumah sakit'),
      _SearchStep(type: 'clinic', keyword: 'rumah sakit'),
      _SearchStep(type: 'doctor', keyword: 'rumah sakit'),
      _SearchStep(type: 'physiotherapist', keyword: 'rumah sakit'),
      _SearchStep(keyword: 'rumah sakit'),
    ];

    for (final radius in radii) {
      for (final step in searchSteps) {
        final results = await _nearbySearch(
          origin: origin,
          radius: radius,
          type: step.type,
          keyword: step.keyword,
        );
        if (results.isNotEmpty) {
          return results;
        }
      }
    }

    // Text search fallback
    final textResults = await _textSearch(
      origin: origin,
      radius: radii.last,
      query: 'rumah sakit dekat saya',
    );
    if (textResults.isNotEmpty) return textResults;

    return [];
  }

  /// Fetch route polyline from Google Directions API. Returns decoded LatLng list.
  Future<List<LatLng>> fetchRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving&key=$placesApiKey',
    );
    try {
      final res = await _http.get(uri);
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List<dynamic>? ?? <dynamic>[];
      if (routes.isEmpty) return [];
      final polyline = routes.first['overview_polyline']?['points']?.toString();
      if (polyline == null || polyline.isEmpty) return [];
      return _decodePolyline(polyline);
    } catch (_) {
      return [];
    }
  }

  Future<void> logEmergencyEvent({
    required String userId,
    required int bpm,
    required LatLng location,
    NearbyHospital? hospital,
    DateTime? timestamp,
  }) async {
    try {
      await _supabase.from('emergency_events').insert({
        'user_id': userId,
        'bpm': bpm,
        'lat': location.latitude,
        'lng': location.longitude,
        'triggered_at': (timestamp ?? DateTime.now()).toIso8601String(),
        'nearest_hospital': hospital == null
            ? null
            : {
                'name': hospital.name,
                'address': hospital.address,
                'lat': hospital.location.latitude,
                'lng': hospital.location.longitude,
                'distance_m': hospital.distanceMeters,
                'place_id': hospital.placeId,
              },
      });
    } catch (_) {
      // Ignore logging failures to keep emergency flow responsive.
    }
  }

  /// Binds both realtime streams (heart rate + smartwatch location) and
  /// invokes [onAlert] when BPM exceeds [HEART_RATE_EMERGENCY_THRESHOLD].
  /// Example:
  /// ```
  /// final bindings = emergencyService.bindAutoEmergency(
  ///   heartRateService: hr,
  ///   locationService: loc,
  ///   userId: userId,
  ///   onAlert: (alert) => showDialog(
  ///     context: context,
  ///     builder: (_) => EmergencyAlertScreen(
  ///       alert: alert,
  ///       emergencyService: emergencyService,
  ///     ),
  ///   ),
  /// );
  /// ```
  EmergencySubscriptions bindAutoEmergency({
    required SmartwatchHeartRateService heartRateService,
    required SmartwatchLocationService locationService,
    required String userId,
    required void Function(EmergencyAlertData alert) onAlert,
    bool autoDial = false,
    String? whatsappNumber,
    String? smsNumber,
  }) {
    SmartwatchLocationUpdate? latestLocation;
    final locationSub = locationService.watchLocationUpdates(userId).listen(
      (update) => latestLocation = update,
    );

    final heartRateSub = heartRateService.watchHeartRateStream(userId).listen(
      (sample) async {
        if (sample.bpm <= HEART_RATE_EMERGENCY_THRESHOLD) return;
        final loc = latestLocation?.point ?? locationService.lastKnownLocation;
        if (loc == null) return;

        final hospitals = await findNearbyHospitals(loc);
        final nearest = hospitals.isNotEmpty ? hospitals.first : null;
        List<LatLng> routePoints = [];
        if (nearest != null) {
          routePoints = await fetchRoutePolyline(
            origin: loc,
            destination: nearest.location,
          );
        }
        final alert = EmergencyAlertData(
          bpm: sample.bpm,
          location: loc,
          nearestHospital: nearest,
          triggeredAt: sample.timestamp ?? DateTime.now(),
          routePoints: routePoints,
        );

        await logEmergencyEvent(
          userId: sample.userId,
          bpm: sample.bpm,
          location: loc,
          hospital: nearest,
          timestamp: alert.triggeredAt,
        );

        onAlert(alert);

        final message = buildEmergencyMessage(
          sample.bpm,
          loc,
          hospital: nearest,
        );

        if (autoDial) {
          unawaited(_safeLaunch(() => launchEmergencyCall()));
        }

        final waTarget = (whatsappNumber ?? defaultWhatsappNumber)?.trim();
        if (waTarget != null && waTarget.isNotEmpty) {
          unawaited(_safeLaunch(() => launchWhatsApp(waTarget, message)));
        }

        final smsTarget = (smsNumber ?? defaultSmsNumber)?.trim();
        if (smsTarget != null && smsTarget.isNotEmpty) {
          unawaited(_safeLaunch(() => sendSms(smsTarget, message)));
        }
      },
    );

    return EmergencySubscriptions(
      heartRate: heartRateSub,
      location: locationSub,
    );
  }

  String buildEmergencyMessage(
    int bpm,
    LatLng location, {
    NearbyHospital? hospital,
  }) {
    final buffer = StringBuffer()
      ..writeln('Darurat! Detak jantung $bpm bpm.')
      ..writeln(
        'Lokasi: https://www.google.com/maps?q=${location.latitude},${location.longitude}',
      );
    if (hospital != null) {
      final distance =
          hospital.distanceMeters != null ? hospital.distanceMeters! / 1000 : null;
      final distText = distance == null ? '' : ' (${distance.toStringAsFixed(1)} km)';
      buffer.writeln('RS terdekat: ${hospital.name}$distText');
    }
    return buffer.toString().trim();
  }

  Future<void> launchEmergencyCall([String? number]) async {
    final target = (number ?? emergencyNumber).trim();
    await launchUrl(Uri.parse('tel:$target'));
  }

  Future<void> launchWhatsApp(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    await launchUrl(Uri.parse('https://wa.me/$phone?text=$encoded'));
  }

  Future<void> sendSms(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    await launchUrl(Uri.parse('sms:$phone?body=$encoded'));
  }

  Future<void> dispose() async {
    _http.close();
  }

  Future<void> _safeLaunch(Future<void> Function() launcher) async {
    try {
      await launcher();
    } catch (_) {}
  }

  double _haversine(LatLng a, LatLng b) {
    const earthRadius = 6371000; // meters
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    return 2 * earthRadius * asin(min(1, sqrt(h)));
  }

  double _degToRad(double deg) => deg * pi / 180.0;

  Future<String?> _getPhoneNumber(String placeId) async {
    final params = {
      'place_id': placeId,
      'fields': 'formatted_phone_number',
      'key': placesApiKey,
    };
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      params,
    );
    try {
      final res = await _http.get(uri);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>? ?? {};
      return result['formatted_phone_number']?.toString();
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final polylinePoints = PolylinePoints();
    final result = polylinePoints.decodePolyline(encoded);
    return result
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);
  }

  Future<List<NearbyHospital>> _nearbySearch({
    required LatLng origin,
    required int radius,
    String? type,
    String? keyword,
  }) async {
    final params = <String, String>{
      'location': '${origin.latitude},${origin.longitude}',
      'radius': '$radius',
      'key': placesApiKey,
      if (type != null) 'type': type,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
    };

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      params,
    );

    try {
      final res = await _http.get(uri);
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
      final hospitals = _mapPlacesResults(origin, results);
      return hospitals;
    } catch (_) {
      return [];
    }
  }

  Future<List<NearbyHospital>> _textSearch({
    required LatLng origin,
    required int radius,
    required String query,
  }) async {
    final params = <String, String>{
      'query': query,
      'location': '${origin.latitude},${origin.longitude}',
      'radius': '$radius',
      'key': placesApiKey,
    };
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      params,
    );
    try {
      final res = await _http.get(uri);
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? <dynamic>[];
      return _mapPlacesResults(origin, results);
    } catch (_) {
      return [];
    }
  }

  List<NearbyHospital> _mapPlacesResults(
    LatLng origin,
    List<dynamic> rawResults,
  ) {
    final hospitals = <NearbyHospital>[];
    for (final item in rawResults) {
      if (item is! Map<String, dynamic>) continue;
      final geometry = item['geometry'] as Map<String, dynamic>? ?? {};
      final loc = geometry['location'] as Map<String, dynamic>? ?? {};
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final hospitalLoc = LatLng(lat, lng);
      hospitals.add(
        NearbyHospital(
          name: item['name']?.toString() ?? 'Rumah Sakit',
          address: (item['vicinity'] ?? item['formatted_address'] ?? '-')
              .toString(),
          location: hospitalLoc,
          placeId: item['place_id']?.toString(),
          distanceMeters: _haversine(origin, hospitalLoc),
          phoneNumber: item['formatted_phone_number']?.toString(),
        ),
      );
    }

    hospitals.sort(
      (a, b) => (a.distanceMeters ?? double.infinity)
          .compareTo(b.distanceMeters ?? double.infinity),
    );
    return hospitals;
  }
}

class NearbyHospital {
  NearbyHospital({
    required this.name,
    required this.address,
    required this.location,
    this.placeId,
    this.distanceMeters,
    this.phoneNumber,
  });

  final String name;
  final String address;
  final LatLng location;
  final String? placeId;
  final double? distanceMeters;
  final String? phoneNumber;
}

class _SearchStep {
  _SearchStep({this.type, this.keyword});

  final String? type;
  final String? keyword;
}

class EmergencyAlertData {
  EmergencyAlertData({
    required this.bpm,
    required this.location,
    required this.triggeredAt,
    this.nearestHospital,
    this.routePoints = const [],
  });

  final int bpm;
  final LatLng location;
  final DateTime triggeredAt;
  final NearbyHospital? nearestHospital;
  final List<LatLng> routePoints;
}

class EmergencySubscriptions {
  EmergencySubscriptions({
    required this.heartRate,
    required this.location,
  });

  final StreamSubscription<HeartRateSample> heartRate;
  final StreamSubscription<SmartwatchLocationUpdate> location;

  Future<void> cancel() async {
    await heartRate.cancel();
    await location.cancel();
  }
}
