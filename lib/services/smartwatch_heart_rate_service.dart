import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeartRateSample {
  HeartRateSample({
    required this.bpm,
    required this.userId,
    this.timestamp,
    required this.raw,
  });

  final int bpm;
  final String userId;
  final DateTime? timestamp;
  final Map<String, dynamic> raw;
}

class SmartwatchHeartRateService {
  SmartwatchHeartRateService({
    SupabaseClient? client,
    List<String>? tables,
  })  : _client = client ?? Supabase.instance.client,
        _tables = tables ?? const ['heart_rate_data', 'sensor_data'];

  final SupabaseClient _client;
  final List<String> _tables;
  RealtimeChannel? _channel;

  /// Subscribe to realtime heart rate feed from smartwatch.
  Stream<HeartRateSample> watchHeartRateStream(String userId) {
    _closeChannel();
    final controller = StreamController<HeartRateSample>.broadcast();
    final channel = _client.channel('heart_rate:$userId');

    for (final table in _tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) => _handlePayload(
          payload,
          controller,
          fallbackUserId: userId,
        ),
      );
    }

    channel.subscribe();
    _channel = channel;
    controller.onCancel = _closeChannel;
    return controller.stream;
  }

  void _handlePayload(
    PostgresChangePayload payload,
    StreamController<HeartRateSample> controller, {
    required String fallbackUserId,
  }) {
    final record = payload.newRecord;
    final bpmValue = record['bpm'];
    final bpm = (bpmValue is num) ? bpmValue.toInt() : int.tryParse('$bpmValue');
    if (bpm == null) return;

    final tsRaw = record['timestamp']?.toString() ?? record['sent_at']?.toString();
    final ts = tsRaw != null ? DateTime.tryParse(tsRaw) : null;

    controller.add(
      HeartRateSample(
        bpm: bpm,
        userId: record['user_id']?.toString() ?? fallbackUserId,
        timestamp: ts,
        raw: record,
      ),
    );
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
}
