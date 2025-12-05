import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/emergency_service.dart';
import '../../screens/maps_route_screen.dart';

class EmergencyLocationScreen extends StatefulWidget {
  const EmergencyLocationScreen({super.key});

  @override
  State<EmergencyLocationScreen> createState() =>
      _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
  // Ganti API key di sini atau gunakan dotenv.
  static const String apiKey = "AIzaSyBggaOmseqyHiiS7KYgOwquqXkdXJgc5dY";
  late final EmergencyService _emergencyService =
      EmergencyService(placesApiKey: apiKey);

  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLatLng;

  bool _loadingLocation = true;
  bool _loadingPlaces = false;
  bool _loadingRoute = false;
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

  Future<void> _fetchHospitalsGuaranteed() async {
    setState(() {
      _loadingPlaces = true;
      _error = null;
    });

    _places.clear();
    _markers.removeWhere((m) => m.markerId.value != 'you');

    if (_currentLatLng == null) {
      setState(() {
        _loadingPlaces = false;
        _error = "Lokasi belum tersedia.";
      });
      return;
    }

    final hospitals = await _emergencyService.findNearbyHospitals(
      _currentLatLng!,
      initialRadius: 5000,
    );

    if (hospitals.isEmpty) {
      setState(() {
        _loadingPlaces = false;
        _error = "Tidak ditemukan rumah sakit dalam radius 20 km.";
      });
      return;
    }

    for (final h in hospitals) {
      final distance = h.distanceMeters ??
          Geolocator.distanceBetween(
            _currentLatLng!.latitude,
            _currentLatLng!.longitude,
            h.location.latitude,
            h.location.longitude,
          );
      _places.add(
        _HospitalPlace(
          name: h.name,
          address: h.address,
          location: h.location,
          distance: distance,
          phoneNumber: null,
        ),
      );
      _markers.add(
        Marker(
          markerId: MarkerId(h.name),
          position: h.location,
          infoWindow: InfoWindow(
            title: h.name,
            snippet:
                "${(distance / 1000).toStringAsFixed(2)} km • ${h.address}",
          ),
        ),
      );
    }

    setState(() {
      _loadingPlaces = false;
    });
  }

  Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
    if (!_mapController.isCompleted) return;
    final c = await _mapController.future;
    c.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _routeToNearest() async {
    if (_currentLatLng == null) return;
    if (_places.isEmpty) {
      await _fetchHospitalsGuaranteed();
    }
    if (_places.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ditemukan RS terdekat')),
        );
      }
      return;
    }
    await _openRouteInternal(_places.first);
  }

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
          if (_loadingRoute)
            Container(
              color: Colors.black26,
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
                onNavigate: _openRouteInternal,
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
          Positioned(
            right: 16,
            bottom: _places.isNotEmpty ? 270 : 16,
            child: FloatingActionButton.extended(
              onPressed: _routeToNearest,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Rute RS Terdekat'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRouteInternal(_HospitalPlace place) async {
    if (_currentLatLng == null) return;
    setState(() => _loadingRoute = true);
    final points = await _emergencyService.fetchRoutePolyline(
      origin: _currentLatLng!,
      destination: place.location,
    );
    setState(() => _loadingRoute = false);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapsRouteScreen(
          userLocation: _currentLatLng!,
          hospital: NearbyHospital(
            name: place.name,
            address: place.address,
            location: place.location,
            distanceMeters: place.distance,
          ),
          routePoints: points,
        ),
      ),
    );
  }
}

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
}

class _HospitalList extends StatelessWidget {
  final List<_HospitalPlace> places;
  final void Function(_HospitalPlace) onNavigate;
  final void Function(_HospitalPlace) onSelect;
  final void Function(_HospitalPlace) onCall;

  const _HospitalList({
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
