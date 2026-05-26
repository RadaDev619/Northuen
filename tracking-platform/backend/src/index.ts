import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { ZodError } from 'zod';
import { config } from './config.js';
import { trackingRoutes } from './routes/trackingRoutes.js';

const app = express();

app.use(helmet());
app.use(cors({
  origin: config.TRACKING_ALLOWED_ORIGINS === '*'
    ? '*'
    : config.TRACKING_ALLOWED_ORIGINS.split(',')
}));
app.use(express.json({ limit: '256kb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api/tracking', trackingRoutes);

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  if (error instanceof ZodError) {
    res.status(400).json({ message: 'Validation failed', errors: error.flatten() });
    return;
  }

  const message = error instanceof Error ? error.message : 'Unexpected server error';
  res.status(500).json({ message });
});

app.listen(config.PORT, () => {
  console.log(`Tracking backend listening on ${config.PORT}`);
});
