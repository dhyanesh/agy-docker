# AGY Docker Environment

Run [Google Antigravity CLI (`agy`)](https://github.com/) autonomously inside isolated Docker containers with `--dangerously-skip-permissions`.

---

## Features

- **Container-per-project Isolation**: Each run launches an isolated container scoped to your project's workspace directory. Filesystem write permissions are strictly confined to that project.
- **Autonomy by Default**: Pass `--dangerously-skip-permissions` automatically inside containers so agents can execute commands and edit code without constant prompts.
- **Background OAuth Token Refresh**: Seamlessly mounts authentication credentials read-write so agy can refresh Google OAuth access tokens automatically in the background without user intervention.
- **Host Binary Passthrough**: Mounts your host machine's `agy` binary (`/usr/local/bin/agy:ro`), meaning any updates to `agy` on the host (`agy update`) are immediately reflected without rebuilding container images.
- **Scalable Non-Root Storage Setup**: Includes a utility script to create a sparse loopback ext4 volume on any secondary drive (e.g. large NTFS, exFAT, or ext4 mounts), avoiding Docker `overlay2` incompatibilities and saving root disk space.

---

## Quick Start

### 1. (Optional) Relocate Docker Storage to a Secondary Drive

If your primary root partition has limited disk space or your large storage drive is formatted as NTFS/exFAT (which Docker's `overlay2` storage driver cannot directly use), use `setup-docker-storage.sh`:

```bash
# Syntax: sudo ./setup-docker-storage.sh <STORAGE_DIRECTORY> [MAX_SIZE_IN_GB]
sudo ./setup-docker-storage.sh /mnt/your-storage-drive 500
```

> **Note**: This creates a sparse virtual ext4 disk image (`docker-storage.img`). It allocates almost **0 bytes initially** and dynamically grows only as Docker images and containers are downloaded.

### 2. Installation

#### Option A: Install Debian Package (Recommended for Ubuntu/Debian)

Download the `.deb` release package from GitHub Releases or build it locally:

```bash
# Install package
sudo apt install ./agy-docker_1.0.0_all.deb
# Or via dpkg:
sudo dpkg -i agy-docker_1.0.0_all.deb

# Build the base container image
agy-docker --build
```

#### Option B: Standalone / From Source

1. Build the base development image (`agy-base:latest`):
   ```bash
   ./build.sh
   # Or:
   ./agy-docker --build
   ```

2. Symlink or copy `agy-docker` to your `$PATH` (e.g. `~/.local/bin`):
   ```bash
   ln -sf "$(pwd)/agy-docker" ~/.local/bin/agy-docker
   ```

---

## Usage

Navigate to any project directory and run `agy-docker`:

### Interactive Mode
```bash
cd ~/projects/my-app
agy-docker
```

### Single Autonomous Prompt (Print Mode)
```bash
cd ~/projects/my-app
agy-docker -p "run pytest and fix any failing unit tests"
```

### Autonomous Planning & Execution
```bash
cd ~/projects/my-app
agy-docker --mode auto -p "implement the REST endpoint for user registration"
```

### Specify a Custom Workspace
You can target a workspace without `cd`-ing into it:
```bash
AGY_WORKSPACE=/path/to/project agy-docker -p "analyze code coverage"
```

---

## Configuration & Environment Variables

| Variable | Default | Description |
|---|---|---|
| `AGY_WORKSPACE` | Current working directory | Directory mounted to `/workspace` inside the container |
| `AGY_IMAGE` | `agy-base:latest` | Docker image to run |
| `AGY_BIN` | Auto-detected from `PATH` / `~/.local/bin/agy` | Path to host's `agy` executable |
| `GEMINI_DIR` | `~/.gemini` | Host directory containing OAuth credentials, config, and history |
| `EXTRA_DOCKER_ARGS` | `""` | Additional flags passed directly to `docker run` (e.g. `-p 8080:8080` or `--network host`) |

---

## File Structure

```text
.
├── Dockerfile                  # Ubuntu 24.04 base image with development toolchain
├── build.sh                    # Helper script to build the image matching host UID/GID
├── agy-docker                  # CLI wrapper to launch autonomous containers
├── setup-docker-storage.sh     # Utility to mount sparse loopback volume on secondary drive
├── package-deb.sh              # Debian (.deb) package and tarball builder
└── README.md                   # Documentation
```
