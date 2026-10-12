#!/bin/bash
# Test script for Intel Iris Xe video playback

echo "=== Intel Iris Xe Video Test ==="
echo "Testing mpv with optimized Intel settings..."

# Test with one of your videos
cd /home/user/Videos/entertainment/movies

# Get the first video file
VIDEO_FILE=$(ls -1 *.mkv 2>/dev/null | head -1)

if [[ -n "$VIDEO_FILE" ]]; then
    echo "Playing: $VIDEO_FILE"
    echo "Press 'f' to toggle fullscreen and check for color consistency"
    echo "Press 'q' to quit"
    mpv "$VIDEO_FILE" --msg-level=all=info
else
    echo "No video files found in current directory"
fi