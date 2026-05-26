import { activeTrackingStatuses, terminalTrackingStatuses } from '../config.js';
import { supabase } from '../supabase.js';
import type { LatLng, RunnerLocationPayload, RouteSnapshot } from '../types/tracking.js';
import { computeRoute, snapToRoads } from './googleMaps.js';

const snapBuffers = new Map<string, RunnerLocationPayload[]>();
const lastSnapAt = new Map<string, number>();
const lastRouteAt = new Map<string, number>();

export async function ingestRunnerLocation(payload: RunnerLocationPayload) {
  const status = payload.status.toLowerCase();
  if (terminalTrackingStatuses.has(status)) {
    await stopTracking(payload.orderId, payload.runnerId);
    return { accepted: false, reason: 'tracking_stopped' };
  }

  if (!activeTrackingStatuses.has(status)) {
    return { accepted: false, reason: 'inactive_order_status' };
  }

  const locationRow = {
    order_id: payload.orderId,
    runner_id: payload.runnerId,
    status,
    lat: payload.lat,
    lng: payload.lng,
    heading: payload.heading ?? null,
    speed: payload.speed ?? null,
    accuracy: payload.accuracy ?? null,
    recorded_at: payload.timestamp
  };

  const { error: historyError } = await supabase
    .from('runner_location_history')
    .insert(locationRow);
  if (historyError) throw historyError;

  const { error: latestError } = await supabase
    .from('runner_locations_latest')
    .upsert({
      ...locationRow,
      updated_at: new Date().toISOString()
    }, { onConflict: 'order_id' });
  if (latestError) throw latestError;

  bufferForRoadSnapping(payload);
  await maybeSnapRecentPoints(payload.orderId, payload.runnerId);

  return { accepted: true };
}

export async function getTrackingSnapshot(orderId: string) {
  const [latest, route] = await Promise.all([
    supabase.from('runner_locations_latest').select('*').eq('order_id', orderId).maybeSingle(),
    supabase.from('delivery_routes').select('*').eq('order_id', orderId).maybeSingle()
  ]);

  if (latest.error) throw latest.error;
  if (route.error) throw route.error;

  return {
    latest: latest.data,
    route: route.data
  };
}

export async function recalculateRoute(params: {
  orderId: string;
  origin: LatLng;
  destination: LatLng;
}) {
  const route = await computeRoute(params);
  await storeRoute(route);
  return route;
}

export async function maybeRecalculateRoute(params: {
  orderId: string;
  origin: LatLng;
  destination: LatLng;
  minAgeMs?: number;
}) {
  const now = Date.now();
  const minAgeMs = params.minAgeMs ?? 45_000;
  const last = lastRouteAt.get(params.orderId) ?? 0;
  if (now - last < minAgeMs) return null;

  const route = await recalculateRoute(params);
  lastRouteAt.set(params.orderId, now);
  return route;
}

async function storeRoute(route: RouteSnapshot) {
  const { error } = await supabase
    .from('delivery_routes')
    .upsert({
      order_id: route.orderId,
      encoded_polyline: route.encodedPolyline,
      distance_meters: route.distanceMeters,
      duration_seconds: route.durationSeconds,
      eta: route.eta,
      calculated_at: route.calculatedAt
    }, { onConflict: 'order_id' });

  if (error) throw error;
}

async function stopTracking(orderId: string, runnerId: string) {
  await supabase
    .from('runner_locations_latest')
    .update({
      status: 'stopped',
      runner_id: runnerId,
      updated_at: new Date().toISOString()
    })
    .eq('order_id', orderId);
  snapBuffers.delete(orderId);
  lastSnapAt.delete(orderId);
}

function bufferForRoadSnapping(payload: RunnerLocationPayload) {
  const existing = snapBuffers.get(payload.orderId) ?? [];
  existing.push(payload);
  snapBuffers.set(payload.orderId, existing.slice(-100));
}

async function maybeSnapRecentPoints(orderId: string, runnerId: string) {
  const buffer = snapBuffers.get(orderId) ?? [];
  const now = Date.now();
  const last = lastSnapAt.get(orderId) ?? 0;
  if (buffer.length < 4 || now - last < 20_000) return;

  const points = buffer.map((point) => ({ lat: point.lat, lng: point.lng }));
  const snapped = await snapToRoads(points);
  const lastSnapped = snapped.at(-1);
  if (!lastSnapped) return;

  await supabase.from('runner_location_history').insert({
    order_id: orderId,
    runner_id: runnerId,
    status: buffer.at(-1)?.status.toLowerCase() ?? 'accepted',
    lat: lastSnapped.lat,
    lng: lastSnapped.lng,
    heading: buffer.at(-1)?.heading ?? null,
    speed: buffer.at(-1)?.speed ?? null,
    accuracy: buffer.at(-1)?.accuracy ?? null,
    recorded_at: new Date().toISOString(),
    source: 'snapped'
  });

  await supabase
    .from('runner_locations_latest')
    .update({
      snapped_lat: lastSnapped.lat,
      snapped_lng: lastSnapped.lng,
      updated_at: new Date().toISOString()
    })
    .eq('order_id', orderId);

  snapBuffers.set(orderId, []);
  lastSnapAt.set(orderId, now);
}
