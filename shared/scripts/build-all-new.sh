#!/bin/bash
# Convenience wrapper for the updated build script
cd "$(dirname "$0")/../.."
exec ./shared/scripts/build-all.sh "$@"