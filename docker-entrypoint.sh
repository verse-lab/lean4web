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

# Check cgroups v2 availability for resource fairness
echo ""
echo "Checking cgroups v2 availability..."
if [ -d /sys/fs/cgroup ] && [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    if [ -w /sys/fs/cgroup ] || [ -w /sys/fs/cgroup/user.slice ]; then
        echo "  cgroups v2: OK (resource fairness enabled)"
    else
        echo "  WARNING: cgroups v2 not writable - resource fairness disabled"
        echo "  For resource fairness, run with: --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw"
    fi
else
    echo "  WARNING: cgroups v2 not available - resource fairness disabled"
fi

# Show Lean toolchains
echo ""
echo "Available Lean toolchains:"
elan show 2>/dev/null || echo "  (elan not in PATH or no toolchains installed)"

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

# Execute the main command
exec "$@"
