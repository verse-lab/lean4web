#!/bin/bash
set -e

echo "=== lean4web Docker Entrypoint ==="

# Verify bubblewrap is available
echo "Checking Bubblewrap availability..."
if command -v bwrap &> /dev/null; then
    echo "  Bubblewrap version: $(bwrap --version 2>&1 || echo 'unknown')"

    # Test if bwrap can actually create namespaces
    if bwrap --ro-bind / / --proc /proc --dev /dev /bin/true 2>/dev/null; then
        echo "  Namespace creation: OK"
    else
        echo "  WARNING: Bubblewrap cannot create namespaces!"
        echo "  Container may need: --security-opt apparmor:unconfined --cap-add SYS_ADMIN"
        if [ "$ALLOW_NO_BUBBLEWRAP" != "true" ]; then
            echo "  Set ALLOW_NO_BUBBLEWRAP=true to run without sandboxing (NOT RECOMMENDED)"
            exit 1
        fi
        echo "  Continuing without sandboxing (ALLOW_NO_BUBBLEWRAP=true)"
    fi
else
    echo "  WARNING: Bubblewrap is not installed!"
    if [ "$ALLOW_NO_BUBBLEWRAP" != "true" ]; then
        echo "  Set ALLOW_NO_BUBBLEWRAP=true to run without sandboxing (NOT RECOMMENDED)"
        exit 1
    fi
    echo "  Continuing without sandboxing (ALLOW_NO_BUBBLEWRAP=true)"
fi

# Set up cgroups v2 for resource fairness (must run as root)
echo ""
echo "Setting up cgroups v2 for resource fairness..."
CGROUP_DIR="/sys/fs/cgroup/lean4web-sessions"
if [ -d /sys/fs/cgroup ] && [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    if [ "$(id -u)" = "0" ]; then
        # Running as root - set up cgroup delegation for lean user
        if mkdir -p "$CGROUP_DIR" 2>/dev/null; then
            # Enable cpu and memory controllers
            echo "+cpu +memory" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
            # Give lean user ownership so it can create sub-cgroups
            chown -R lean:lean "$CGROUP_DIR"
            echo "  cgroups v2: OK (delegated to lean user)"
        else
            echo "  WARNING: Could not create cgroup directory - resource fairness disabled"
        fi
    else
        # Not running as root - check if already writable
        if [ -w "$CGROUP_DIR" ] || [ -w /sys/fs/cgroup ]; then
            echo "  cgroups v2: OK (resource fairness enabled)"
        else
            echo "  WARNING: cgroups v2 not writable - resource fairness disabled"
            echo "  Run container as root or with cgroup delegation"
        fi
    fi
else
    echo "  WARNING: cgroups v2 not available - resource fairness disabled"
    echo "  For resource fairness, run with: --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw"
fi

# Show Lean toolchains
echo ""
echo "Available Lean toolchains:"
gosu lean elan show 2>/dev/null || elan show 2>/dev/null || echo "  (elan not in PATH or no toolchains installed)"

# Show available projects
echo ""
echo "Available projects:"
for dir in /app/Projects/*/; do
    if [ -f "$dir/lean-toolchain" ]; then
        project=$(basename "$dir")
        toolchain=$(cat "$dir/lean-toolchain")
        echo "  - $project (toolchain: $toolchain)"
    fi
done

echo ""
echo "Starting lean4web server on port ${PORT:-8080}..."
echo ""

# Drop privileges and execute the main command as lean user
if [ "$(id -u)" = "0" ]; then
    exec gosu lean "$@"
else
    exec "$@"
fi
