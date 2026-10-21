FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install common development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    jq \
    ripgrep \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    sudo \
    procps \
    psmisc \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Arguments for matching host user ID and group ID
ARG HOST_UID=1000
ARG HOST_GID=1000

# Create devuser with host UID/GID and grant passwordless sudo within the container
RUN if getent group ${HOST_GID} ; then \
        group_name=$(getent group ${HOST_GID} | cut -d: -f1); \
    else \
        group_name=devuser; \
        groupadd -g ${HOST_GID} ${group_name}; \
    fi && \
    useradd -u ${HOST_UID} -g ${group_name} -m -s /bin/bash devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
    chmod 0440 /etc/sudoers.d/devuser

# Set working directory and default user
WORKDIR /workspace
USER devuser
ENV HOME=/home/devuser
ENV USER=devuser
ENV PATH="/usr/local/bin:${PATH}"

CMD ["/bin/bash"]
