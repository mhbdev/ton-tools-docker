# TON Tools Docker Image
This repository provides the necessary files to build a minimal, clean Docker image containing essential command-line tools for The Open Network (TON).

The image is built using a multi-stage Dockerfile to ensure the final image is lightweight, containing only the compiled binaries and their necessary runtime dependencies. The image is automatically built and published to Docker Hub.

# What's Inside?
This image is based on ubuntu:20.04 and includes the following compiled tools from the official [ton-blockchain/ton](https://github.com/ton-blockchain/ton.git) repository:

`rldp-http-proxy` and
`generate-random-id`

# Usage
Pull from Docker Hub
The easiest way to use the image is to pull it directly from Docker Hub:

`docker pull mhbdev/ton-tools:latest`

Run a Command
You can run any tool included in the image using docker run. The --rm flag is recommended to automatically clean up the container after the command exits.

Example: Generate a random ID

`docker run --rm mhbdev/ton-tools:latest generate-random-id`

Building the Image Locally
If you want to build the image yourself, you can clone this repository and use the provided Docker Compose file.

# Prerequisites
- Docker
- Docker Compose (usually included with Docker Desktop)

# Build Command
The docker-compose.yml file is configured to build and tag the image correctly.

# From the root of the project directory
`docker-compose -f docker-compose.yml build`

This command will execute the build process defined in Dockerfile and create a local image tagged as `mhbdev/ton-tools:latest.`

# About the Dockerfile
The Dockerfile uses a multi-stage build to keep the final image as small as possible.

* Stage 1 (ton-builder): This stage sets up a complete build environment. It installs cmake, clang, git, and all other dependencies required to compile the TON tools from the source code.

* Stage 2 (Final Image): This stage starts from a fresh ubuntu:20.04 base. It installs only the essential runtime libraries needed by the TON tools. The compiled binaries from the ton-builder stage are then copied into the final image. This approach avoids including the build tools and source code in the final, distributable image, making it smaller and more secure.
