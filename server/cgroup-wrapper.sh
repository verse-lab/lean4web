#!/bin/bash
# Wrapper that sets up cgroups v2 for fair resource sharing and process cleanup
# This script creates a cgroup for each user session, ensuring:
# 1. Fair CPU sharing between all concurrent sessions
# 2. All child processes are killed when the session ends

CGROUP_PARENT="/sys/fs/cgroup/lean4web-sessions"
CGROUP_NAME="session-$$"
CGROUP_PATH="$CGROUP_PARENT/$CGROUP_NAME"

# Check if the parent cgroup exists and is writable (set up by entrypoint)
if [ ! -w "$CGROUP_PARENT" ]; then
    # Cgroups not available, fall back to just running bubblewrap
    exec ./bubblewrap.sh "$@"
fi

# Enable controllers on parent (needed for cgroups v2)
echo "+cpu +memory" > "$CGROUP_PARENT/cgroup.subtree_control" 2>/dev/null || true

# Create our session cgroup
mkdir "$CGROUP_PATH" 2>/dev/null || exec ./bubblewrap.sh "$@"

# Set fair CPU sharing (weight 100 = equal share with all other sessions)
# All sessions with weight 100 get equal CPU time under contention
echo "100" > "$CGROUP_PATH/cpu.weight" 2>/dev/null || true

# Move current process into cgroup
echo $$ > "$CGROUP_PATH/cgroup.procs" 2>/dev/null || true

# Cleanup function - kills all processes in cgroup
cleanup() {
    if [ -d "$CGROUP_PATH" ]; then
        # cgroup.kill is a cgroups v2 feature that kills all processes in the cgroup
        echo 1 > "$CGROUP_PATH/cgroup.kill" 2>/dev/null || true
        sleep 0.1
        rmdir "$CGROUP_PATH" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Run bubblewrap (exec replaces this shell, but cleanup runs on exit)
exec ./bubblewrap.sh "$@"
