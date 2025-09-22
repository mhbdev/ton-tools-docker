# syntax=docker/dockerfile:1.4

# =================================================================
# ===== Stage 1: Build TON Tools from Source ======================
# =================================================================
FROM ubuntu:20.04 AS ton-builder

# Set non-interactive frontend for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install all build dependencies in a single, cacheable layer
RUN apt-get update && apt-get install -y \
    tzdata \
    build-essential \
    cmake \
    clang \
    openssl \
    libssl-dev \
    zlib1g-dev \
    gperf \
    git \
    libreadline-dev \
    ccache \
    libmicrohttpd-dev \
    pkg-config \
    liblz4-dev \
    libsodium-dev \
    libsecp256k1-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone the OFFICIAL TON source code
WORKDIR /
RUN git clone --recurse-submodules https://github.com/mhbdev/ton-blockchain.git ton

# Create a build directory
WORKDIR /build

# Set compiler environment variables as per official docs
ENV CC=clang
ENV CXX=clang++

# Compile the tools with ccache optimization
RUN --mount=type=cache,target=/root/.ccache \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
          -DCMAKE_C_COMPILER_LAUNCHER=ccache \
          ../ton && \
    cmake --build . -j$(nproc) --target rldp-http-proxy generate-random-id tonlib-cli

# =================================================
# ===== Stage 2: Create the Clean Runtime Image ===
# =================================================
FROM ubuntu:20.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install ONLY the RUNTIME dependencies needed for the compiled TON tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    libssl1.1 \
    libatomic1 \
    zlib1g \
    libmicrohttpd12 \
    liblz4-1 \
    libsodium23 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binaries from the builder stage
COPY --from=ton-builder /build/rldp-http-proxy/rldp-http-proxy /usr/local/bin/
COPY --from=ton-builder /build/utils/generate-random-id /usr/local/bin/
COPY --from=ton-builder /build/tonlib/tonlib-cli /usr/local/bin/

# Ensure binaries are executable
RUN chmod +x /usr/local/bin/rldp-http-proxy \
             /usr/local/bin/generate-random-id \
             /usr/local/bin/tonlib-cli

# Download global config (optional - can be mounted at runtime)
RUN wget -O /etc/global.config.json https://ton-blockchain.github.io/global.config.json

# Create a working directory
WORKDIR /app

# Default command
CMD ["bash"]
