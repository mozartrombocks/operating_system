################################################################################
# @file Dockerfile
# @brief Container image for OS kernel development
#
# Provides a consistent build environment for kernel development across
# all platforms (Linux, macOS, Windows).
#
# Usage:
#   # Build image
#   docker build -t os-kernel .
#
#   # Run container
#   docker run -it -v $(pwd):/workspace os-kernel bash
#
#   # Build kernel inside container
#   cd /workspace
#   make build-x86_64
#
#   # Run tests
#   make test
#
# Benefits:
#   - Consistent environment across all developers
#   - No local installation required
#   - Reproducible builds
#   - Easy CI/CD integration
#
# Requirements:
#   - Docker installed (https://docs.docker.com/get-docker/)
#   - ~2GB disk space for image
################################################################################

# ============================================================================
# BASE IMAGE
# ============================================================================

FROM ubuntu:22.04

LABEL maintainer="Your Name <your@email.com>"
LABEL description="OS Kernel Development Environment"
LABEL version="1.0.0"

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /workspace

# ============================================================================
# INSTALL BUILD TOOLS
# ============================================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential build tools
    build-essential \
    gcc \
    g++ \
    make \
    \
    # Assembler and linker
    nasm \
    binutils \
    \
    # Emulator
    qemu-system-x86 \
    qemu-utils \
    \
    # Debugging
    gdb \
    gdb-doc \
    \
    # Version control
    git \
    \
    # ISO creation
    xorriso \
    \
    # Bootloader
    grub-common \
    \
    # Optional development tools
    vim \
    nano \
    curl \
    wget \
    \
    # Code formatting and analysis
    clang-format \
    clang-tools \
    \
    # Documentation generation
    doxygen \
    graphviz \
    \
    # Memory analysis
    valgrind \
    \
    # Utilities
    file \
    tree \
    htop \
    less \
    && \
    # Clean up apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# VERIFY INSTALLATIONS
# ============================================================================

# Verify critical tools are installed
RUN gcc --version && \
    nasm -version && \
    qemu-system-x86_64 --version && \
    gdb --version && \
    make --version && \
    git --version

# ============================================================================
# SETUP WORKING DIRECTORY
# ============================================================================

# Create workspace directory for user to mount
RUN mkdir -p /workspace

# Create directory for build artifacts
RUN mkdir -p /workspace/build
RUN mkdir -p /workspace/dist

# ============================================================================
# CREATE NON-ROOT USER (Optional but recommended for security)
# ============================================================================

# Create user 'developer' with sudo privileges
RUN useradd -m -s /bin/bash -G sudo developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set password (you can change or remove this)
RUN echo "developer:developer" | chpasswd

# ============================================================================
# FINAL SETUP
# ============================================================================

# Use non-root user
USER developer

# Set shell
SHELL ["/bin/bash", "-c"]

# Print welcome message
RUN echo "#!/bin/bash" > /etc/profile.d/welcome.sh && \
    echo 'echo "OS Kernel Development Environment"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "=================================="' >> /etc/profile.d/welcome.sh && \
    echo 'echo ""' >> /etc/profile.d/welcome.sh && \
    echo 'echo "Available commands:"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  make help           - Show all make targets"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  make build-x86_64   - Build kernel"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  make test           - Run tests"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  make debug          - Debug with GDB"' >> /etc/profile.d/welcome.sh && \
    echo 'echo ""' >> /etc/profile.d/welcome.sh && \
    echo 'echo "Quick start:"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  cd /workspace"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  make build-x86_64"' >> /etc/profile.d/welcome.sh && \
    echo 'echo "  make test"' >> /etc/profile.d/welcome.sh && \
    echo 'echo ""' >> /etc/profile.d/welcome.sh

# ============================================================================
# DEFAULT COMMAND
# ============================================================================

# Start interactive bash shell
CMD ["/bin/bash"]

################################################################################
# BUILD INSTRUCTIONS
################################################################################

# Build the image:
#   docker build -t os-kernel .
#
# Options:
#   docker build -t os-kernel:latest .
#   docker build -t os-kernel:v1.0 .
#   docker build --no-cache -t os-kernel .  # Force rebuild
#
# Run the image:
#   docker run -it os-kernel
#   docker run -it -v /path/to/project:/workspace os-kernel
#   docker run -it --rm os-kernel make build-x86_64
#
# Mount current directory:
#   docker run -it -v $(pwd):/workspace os-kernel
#
# Run with X11 forwarding (for GUI, if needed):
#   docker run -it -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY os-kernel
#
# Run as root (not recommended):
#   docker run -it -u root os-kernel
#
# Remove container after exit:
#   docker run -it --rm os-kernel
#
# Limit resources:
#   docker run -it -m 2g -c 1024 os-kernel  # 2GB RAM, 1 CPU
#
# Name the container:
#   docker run -it --name os-dev os-kernel
#
# Reconnect to existing container:
#   docker exec -it os-dev bash

################################################################################
# DOCKER-COMPOSE (Optional)
################################################################################

# docker-compose.yml:
#
# version: '3.8'
#
# services:
#   os-kernel:
#     build: .
#     image: os-kernel:latest
#     container_name: os-kernel-dev
#     volumes:
#       - .:/workspace
#     environment:
#       - TERM=xterm-256color
#     stdin_open: true
#     tty: true
#     command: bash
#
# Usage:
#   docker-compose up -d
#   docker-compose exec os-kernel bash
#   docker-compose down

################################################################################
# TROUBLESHOOTING
################################################################################

# Q: "Permission denied" errors inside container
# A: Run with --user option or as root (-u 0)
#
# Q: "Cannot connect to Docker daemon"
# A: Ensure Docker is installed and running
#    Try: sudo docker ps
#
# Q: "Out of disk space"
# A: Clean up images: docker system prune
#
# Q: "Build is slow"
# A: Use BuildKit: DOCKER_BUILDKIT=1 docker build .
#
# Q: "Changes not saved"
# A: Mount volumes with -v or use docker-compose.yml
#
# Q: "Cannot access host files"
# A: Mount with -v /host/path:/container/path

################################################################################
# IMAGE SIZE OPTIMIZATION
################################################################################

# Current image size: ~1.5-2GB
#
# To reduce further:
# - Use alpine:latest as base (not recommended for this project)
# - Remove optional tools (clang-tools, valgrind, etc.)
# - Use multi-stage builds
#
# For production builds, create stripped-down version:
# FROM os-kernel:latest AS builder
# RUN apt-get purge -y clang-tools valgrind graphviz
# RUN apt-get autoremove -y && apt-get clean
#
# FROM os-kernel:latest
# COPY --from=builder / /

################################################################################
# SECURITY NOTES
################################################################################

# This Dockerfile:
# ✓ Uses official Ubuntu image (security updates available)
# ✓ Installs only necessary tools
# ✓ Creates non-root user (developer)
# ✓ Cleans up apt cache
#
# Security improvements (if needed):
# - Scan image: docker scan os-kernel
# - Use specific Ubuntu version: ubuntu:22.04.1
# - Add security policy
# - Digitally sign images

################################################################################
# CONTINUOUS INTEGRATION
################################################################################

# Use in CI/CD pipelines:
#
# .github/workflows/build.yml:
#
# jobs:
#   docker-build:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v3
#       - name: Build Docker image
#         run: docker build -t os-kernel .
#       - name: Run tests in Docker
#         run: docker run --rm -v ${{ github.workspace }}:/workspace os-kernel make test
