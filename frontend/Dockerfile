# ── Universal SQL Transpiler — Frontend ─────────────────────────────────────
# Multi-stage build:
#   1. node:20-alpine  — runs `npm run build` to produce the Vite dist/
#   2. nginx:alpine    — serves the dist/ and proxies /api to the backend
#
# Official Node image docs:  https://hub.docker.com/_/node
# Official nginx image docs: https://hub.docker.com/_/nginx

# ── Stage 1: build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
RUN npm run build

# ── Stage 2: serve ──────────────────────────────────────────────────────────
FROM nginx:alpine

# Replace default nginx config with our proxy config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy Vite build output
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
