#!/bin/bash

# Simple shell runner for the iPhone Solitaire Automator
set -e

# Navigate to the project directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR/SolitaireAutomator"

echo "🚀 Starting Native Automator..."
swift run
