# ─── Build stage ─────────────────────────────────────────────────────────────
# buildpack-deps:bookworm-curl already provides curl, git, and common build
# tools, so we only need to install the CMake / C++ toolchain on top of it.
FROM buildpack-deps:bookworm-curl AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        cmake \
        make \
        g++ \
        pkg-config \
        libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app

RUN cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build

# ─── Runtime stage ───────────────────────────────────────────────────────────
# Use a minimal Debian image; only the libcurl4 shared library is needed at
# runtime (the build stage links against it dynamically).
FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/build/aooserver /usr/bin/aooserver
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Create directories for optional volume mounts (logs and blocklist config).
# These are the fixed in-container paths used by the entrypoint script.
RUN mkdir -p /logs /config \
    && chmod 755 /logs /config \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# AOO server listens on this port for both UDP and TCP (default: 10998).
# Override at runtime with: aooserver -p <port>
EXPOSE 10998/udp
EXPOSE 10998/tcp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
