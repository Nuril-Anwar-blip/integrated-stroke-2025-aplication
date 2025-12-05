import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/emergency_service.dart';

class MapsRouteScreen extends StatefulWidget {
  const MapsRouteScreen({
    super.key,
    required this.userLocation,
    required this.hospital,
    required this.routePoints,
  });

  final LatLng userLocation;
  final NearbyHospital hospital;
  final List<LatLng> routePoints;

  @override
  State<MapsRouteScreen> createState() => _MapsRouteScreenState();
}

class _MapsRouteScreenState extends State<MapsRouteScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    final hasRoute = widget.routePoints.isNotEmpty;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user'),
        position: widget.userLocation,
        infoWindow: const InfoWindow(title: 'Anda'),
      ),
      Marker(
        markerId: const MarkerId('hospital'),
        position: widget.hospital.location,
        infoWindow: InfoWindow(title: widget.hospital.name),
      ),
    };

    final polylines = <Polyline>{};
    if (hasRoute) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 6,
          points: widget.routePoints,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rute ke Rumah Sakit')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.userLocation,
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) async {
              _controller.complete(controller);
              if (hasRoute) {
                await _fitBounds(controller);
              }
            },
            myLocationEnabled: false,
            compassEnabled: true,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () async {
                final controller = await _controller.future;
                await _fitBounds(controller);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fitBounds(GoogleMapController controller) async {
    final allPoints = [
      widget.userLocation,
      widget.hospital.location,
      ...widget.routePoints,
    ];
    if (allPoints.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final p in allPoints) {
      minLat = minLat == null ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = maxLat == null ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = minLng == null ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = maxLng == null ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }
}
