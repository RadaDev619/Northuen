export type LatLng = {
  lat: number;
  lng: number;
};

export type RunnerLocationPayload = LatLng & {
  orderId: string;
  runnerId: string;
  status: string;
  heading?: number | null;
  speed?: number | null;
  accuracy?: number | null;
  timestamp: string;
};

export type RouteSnapshot = {
  orderId: string;
  encodedPolyline: string;
  distanceMeters: number;
  durationSeconds: number;
  eta: string;
  calculatedAt: string;
};
