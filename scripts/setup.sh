#!/usr/bin/env bash
# One-time setup: creates the Python venv, installs dependencies, and
# installs the launchd cleanup job. Run this after copying the project
# files to ~/Library/Application Support/MyWispr/app/.
#
# Usage: bash scripts/setup.sh
# Run from any directory — paths resolve from this script's location.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
VENV="$PROJECT_DIR/.venv"

echo "MyWispr setup"
echo "  Install root: $PROJECT_DIR"
echo ""

# --- Python check ---
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install Python 3.10 or later from python.org."
    exit 1
fi
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "Python: $PY_VERSION"

# --- Venv ---
if [ -d "$VENV" ]; then
    echo "Venv already exists at $VENV — skipping creation."
else
    echo "Creating venv ..."
    python3 -m venv "$VENV"
fi

# --- Dependencies ---
echo "Installing dependencies (this may take a minute the first time) ..."
"$VENV/bin/pip" install --upgrade "pip>=26.2.2" --quiet
"$VENV/bin/pip" install -r "$PROJECT_DIR/requirements.txt" --quiet
echo "Dependencies installed."

# --- launchd cleanup job ---
PLIST_TEMPLATE="$PROJECT_DIR/launchd/com.mywispr.cleanup.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.mywispr.cleanup.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
RUN_SH_PATH="$PROJECT_DIR/scripts/run.sh"

echo ""
echo "Installing launchd cleanup job ..."
mkdir -p "$LAUNCH_AGENTS_DIR"

# Render the template: substitute the actual run.sh path
sed "s|__RUN_SH_PATH__|$RUN_SH_PATH|g" "$PLIST_TEMPLATE" > "$PLIST_DST"

# Reload (unload ignores error if not previously loaded)
launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl load "$PLIST_DST"
echo "Launchd cleanup job installed: $PLIST_DST"
echo "  run.sh path: $RUN_SH_PATH"

echo ""
echo "Setup complete."
echo "Next: run scripts/build-app.sh to create /Applications/MyWispr.app"
