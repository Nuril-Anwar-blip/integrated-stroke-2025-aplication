import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyCallScreen extends StatefulWidget {
  const EmergencyCallScreen({Key? key}) : super(key: key);

  @override
  _EmergencyCallScreenState createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  late Timer _timer;
  int _countdown = 3; // Countdown dimulai dari 3 sesuai gambar
  bool _isCalling = false;
  bool _isPreparing = true;

  LatLng? _currentLatLng;
  _HospitalTarget? _nearestHospital;
  String? _emergencyContactPhone;

  static const String _placesApiKey = "AIzaSyBggaOmseqyHiiS7KYgOwquqXkdXJgc5dY";

  @override
  void initState() {
    super.initState();
    _prepareEmergency().then((_) {
      _isPreparing = false;
      if (mounted) setState(() {});
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() {
            _countdown--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isCalling = true;
          });
          _executeEmergencyActions();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _prepareEmergency() async {
    try {
      await _ensureLocation();
      await _loadEmergencyContact();
      await _findNearestHospital();
    } catch (_) {}
  }

  Future<void> _ensureLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  Future<void> _loadEmergencyContact() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final row = await client
          .from('users')
          .select('emergency_contact')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null && row['emergency_contact'] is Map) {
        final ec = Map<String, dynamic>.from(row['emergency_contact'] as Map);
        final phone = ec['phone_number']?.toString();
        if (phone != null && phone.trim().isNotEmpty) {
          _emergencyContactPhone = phone;
        }
      }
    } catch (_) {}
  }

  Future<void> _findNearestHospital() async {
    if (_currentLatLng == null) return;
    final candidates = await _searchNearby(type: 'hospital', radius: 20000);
    if (candidates.isEmpty) {
      final c1 = await _searchNearby(type: 'clinic', radius: 20000);
      if (c1.isNotEmpty) {
        _nearestHospital = c1.first;
        return;
      }
      final c2 = await _searchNearby(type: 'health', radius: 20000);
      if (c2.isNotEmpty) {
        _nearestHospital = c2.first;
        return;
      }
    } else {
      _nearestHospital = candidates.first;
    }
  }

  Future<List<_HospitalTarget>> _searchNearby({
    required String type,
    required double radius,
  }) async {
    try {
      final url = Uri.parse("https://places.googleapis.com/v1/places:searchNearby");
      final payload = {
        "includedTypes": [type],
        "languageCode": "id",
        "maxResultCount": 10,
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
        "X-Goog-Api-Key": _placesApiKey,
        "X-Goog-FieldMask":
            "places.displayName,places.formattedAddress,places.location,places.nationalPhoneNumber",
      };
      final res = await http.post(url, headers: headers, body: jsonEncode(payload));
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body);
      if (decoded["places"] == null) return [];
      final List<_HospitalTarget> result = [];
      for (final p in decoded["places"]) {
        final loc = p["location"];
        result.add(
          _HospitalTarget(
            name: p["displayName"]?.toString() ?? "Rumah Sakit",
            address: p["formattedAddress"]?.toString() ?? "",
            latitude: (loc["latitude"] as num).toDouble(),
            longitude: (loc["longitude"] as num).toDouble(),
            phone: p["nationalPhoneNumber"]?.toString(),
          ),
        );
      }
      result.sort((a, b) => _distance(a).compareTo(_distance(b)));
      return result;
    } catch (_) {
      return [];
    }
  }

  double _distance(_HospitalTarget h) {
    if (_currentLatLng == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      h.latitude,
      h.longitude,
    );
  }

  Future<void> _executeEmergencyActions() async {
    final locText = (_currentLatLng != null)
        ? "https://www.google.com/maps?q=${_currentLatLng!.latitude},${_currentLatLng!.longitude}"
        : null;
    try {
      if (_nearestHospital?.phone != null && _nearestHospital!.phone!.trim().isNotEmpty) {
        final tel = Uri.parse('tel:${_nearestHospital!.phone!.replaceAll(' ', '')}');
        await launchUrl(tel);
        if (locText != null) {
          final smsHospital = Uri.parse('sms:${_nearestHospital!.phone}?body=${Uri.encodeComponent('Lokasi darurat: $locText')}');
          await launchUrl(smsHospital);
        }
      }
    } catch (_) {}
    try {
      if (_emergencyContactPhone != null && _emergencyContactPhone!.trim().isNotEmpty) {
        final tel2 = Uri.parse('tel:${_emergencyContactPhone!.replaceAll(' ', '')}');
        await launchUrl(tel2);
        if (locText != null) {
          final msg = 'Bantuan darurat diperlukan. Lokasi: $locText';
          final sms = Uri.parse('sms:${_emergencyContactPhone}?body=${Uri.encodeComponent(msg)}');
          await launchUrl(sms);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black54),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.favorite, color: Colors.red),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul
                  Text(
                    'Panggilan Darurat',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ikon-ikon utama
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      Icon(
                        Icons.family_restroom_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Tampilan Countdown atau Status Memanggil
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isPreparing
                        ? _buildPreparingStatus()
                        : _isCalling
                        ? _buildCallingStatus()
                        : _buildCountdownStatus(),
                  ),

                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Ikon Aksi di Bawah
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreparingStatus() {
    return Column(
      key: const ValueKey('preparing'),
      children: const [
        SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        SizedBox(height: 24),
        Text(
          'Menyiapkan lokasi & kontak...',
          style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Widget untuk status countdown
  Widget _buildCountdownStatus() {
    return Column(
      key: const ValueKey('countdown'),
      children: [
        const Text(
          'SOS DIMULAI DALAM',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            '$_countdown',
            key: ValueKey<int>(_countdown), // Kunci penting untuk animasi
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'DETIK',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Widget untuk status "memanggil"
  Widget _buildCallingStatus() {
    return Column(
      key: const ValueKey('calling'),
      children: [
        SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          'Menghubungi Bantuan...',
          style: TextStyle(
            fontSize: 18,
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Widget untuk tombol-tombol aksi di bagian bawah
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(
            Icons.home_outlined,
            color: Colors.grey.shade600,
            size: 28,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.mail_outline, color: Colors.grey.shade600, size: 28),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.mic_none, color: Colors.grey.shade600, size: 28),
          onPressed: () {},
        ),
        // Tombol batalkan panggilan dibuat lebih menonjol
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            _timer.cancel(); // Membatalkan timer jika ditekan
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class _HospitalTarget {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  _HospitalTarget({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
  });
}
