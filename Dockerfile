# =============================================================================
# lean4web Dockerfile
# Multi-stage build for production deployment with Bubblewrap sandboxing
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Base image with system dependencies
# -----------------------------------------------------------------------------
FROM ubuntu:24.04 AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    bubblewrap \
    procps \
    unzip \
    # Required for building lean-cvc5 (Veil dependency)
    clang-15 \
    lld-15 \
    libc++-15-dev \
    libc++abi-15-dev \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/clang-15 100 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 25.x
RUN curl -fsSL https://deb.nodesource.com/setup_25.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for running elan/lean
# Install uidmap for newuidmap/newgidmap (required for bubblewrap user namespaces)
RUN apt-get update && apt-get install -y --no-install-recommends uidmap \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash lean \
    && echo "lean:100000:65536" >> /etc/subuid \
    && echo "lean:100000:65536" >> /etc/subgid

# Install elan as the lean user
USER lean
WORKDIR /home/lean

ENV ELAN_HOME="/home/lean/.elan"
ENV PATH="${ELAN_HOME}/bin:${PATH}"

RUN curl -sSf https://elan.lean-lang.org/elan-init.sh | sh -s -- -y --default-toolchain none
RUN elan toolchain install beta
RUN elan toolchain install v4.27.0

# Switch back to root for subsequent stages
USER root

# -----------------------------------------------------------------------------
# Stage 2: Build Node.js application
# -----------------------------------------------------------------------------
FROM base AS node-builder

WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Copy source files
COPY client/ ./client/
COPY server/ ./server/
COPY index.html vite.config.ts tsconfig.json ./

# Build client (TypeScript + Vite)
RUN npm run build:client

# -----------------------------------------------------------------------------
# Stage 3: Build Lean projects
# -----------------------------------------------------------------------------
FROM base AS lean-builder

# Switch to lean user for all Lean operations
USER lean
WORKDIR /home/lean

# Copy elan installation
ENV ELAN_HOME="/home/lean/.elan"
ENV PATH="${ELAN_HOME}/bin:${PATH}"

# Copy Projects directory
COPY --chown=lean:lean Projects/ /app/Projects/

# Build each project
# MathlibDemo - has Mathlib dependency, use cache
# WORKDIR /app/Projects/MathlibDemo
# RUN if [ -f lean-toolchain ]; then \
#         echo "Building MathlibDemo..." && \
#         elan toolchain install $(cat lean-toolchain) && \
#         (lake exe cache get 2>/dev/null || true) && \
#         lake build; \
#     fi

# # Stable
# WORKDIR /app/Projects/Stable
# RUN if [ -f lean-toolchain ]; then \
#         echo "Building Stable..." && \
#         elan toolchain install $(cat lean-toolchain) && \
#         lake build; \
#     fi

# Veil (if present)
WORKDIR /app/Projects/Veil
RUN if [ -f lean-toolchain ]; then \
        echo "Building Veil..." && \
        # elan toolchain install $(cat lean-toolchain) && \
        (lake exe cache get 2>/dev/null || true) && \
        lake build && \
        mkdir -p .lake/model_checker_builds; \
    fi

WORKDIR /app

# -----------------------------------------------------------------------------
# Stage 4: Production runtime
# -----------------------------------------------------------------------------
FROM base AS production

WORKDIR /app

# Copy node_modules from builder (production deps only would be ideal, but we need all for now)
COPY --from=node-builder /app/node_modules ./node_modules

# Copy built client
COPY --from=node-builder /app/client/dist ./client/dist

# Copy server files
COPY --from=node-builder /app/server ./server
COPY --from=node-builder /app/package*.json ./

# Copy built Lean projects (includes .lake with compiled artifacts)
COPY --from=lean-builder --chown=lean:lean /app/Projects ./Projects

# Copy elan and installed toolchains from lean-builder
COPY --from=lean-builder --chown=lean:lean /home/lean/.elan /home/lean/.elan

# Copy entrypoint script
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/

# Environment
ENV NODE_ENV=production
ENV PORT=8080
ENV PATH="/home/lean/.elan/bin:${PATH}"

# Switch to non-root user
USER lean

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/ || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server/index.mjs"]
