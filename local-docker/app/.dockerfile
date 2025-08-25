# Official Alpine image with Node.js
# If you need to run application in amd64 container on arm64 machine, please add '--platform=linux/amd64' before image name.
FROM --platform=linux/amd64 node:18-alpine

LABEL maintainer="office@adminitiative.com"
LABEL description="Custom Node.js Express application with Prometheus and Grafana monitoring"

# Service user for Node.js app
RUN addgroup -g 1001 -S nodeapp && \
    adduser -S nodeapp -u 1001

# Application directory
WORKDIR /app

# Copy application
COPY package*.json ./
COPY app.js ./

# Install npm dependencies
RUN npm install && \ 
    npm ci --only=development && \
    npm cache clean --force


# Logs directory with permissions for service user
RUN mkdir -p logs && \
    chown -R nodeapp:nodeapp /app

# Change to service user from root
USER nodeapp

# Application port
EXPOSE 3000

# Healthcheck to validate if application is running
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD nodeapp healthcheck.js

# Application start
CMD ["node", "app.js"]