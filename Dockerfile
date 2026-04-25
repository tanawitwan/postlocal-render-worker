# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@9

# Copy source
COPY package.json tsconfig.json src/ ./

# Install deps (from npm — packages are published)
RUN pnpm install --frozen-lockfile

# Build
RUN pnpm run build


# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS runtime

# Chrome + FFmpeg + fonts (same as Hyperframes render image)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip ffmpeg \
    libgbm1 libnss3 libatk-bridge2.0-0 libdrm2 libxcomposite1 \
    libxdamage1 libxrandr2 libcups2 libasound2 libpangocairo-1.0-0 \
    libxshmfence1 libgtk-3-0 \
    fonts-liberation fonts-noto-color-emoji fonts-noto-cjk fonts-noto-core \
    fonts-noto-extra fonts-noto-ui-core fonts-freefont-ttf fonts-dejavu-core \
    fontconfig \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && fc-cache -fv

# Puppeteer headless Chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV CONTAINER=true

RUN npx --yes @puppeteer/browsers install chrome-headless-shell@stable \
      --path /root/.cache/puppeteer

WORKDIR /app

# Copy built output + node_modules from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

# BeginFrame Chrome path (set at runtime via shell expansion)
ENV PRODUCER_HEADLESS_SHELL_PATH=$(find /root/.cache/puppeteer/chrome-headless-shell -name "chrome-headless-shell" -type f | head -1)

# Writable render output dir
RUN mkdir -p /tmp/renders
ENV PRODUCER_RENDERS_DIR=/tmp/renders

EXPOSE 9847

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:9847/health || exit 1

ENTRYPOINT ["node", "dist/index.js"]
