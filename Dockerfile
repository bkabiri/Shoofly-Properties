# ---- Stage 1: grab caddy binary ----
FROM caddy:2 AS caddybin

# ---- Stage 2: Rails base ----
FROM ruby:3.0.3

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev postgresql-client git nano nodejs yarn \
    libvips libvips-dev imagemagick curl ca-certificates \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Bundler
RUN gem install bundler:2.3.7

WORKDIR /usr/src/app

# Bring in the Caddy binary
COPY --from=caddybin /usr/bin/caddy /usr/bin/caddy

# Install a simple Procfile runner (forego)
#RUN curl -fsSL -o /usr/local/bin/forego \
     # https://github.com/ddollar/forego/releases/download/v0.17.2/forego-linux-amd64 \
#  && chmod +x /usr/local/bin/forego

# Copy Procfile + Caddyfile into expected paths
# (you can copy your whole app later via docker-compose bind mounts)
COPY Caddyfile.dev /etc/caddy/Caddyfile
COPY Procfile.dev  /usr/src/app/Procfile.dev

# Keep your entrypoint
ENTRYPOINT ["./entrypoint.sh"]

# Expose both Rails (3000) and Caddy (80) — we’ll publish only 80 from compose
EXPOSE 80 3000

# Default: run Procfile for local dev
CMD ["forego", "start", "-f", "Procfile.dev"]