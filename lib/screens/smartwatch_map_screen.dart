import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/smartwatch_location_service.dart';

/// Simple map screen that subscribes to smartwatch GPS and keeps the marker
/// and camera in sync with the latest coordinate.
class SmartwatchMapScreen extends StatefulWidget {
  const SmartwatchMapScreen({
    super.key,
    required this.userId,
    required this.locationService,
    this.mapPadding = EdgeInsets.zero,
  });

  final String userId;
  final SmartwatchLocationService locationService;
  final EdgeInsets mapPadding;

  @override
  State<SmartwatchMapScreen> createState() => _SmartwatchMapScreenState();
}

class _SmartwatchMapScreenState extends State<SmartwatchMapScreen> {
  StreamSubscription<SmartwatchLocationUpdate>? _sub;
  GoogleMapController? _mapController;
  LatLng? _latest;
  DateTime? _sentAt;

  @override
  void initState() {
    super.initState();
    _latest = widget.locationService.lastKnownLocation;
    _sub = widget.locationService
        .watchLocationUpdates(widget.userId)
        .listen((update) {
      setState(() {
        _latest = update.point;
        _sentAt = update.sentAt;
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(update.point));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    if (_latest != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('smartwatch'),
          position: _latest!,
          infoWindow: const InfoWindow(title: 'Smartwatch'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Smartwatch Live Location')),
      body: Stack(
        children: [
          GoogleMap(
            padding: widget.mapPadding,
            initialCameraPosition: CameraPosition(
              target: _latest ?? const LatLng(0, 0),
              zoom: _latest == null ? 3 : 17,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: markers,
            myLocationEnabled: false,
            compassEnabled: true,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_latest == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Menunggu lokasi smartwatch...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lokasi Smartwatch',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${_latest!.latitude.toStringAsFixed(6)} • '
              'Lng: ${_latest!.longitude.toStringAsFixed(6)}',
            ),
            if (_sentAt != null)
              Text('Dikirim: ${_sentAt!.toLocal().toIso8601String()}'),
          ],
        ),
      ),
    );
  }
}
