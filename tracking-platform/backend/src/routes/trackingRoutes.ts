import { Router } from 'express';
import { z } from 'zod';
import {
  getTrackingSnapshot,
  ingestRunnerLocation,
  maybeRecalculateRoute,
  recalculateRoute
} from '../services/trackingService.js';
import { geocodeAddress, placesAutocomplete } from '../services/googleMaps.js';

export const trackingRoutes = Router();

const locationSchema = z.object({
  orderId: z.string().uuid(),
  runnerId: z.string().uuid(),
  status: z.string().min(1),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  heading: z.number().min(0).max(360).nullable().optional(),
  speed: z.number().nullable().optional(),
  accuracy: z.number().nullable().optional(),
  timestamp: z.string().datetime()
});

const routeSchema = z.object({
  orderId: z.string().uuid(),
  origin: z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  }),
  destination: z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  }),
  force: z.boolean().optional()
});

trackingRoutes.post('/locations', async (req, res, next) => {
  try {
    const payload = locationSchema.parse(req.body);
    const result = await ingestRunnerLocation(payload);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

trackingRoutes.get('/orders/:orderId', async (req, res, next) => {
  try {
    const snapshot = await getTrackingSnapshot(req.params.orderId);
    res.json(snapshot);
  } catch (error) {
    next(error);
  }
});

trackingRoutes.post('/routes', async (req, res, next) => {
  try {
    const payload = routeSchema.parse(req.body);
    const route = payload.force
      ? await recalculateRoute(payload)
      : await maybeRecalculateRoute(payload);
    res.json({ route });
  } catch (error) {
    next(error);
  }
});

trackingRoutes.get('/places/autocomplete', async (req, res, next) => {
  try {
    const input = z.string().min(2).parse(req.query.input);
    const sessionToken = z.string().min(1).parse(req.query.sessionToken);
    res.json(await placesAutocomplete(input, sessionToken));
  } catch (error) {
    next(error);
  }
});

trackingRoutes.get('/geocode', async (req, res, next) => {
  try {
    const address = z.string().min(3).parse(req.query.address);
    res.json({ location: await geocodeAddress(address) });
  } catch (error) {
    next(error);
  }
});
