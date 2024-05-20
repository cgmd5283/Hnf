# Use a base OS image with Docker installed
FROM ubuntu:20.04

# Set environment variables to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    wget \
    curl \
    git \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    # Install Docker CE (Community Edition)
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    # Install Docker Compose
    && curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    # Setup for Coolify
    && mkdir -p /app/coolify \
    && wget -O /app/coolify/docker-compose.yml https://coolify.io/docker-compose.yml \
    # Setup for PocketBase
    && mkdir -p /app/pocketbase \
    && echo "version: '3.8'\nservices:\n  pocketbase:\n    image: pocketbase/pocketbase:latest\n    ports:\n      - '8090:8090'\n    volumes:\n      - pocketbase-data:/pb_data\nvolumes:\n  pocketbase-data:" > /app/pocketbase/docker-compose.yml \
    # Cleanup to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Write the start script directly in the Dockerfile
RUN echo "#!/bin/bash\n\
dockerd > /dev/null 2>&1 &\n\
sleep 10\n\
cd /app/coolify && docker-compose up -d\n\
cd /app/pocketbase && docker-compose up -d\n\
tail -f /dev/null" > /start.sh \
    && chmod +x /start.sh

# Expose necessary ports
EXPOSE 3000 8090

# Healthcheck to ensure services are running
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Command to start everything
CMD ["/start.sh"]