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

# Ubuntu 24.04 includes a default 'ubuntu' user with UID/GID 1000.
# If a user with HOST_UID already exists, remove it first so devuser can claim it.
RUN if getent passwd "${HOST_UID}" >/dev/null 2>&1; then \
        existing_user=$(getent passwd "${HOST_UID}" | cut -d: -f1); \
        userdel -f "${existing_user}" 2>/dev/null || true; \
    fi && \
    if ! getent group "${HOST_GID}" >/dev/null 2>&1; then \
        groupadd -g "${HOST_GID}" devuser; \
    fi && \
    group_name=$(getent group "${HOST_GID}" | cut -d: -f1) && \
    useradd -u "${HOST_UID}" -g "${group_name}" -m -s /bin/bash devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
    chmod 0440 /etc/sudoers.d/devuser

# Set working directory and default user
WORKDIR /workspace
USER devuser
ENV HOME=/home/devuser
ENV USER=devuser
ENV PATH="/usr/local/bin:${PATH}"

CMD ["/bin/bash"]
