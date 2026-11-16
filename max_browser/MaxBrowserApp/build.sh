#!/bin/bash
# Compile and install MaxBrowser.app — see bin/build_app.sh (shared by every window shell).
exec "$(dirname "$0")/../../bin/build_app.sh" MaxBrowser "$(dirname "$0")/main.swift"
