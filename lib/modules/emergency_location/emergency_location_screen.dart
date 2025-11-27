import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class EmergencyLocationScreen extends StatefulWidget {
  const EmergencyLocationScreen({super.key});

  @override
  State<EmergencyLocationScreen> createState() =>
      _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
  // -------------------------------
  // 🔥 GANTI API KEY DI SINI
  // -------------------------------
  static const String apiKey = "AIzaSyBggaOmseqyHiiS7KYgOwquqXkdXJgc5dY";

  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLatLng;

  bool _loadingLocation = true;
  bool _loadingPlaces = false;
  String? _error;

  final Set<Marker> _markers = {};
  final List<_HospitalPlace> _places = [];

  static const LatLng fallbackCenter = LatLng(-6.1754, 106.8272);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getLocation();
    if (_currentLatLng != null) {
      await _fetchHospitalsGuaranteed();
    }
  }

  // ================================
  // 📍 AMBIL LOKASI
  // ================================
  Future<void> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _error = "Layanan lokasi perangkat nonaktif.";
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition();
      _currentLatLng = LatLng(pos.latitude, pos.longitude);

      _markers.add(
        Marker(
          markerId: const MarkerId("you"),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: "Lokasi Anda"),
        ),
      );

      if (!mounted) return;
      setState(() => _loadingLocation = false);
      _animateTo(_currentLatLng!, zoom: 15);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _error = "Gagal mendapatkan lokasi: $e";
      });
    }
  }

  // =============================================================
  // ⭐ METHOD UTAMA – DIJAMIN MENGEMBALIKAN RUMAH SAKIT
  // Dengan fallback strategi
  // =============================================================
  Future<void> _fetchHospitalsGuaranteed() async {
    setState(() {
      _loadingPlaces = true;
      _error = null;
    });

    _places.clear();
    _markers.removeWhere((m) => m.markerId.value != 'you');

    // 1️⃣ Coba "hospital"
    final primary = await _searchNearby(type: "hospital", radius: 20000);

    if (primary.isNotEmpty) {
      _places.addAll(primary);
      setState(() => _loadingPlaces = false);
      return;
    }

    // 2️⃣ Coba fallback: "clinic"
    final fallback1 = await _searchNearby(type: "clinic", radius: 20000);
    if (fallback1.isNotEmpty) {
      _places.addAll(fallback1);
      setState(() => _loadingPlaces = false);
      return;
    }

    // 3️⃣ Coba fallback: "health"
    final fallback2 = await _searchNearby(type: "health", radius: 20000);
    if (fallback2.isNotEmpty) {
      _places.addAll(fallback2);
      setState(() => _loadingPlaces = false);
      return;
    }

    setState(() {
      _loadingPlaces = false;
      _error = "Tidak ada rumah sakit dalam radius 20 km.";
    });
  }

  // =============================================================
  // 🔥 FUNCTION PLACES API NEW v1
  // =============================================================
  Future<List<_HospitalPlace>> _searchNearby({
    required String type,
    required double radius,
  }) async {
    if (_currentLatLng == null) return [];

    final url = Uri.parse(
      "https://places.googleapis.com/v1/places:searchNearby",
    );

    final payload = {
      "includedTypes": [type],
      "languageCode": "id",
      "maxResultCount": 20,
      "locationRestriction": {
        "circle": {
          "center": {
            "latitude": _currentLatLng!.latitude,
            "longitude": _currentLatLng!.longitude,
          },
          "radius": radius,
        },
      },
    };

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask":
          "places.displayName,places.formattedAddress,places.location,places.rating,places.nationalPhoneNumber",
    };

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error = "Gagal memuat data lokasi kesehatan.";
          });
        }
        return [];
      }

      final decoded = jsonDecode(res.body);

      if (decoded["places"] == null) return [];

      final List<_HospitalPlace> result = [];

      for (final p in decoded["places"]) {
        final loc = p["location"];
        result.add(
          _HospitalPlace.fromApi(
            p,
            LatLng(
              (loc["latitude"] as num).toDouble(),
              (loc["longitude"] as num).toDouble(),
            ),
            _currentLatLng!,
          ),
        );
      }

      result.sort((a, b) => a.distance.compareTo(b.distance));

      // update markers
      for (final hospital in result) {
        _markers.add(
          Marker(
            markerId: MarkerId(hospital.name),
            position: hospital.location,
            infoWindow: InfoWindow(
              title: hospital.name,
              snippet:
                  "${(hospital.distance / 1000).toStringAsFixed(2)} km • ${hospital.address}",
            ),
          ),
        );
      }

      if (mounted) setState(() {});
      return result;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat tempat: $e";
        });
      }
      return [];
    }
  }

  // =============================================================
  Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
    if (!_mapController.isCompleted) return;
    final c = await _mapController.future;
    c.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _openGoogleMaps(LatLng loc) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&travelmode=driving",
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka Maps: $e')));
      }
    }
  }

  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rumah Sakit Terdekat")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: fallbackCenter,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            onMapCreated: (c) => _mapController.complete(c),
          ),

          if (_loadingLocation || _loadingPlaces)
            Container(
              color: Colors.white70,
              child: const Center(child: CircularProgressIndicator()),
            ),

          if (_error != null)
            Positioned(
              top: 30,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

          if (_places.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _HospitalList(
                places: _places,
                onNavigate: (p) => _openGoogleMaps(p.location),
                onSelect: (p) => _animateTo(p.location),
                onCall: (p) async {
                  final phone = p.phoneNumber;
                  if (phone == null || phone.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nomor telepon rumah sakit tidak tersedia',
                        ),
                      ),
                    );
                    return;
                  }
                  final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                  await launchUrl(uri);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================
// MODEL
// =============================================================
class _HospitalPlace {
  final String name;
  final String address;
  final LatLng location;
  final double distance;
  final String? phoneNumber;

  _HospitalPlace({
    required this.name,
    required this.address,
    required this.location,
    required this.distance,
    this.phoneNumber,
  });

  factory _HospitalPlace.fromApi(
    Map<String, dynamic> json,
    LatLng coord,
    LatLng origin,
  ) {
    double dist = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      coord.latitude,
      coord.longitude,
    );

    return _HospitalPlace(
      name: json["displayName"] ?? "Tanpa Nama",
      address: json["formattedAddress"] ?? "Alamat tidak tersedia",
      location: coord,
      distance: dist,
      phoneNumber: json["nationalPhoneNumber"],
    );
  }
}

// =============================================================
// LIST WIDGET
// =============================================================
class _HospitalList extends StatelessWidget {
  final List<_HospitalPlace> places;
  final void Function(_HospitalPlace) onNavigate;
  final void Function(_HospitalPlace) onSelect;
  final void Function(_HospitalPlace) onCall;

  const _HospitalList({
    super.key,
    required this.places,
    required this.onNavigate,
    required this.onSelect,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: Colors.white,
      child: ListView.builder(
        itemCount: places.length,
        itemBuilder: (context, i) {
          final p = places[i];
          return ListTile(
            title: Text(p.name),
            subtitle: Text(
              "${(p.distance / 1000).toStringAsFixed(2)} km • ${p.address}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call_rounded, color: Colors.green),
                  onPressed: () => onCall(p),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.blue,
                  ),
                  onPressed: () => onNavigate(p),
                ),
              ],
            ),
            onTap: () => onSelect(p),
          );
        },
      ),
    );
  }
}
