import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SmartwatchLocationUpdate {
  SmartwatchLocationUpdate({
    required this.point,
    this.sentAt,
    required this.raw,
  });

  final LatLng point;
  final DateTime? sentAt;
  final Map<String, dynamic> raw;
}

class SmartwatchLocationService {
  SmartwatchLocationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  LatLng? lastKnownLocation;

  /// Subscribe to realtime Supabase channel `location:{userId}` and emit every
  /// new coordinate as `SmartwatchLocationUpdate`.
  Stream<SmartwatchLocationUpdate> watchLocationUpdates(String userId) {
    _closeChannel();
    final controller = StreamController<SmartwatchLocationUpdate>.broadcast();
    final channel = _client.channel('location:$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'location_updates',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final record = payload.newRecord;
        final lat = _toDouble(record['lat']);
        final lng = _toDouble(record['lng']);
        if (lat == null || lng == null) return;

        final timestampRaw = record['sent_at']?.toString();
        final update = SmartwatchLocationUpdate(
          point: LatLng(lat, lng),
          sentAt: timestampRaw != null ? DateTime.tryParse(timestampRaw) : null,
          raw: record,
        );
        lastKnownLocation = update.point;
        controller.add(update);
      },
    );

    channel.subscribe();
    _channel = channel;
    controller.onCancel = _closeChannel;
    return controller.stream;
  }

  /// Convenience wrapper that exposes only LatLng points.
  Stream<LatLng> watchLocationStream(String userId) {
    return watchLocationUpdates(userId).map((update) => update.point);
  }

  Future<void> close() async {
    _closeChannel();
  }

  void _closeChannel() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
