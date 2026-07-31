# KERNEL SHADOWS: Episode 14 — Docker Basics
# Production-ready Dockerfile for Nginx web server
# Amsterdam, Netherlands (Day 27-28)
# Sophie van Dijk, Docker Architect

FROM nginx:alpine

LABEL maintainer="max@operation-shadow.net" \
      version="1.0" \
      description="Nginx web server for Operation Shadow" \
      episode="14" \
      location="Amsterdam, Netherlands"

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy configuration files
COPY configs/nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

# Create nginx user (security best practice)
RUN addgroup -S nginx && adduser -S nginx -G nginx

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Switch to non-root user (security)
USER nginx

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]


