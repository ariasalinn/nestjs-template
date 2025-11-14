# PRODUCTION DOCKERFILE - Backend NestJS
# Multi-stage build for optimal image size and security

FROM node:20-alpine as builder

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

ENV NODE_ENV=build

USER node

WORKDIR /home/node

# Copy dependency files
COPY --chown=node:node package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY --chown=node:node . .

# Generate Prisma Client and build application
RUN npx prisma generate \
    && npm run build \
    && npm prune --omit=dev

# ---
# Production stage - Minimal runtime image
FROM node:20-alpine

# Install runtime dependencies for Prisma
RUN apk add --no-cache \
    openssl \
    libssl3 \
    libcrypto3 \
    curl

ENV NODE_ENV=production

USER node

WORKDIR /home/node

# Copy only necessary files from builder
COPY --from=builder --chown=node:node /home/node/package*.json ./
COPY --from=builder --chown=node:node /home/node/node_modules/ ./node_modules/
COPY --from=builder --chown=node:node /home/node/dist/ ./dist/
COPY --from=builder --chown=node:node /home/node/prisma/ ./prisma/

# Expose application port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/api/v1/health || exit 1

# Start application
CMD ["node", "dist/server.js"]
