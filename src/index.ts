/**
 * @postlocal/render-worker
 *
 * Railway Node service: wraps @hyperframes/producer server.
 * Listens on PORT (Railway injects RAILWAY_PUBLIC_PORT).
 *
 * Routes (from producer server):
 *   POST /render          — blocking render → JSON response with outputPath + fileSize
 *   POST /render/stream   — SSE streaming render with live progress
 *   GET  /health         — health check
 *   GET  /outputs/:token — download rendered file
 *
 * Env vars:
 *   PORT                              — default: 9847
 *   RAILWAY_PUBLIC_PORT               — Railway injects this
 *   PRODUCER_RENDERS_DIR              — output dir for rendered videos (default: /tmp/renders)
 *   PRODUCER_MAX_CONCURRENT_RENDERS   — max concurrent renders (default: 1, cap at 2)
 *   LOG_LEVEL                         — debug | info | warn | error (default: info)
 */

import { createProducerApp } from "@hyperframes/producer/server";
import { createConsoleLogger } from "@hyperframes/producer";
import { existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const PORT = Number(process.env.PORT ?? process.env.RAILWAY_PUBLIC_PORT ?? 9847);
const RENDERS_DIR = process.env.PRODUCER_RENDERS_DIR ?? "/tmp/renders";
const MAX_CONCURRENT = Math.min(
  Number(process.env.PRODUCER_MAX_CONCURRENT_RENDERS ?? 1),
  2 // hard cap: memory constraints on Railway
);
const LOG_LEVEL = (process.env.LOG_LEVEL ?? "info") as "debug" | "info" | "warn" | "error";

// Ensure renders directory exists (required for output files)
if (!existsSync(RENDERS_DIR)) {
  mkdirSync(RENDERS_DIR, { recursive: true });
}

const logger = createConsoleLogger({ level: LOG_LEVEL, prefix: "[render-worker]" });

logger.info("Starting @postlocal/render-worker", {
  port: PORT,
  rendersDir: RENDERS_DIR,
  maxConcurrent: MAX_CONCURRENT,
});

const app = createProducerApp({
  logger,
  rendersDir: RENDERS_DIR,
  maxConcurrentRenders: MAX_CONCURRENT,
  outputUrlPrefix: "/outputs",
  artifactTtlMs: 60 * 60 * 1000, // 1 hour — Railway should pull the file before this
});

app.listen({ port: PORT, fetch: app.fetch });
logger.info(`Listening on port ${PORT}`);
