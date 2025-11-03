# PRODUCTION DOCKERFILE
FROM node:20-alpine3.18 as builder

ENV NODE_ENV=build

USER node
WORKDIR /home/node

USER root
RUN apk add --no-cache openssl1.1-compat curl

USER node
COPY package*.json ./
RUN npm ci

COPY --chown=node:node . .
RUN npx prisma generate \
    && npm run build \
    && npm prune --omit=dev

# ---

FROM node:20-alpine3.18

ENV NODE_ENV=production

USER root
RUN apk add --no-cache openssl1.1-compat curl

USER node
WORKDIR /home/node

COPY --from=builder --chown=node:node /home/node/package*.json ./
COPY --from=builder --chown=node:node /home/node/node_modules/ ./node_modules/
COPY --from=builder --chown=node:node /home/node/dist/ ./dist/
COPY --from=builder --chown=node:node /home/node/prisma/ ./prisma/

COPY --chown=node:node healthcheck.sh ./
USER root
RUN chmod +x /home/node/healthcheck.sh
USER node

EXPOSE 3000

CMD ["node", "dist/server.js"]
