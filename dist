#!/bin/bash

set -e  # Exit immediately if a command fails

echo "🧹 Cleaning..."
make clean

echo "📦 Building dist_macos..."
make dist_macos

echo "📦 Building dist_dmcp..."
make dist_dmcp

echo "📦 Building dist_dmcp5..."
make dist_dmcp5

echo "📦 Building dist_dmcp5r47..."
make dist_dmcp5r47

echo "📦 Building dist_dmcpr47..."
make dist_dmcpr47

echo "✅ All builds complete."

