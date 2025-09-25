# =================================================================
# ===== Stage 1: Build TON Tools from Source ======================
# =================================================================
FROM ubuntu:22.04 AS ton-builder

# Set non-interactive frontend for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install all build dependencies in a single, cacheable layer
RUN apt-get update && apt-get install -y \
    tzdata \
    build-essential \
    cmake \
    clang-14 \
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
    autotools-dev \
    autoconf \
    automake \
    libtool \
    ninja-build \
    python3 \
    python3-pip \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set clang as the default compiler
ENV CC=clang-14
ENV CXX=clang++-14

# Clone the TON source code
WORKDIR /
RUN git clone --recurse-submodules https://github.com/ton-blockchain/ton.git ton

# Create a build directory
WORKDIR /build

# Configure with proper flags for memory efficiency and better error reporting
RUN cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
          -DCMAKE_C_COMPILER_LAUNCHER=ccache \
          -DCMAKE_CXX_COMPILER=clang++-14 \
          -DCMAKE_C_COMPILER=clang-14 \
          -DCMAKE_CXX_FLAGS="-stdlib=libstdc++" \
          -DCMAKE_VERBOSE_MAKEFILE=ON \
          ../ton

# Build with reduced parallelism to avoid memory issues and better error visibility
RUN --mount=type=cache,target=/root/.ccache \
    cmake --build . -j2 --target rldp-http-proxy generate-random-id tonlib-cli --verbose

# =================================================
# ===== Stage 2: Create the Clean Runtime Image ===
# =================================================
FROM ubuntu:22.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Update certificates first, then install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    libssl3 \
    libatomic1 \
    zlib1g \
    libmicrohttpd12 \
    liblz4-1 \
    libsodium23 \
    libstdc++6 \
    libreadline8 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binaries from the builder stage
COPY --from=ton-builder /build/rldp-http-proxy/rldp-http-proxy /usr/local/bin/
COPY --from=ton-builder /build/rldp-http-proxy/rldp-http-proxy /usr/local/bin/proxy
COPY --from=ton-builder /build/utils/generate-random-id /usr/local/bin/
COPY --from=ton-builder /build/tonlib/tonlib-cli /usr/local/bin/

# Ensure binaries are executable
RUN chmod +x /usr/local/bin/rldp-http-proxy \
             /usr/local/bin/generate-random-id \
             /usr/local/bin/tonlib-cli

# Verify the binaries are working
RUN /usr/local/bin/generate-random-id --help || echo "generate-random-id built successfully" && \
    /usr/local/bin/tonlib-cli --help || echo "tonlib-cli built successfully" && \
    /usr/local/bin/rldp-http-proxy --help || echo "rldp-http-proxy built successfully"

# Download global config with proper certificate handling
RUN wget -O /etc/global.config.json https://ton-blockchain.github.io/global.config.json || \
    wget -O /etc/global.config.json https://ton.org/global-config.json

# Create a working directory
WORKDIR /app

# Default command
CMD ["bash"]
