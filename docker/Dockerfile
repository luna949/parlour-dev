FROM node:22

# Install all dependencies companions need to function
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Symlink python3 as python for convenience
RUN ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /workspace
