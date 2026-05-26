import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(8082),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  GOOGLE_SERVER_API_KEY: z.string().min(1),
  TRACKING_ALLOWED_ORIGINS: z.string().default('*')
});

export const config = envSchema.parse(process.env);

export const activeTrackingStatuses = new Set([
  'accepted',
  'picked_up',
  'on_the_way'
]);

export const terminalTrackingStatuses = new Set([
  'delivery_completed',
  'delivered',
  'cancelled'
]);
