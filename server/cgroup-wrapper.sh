#!/bin/bash
# Wrapper that sets up cgroups v2 for fair resource sharing and process cleanup
# This script creates a cgroup for each user session, ensuring:
# 1. Fair CPU sharing between all concurrent sessions
# 2. All child processes are killed when the session ends

CGROUP_BASE="/sys/fs/cgroup"
CGROUP_NAME="lean4web-$$"

# Try to find a writable cgroup location
if [ -w "$CGROUP_BASE/user.slice" ]; then
    CGROUP_PATH="$CGROUP_BASE/user.slice/lean4web-sessions/$CGROUP_NAME"
elif [ -w "$CGROUP_BASE" ]; then
    CGROUP_PATH="$CGROUP_BASE/lean4web-sessions/$CGROUP_NAME"
else
    # Cgroups not available, fall back to just running bubblewrap
    exec ./bubblewrap.sh "$@"
fi

# Create parent directory if needed
mkdir -p "$(dirname "$CGROUP_PATH")" 2>/dev/null || true

# Enable controllers on parent (needed for cgroups v2)
echo "+cpu +memory" > "$(dirname "$CGROUP_PATH")/cgroup.subtree_control" 2>/dev/null || true

# Create our cgroup
mkdir -p "$CGROUP_PATH" 2>/dev/null || exec ./bubblewrap.sh "$@"

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
