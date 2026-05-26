import { config } from '../config.js';
import type { LatLng, RouteSnapshot } from '../types/tracking.js';

type ComputeRouteResult = {
  routes?: Array<{
    distanceMeters?: number;
    duration?: string;
    polyline?: { encodedPolyline?: string };
  }>;
};

export async function computeRoute(params: {
  orderId: string;
  origin: LatLng;
  destination: LatLng;
}): Promise<RouteSnapshot> {
  const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': config.GOOGLE_SERVER_API_KEY,
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
    },
    body: JSON.stringify({
      origin: { location: { latLng: params.origin } },
      destination: { location: { latLng: params.destination } },
      travelMode: 'TWO_WHEELER',
      routingPreference: 'TRAFFIC_AWARE',
      polylineQuality: 'HIGH_QUALITY',
      polylineEncoding: 'ENCODED_POLYLINE'
    })
  });

  if (!response.ok) {
    throw new Error(`Google Routes API failed: ${response.status} ${await response.text()}`);
  }

  const json = (await response.json()) as ComputeRouteResult;
  const route = json.routes?.[0];
  const encodedPolyline = route?.polyline?.encodedPolyline;
  if (!route || !encodedPolyline) {
    throw new Error('Google Routes API returned no route.');
  }

  const durationSeconds = parseGoogleDuration(route.duration ?? '0s');
  const calculatedAt = new Date();
  const eta = new Date(calculatedAt.getTime() + durationSeconds * 1000).toISOString();

  return {
    orderId: params.orderId,
    encodedPolyline,
    distanceMeters: route.distanceMeters ?? 0,
    durationSeconds,
    eta,
    calculatedAt: calculatedAt.toISOString()
  };
}

export async function snapToRoads(points: LatLng[]): Promise<LatLng[]> {
  if (points.length === 0) return [];

  const path = points
    .slice(-100)
    .map((point) => `${point.lat},${point.lng}`)
    .join('|');

  const url = new URL('https://roads.googleapis.com/v1/snapToRoads');
  url.searchParams.set('path', path);
  url.searchParams.set('interpolate', 'false');
  url.searchParams.set('key', config.GOOGLE_SERVER_API_KEY);

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Google Roads API failed: ${response.status} ${await response.text()}`);
  }

  const json = await response.json() as {
    snappedPoints?: Array<{ location: { latitude: number; longitude: number } }>;
  };

  return (json.snappedPoints ?? []).map((point) => ({
    lat: point.location.latitude,
    lng: point.location.longitude
  }));
}

export async function geocodeAddress(address: string): Promise<LatLng | null> {
  const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
  url.searchParams.set('address', address);
  url.searchParams.set('key', config.GOOGLE_SERVER_API_KEY);

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Google Geocoding API failed: ${response.status} ${await response.text()}`);
  }

  const json = await response.json() as {
    results?: Array<{ geometry: { location: LatLng } }>;
  };

  return json.results?.[0]?.geometry.location ?? null;
}

export async function placesAutocomplete(input: string, sessionToken: string) {
  const response = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': config.GOOGLE_SERVER_API_KEY,
      'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text.text'
    },
    body: JSON.stringify({
      input,
      sessionToken
    })
  });

  if (!response.ok) {
    throw new Error(`Places API failed: ${response.status} ${await response.text()}`);
  }

  return response.json();
}

function parseGoogleDuration(duration: string): number {
  const match = duration.match(/^(\d+(?:\.\d+)?)s$/);
  return match ? Math.round(Number(match[1])) : 0;
}
