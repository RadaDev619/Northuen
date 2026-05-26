import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/pickdrop_model.dart';
import '../models/tracking_point_model.dart';

class RealtimeTrackingService {
  RealtimeChannel? _channel;

  bool get available => AppConfig.hasSupabaseRealtime;

  Future<void> subscribe({
    required String deliveryId,
    required void Function(TrackingPoint point) onPoint,
  }) async {
    if (!available) return;
    await unsubscribe();
    final client = Supabase.instance.client;
    _channel = client
        .channel('delivery_tracking:$deliveryId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'delivery_tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'delivery_id',
            value: deliveryId,
          ),
          callback: (payload) {
            onPoint(TrackingPoint.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  Future<void> subscribePickDrop({
    required String orderId,
    required void Function(DriverLiveLocation location) onLocation,
  }) async {
    if (!available) return;
    await unsubscribe();
    final client = Supabase.instance.client;
    _channel = client
        .channel('driver_live_locations:$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_live_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            onLocation(DriverLiveLocation.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  Future<void> subscribePickDropMessages({
    required String orderId,
    required void Function(PickDropMessage message) onMessage,
  }) async {
    if (!available) return;
    await unsubscribe();
    final client = Supabase.instance.client;
    _channel = client
        .channel('pickdrop_messages:$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pickdrop_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            onMessage(PickDropMessage.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe() async {
    final channel = _channel;
    if (channel != null && AppConfig.hasSupabaseRealtime) {
      await Supabase.instance.client.removeChannel(channel);
    }
    _channel = null;
  }
}
