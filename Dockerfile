# syntax=docker/dockerfile:1

# ---- Build stage ----
# Pinned to match the Bun version used in development (bun 1.3.x).
FROM oven/bun:1.3 AS build
WORKDIR /app

# Install dependencies first to leverage Docker layer caching.
# Dev dependencies are needed here because the SvelteKit build runs Vite.
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Build the app. svelte-adapter-bun emits a self-contained ./build directory.
COPY . .
RUN bun run build

# ---- Runtime stage ----
# Slim image keeps the final container small. The build output bundles all
# server dependencies, so node_modules is not copied into the runtime image.
FROM oven/bun:1.3-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

# The bun image ships a non-root "bun" user; run as it for safety.
COPY --from=build --chown=bun:bun /app/build ./build

USER bun

# Railway injects PORT at runtime; the adapter reads PORT/HOST from env.
# 3000 is just the local default if PORT is unset.
ENV HOST=0.0.0.0
EXPOSE 3000

CMD ["bun", "./build/index.js"]
