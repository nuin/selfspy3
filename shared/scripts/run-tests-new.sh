#!/bin/bash
# Convenience wrapper for the updated test runner
cd "$(dirname "$0")/../.."
exec ./shared/scripts/run-tests.sh "$@"