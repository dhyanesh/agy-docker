---
name: agy-docker-sandbox
description: >-
  Use this skill whenever developing, modifying, testing, or building code in a project workspace,
  or when performing tasks that may require git pushes, gcloud actions, or cloud deployment.
  Enforces sandboxed execution in agy-docker and gated host execution for credentialed actions.
---

# Sandboxed Development Workflow with agy-docker

This workflow enforces a strict security and privilege boundary:
1. **Untrusted / Autonomous Execution**: All code modifications, builds, test execution, script execution, and package installations run inside isolated Docker containers via `agy-docker`.
2. **Credentialed Actions**: Commands requiring sensitive host credentials (such as `git push`, `gh`, `gcloud`, or cloud deployments) NEVER run inside Docker. They are executed on the host only after presenting a summary and receiving explicit user approval.

---

## 1. Classification: Container vs. Host Actions

| Action Type | Where to Run | How to Run |
|---|---|---|
| Code editing & refactoring | 🐳 **Docker Container** | `agy-docker -p "..."` or `agy-docker --mode auto -p "..."` |
| Building, compiling, packaging | 🐳 **Docker Container** | `agy-docker -p "build the project"` |
| Running tests & test suites | 🐳 **Docker Container** | `agy-docker -p "run pytest / npm test"` |
| Installing packages / dependencies | 🐳 **Docker Container** | Executed inside the container workspace |
| Local git staging & commit | 🐳 **Docker Container** / 🖥️ **Host** | Local repository metadata in workspace |
| `git push` to remote repositories | 🖥️ **Host (Interactive)** | **Gated**: Present commit diff & ask user permission |
| `gh` CLI (PR creation, releases) | 🖥️ **Host (Interactive)** | **Gated**: Present PR details & ask user permission |
| `gcloud` operations & deployments | 🖥️ **Host (Interactive)** | **Gated**: Present deployment plan & ask user permission |

---

## 2. Step-by-Step Procedure

### Step 1: Delegate Task to `agy-docker`
Run the development prompt inside the isolated container for the current workspace:

```bash
agy-docker -p "<clear instructions of the task, tests to run, and acceptance criteria>"
```

For complex planning and execution across multiple files:
```bash
agy-docker --mode auto -p "<high-level goal description>"
```

### Step 2: Inspect Results on the Host
Once `agy-docker` completes:
1. Run `git status` and `git diff` on the host to inspect what changed.
2. Confirm test results and that no untrusted files were created outside the project.

### Step 3: Gated Host Execution for Credentialed Actions
If the task requires publishing or deploying:
1. **Do NOT run `git push` or `gcloud` inside Docker.**
2. Prepare the exact host command (e.g. `git push origin main` or `gcloud run deploy ...`).
3. Present a clear summary of the changes to the user.
4. **Explicitly ask the user for confirmation**:
   > *"The changes have been implemented and verified inside the Docker sandbox. Would you like me to proceed with executing `<command>` on the host?"*
5. Execute the command on the host **only after** the user confirms.
