#!/bin/bash
# Local build and test script for OrcaSlicer snap
# Usage: ./local-build.sh [--clean] [--test] [--install]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CLEAN=false
TEST=false
INSTALL=false

for arg in "$@"; do
    case $arg in
        --clean)
            CLEAN=true
            shift
            ;;
        --test)
            TEST=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--clean] [--test] [--install]"
            exit 1
            ;;
    esac
done

echo "=== OrcaSlicer Snap Local Build ==="

# Check for snapcraft
if ! command -v snapcraft &> /dev/null; then
    echo "Installing snapcraft..."
    sudo snap install snapcraft --classic
fi

# Clean previous build
if [ "$CLEAN" = true ]; then
    echo "Cleaning previous build..."
    snapcraft clean
    rm -rf parts/ prime/ stage/ *.snap
fi

# Build snap
echo "Building snap..."
snapcraft pack --verbose

# Find the built snap
SNAP_FILE=$(ls -1 orcaslicer_*.snap 2>/dev/null | head -1)

if [ -z "$SNAP_FILE" ]; then
    echo "Error: No snap file found after build"
    exit 1
fi

echo "Built: $SNAP_FILE"

# Test snap
if [ "$TEST" = true ]; then
    echo "Testing snap..."

    # Lint the snap
    echo "Running snap lint..."
    snapcraft lint "$SNAP_FILE" || true

    # Check snap structure
    echo "Checking snap structure..."
    unsquashfs -l "$SNAP_FILE" | grep -E "(orca-slicer|OrcaSlicer)" | head -20
fi

# Install snap
if [ "$INSTALL" = true ]; then
    echo "Installing snap..."
    sudo snap remove orcaslicer --purge 2>/dev/null || true
    sudo snap install --dangerous "$SNAP_FILE"

    echo "Testing installation..."
    timeout 5 orcaslicer --help || echo "(Timeout or display error - expected in headless environment)"

    echo "Snap interfaces:"
    snap connections orcaslicer
fi

echo ""
echo "=== Build Complete ==="
echo "Snap file: $SNAP_FILE"
echo ""
echo "To install manually:"
echo "  sudo snap install --dangerous $SNAP_FILE"
echo ""
echo "To publish to store:"
echo "  snapcraft upload $SNAP_FILE"
