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
    clang-12 \
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
    libtool

# Clone the TON source code into /ton
WORKDIR /
RUN git clone --recurse-submodules https://github.com/mhbdev/ton-blockchain.git ton

# Create a build directory
WORKDIR /build
# Tell cmake to use ccache (compiler cache)
ENV CC clang-12
ENV CXX clang++-12
# Compile the tools
RUN --mount=type=cache,target=~/.ccache \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
          -DCMAKE_C_COMPILER_LAUNCHER=ccache \
          ../ton && \
    cmake --build . -j$(nproc) --target rldp-http-proxy generate-random-id

# =================================================
# ===== Stage 2: Create the Clean Base Image ======
# =================================================
FROM ubuntu:20.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata

# Install ONLY the RUNTIME dependencies needed for the compiled TON tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    libssl1.1 \
    libatomic1 \
    zlib1g \
    libmicrohttpd12 \
    liblz4-1 \
    libsodium23 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binaries from the builder stage into the final image
COPY --from=ton-builder /build/rldp-http-proxy/rldp-http-proxy /usr/local/bin/
COPY --from=ton-builder /build/utils/generate-random-id /usr/local/bin/
