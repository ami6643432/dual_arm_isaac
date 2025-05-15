#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# Entrypoint for Isaac Sim + ROS 2 Humble dev-container
#  • Sources ROS 2, Isaac Sim, and the local overlay (/ros2_ws)
#  • Preserves incoming signals (exec "$@")
#  • Adds GPU graphics caps automatically when DISPLAY is set
# ──────────────────────────────────────────────────────────────
set -euo pipefail

# 1. ROS 2
if [ -f "/opt/ros/humble/setup.bash" ]; then
  source /opt/ros/humble/setup.bash
fi

# 2. Isaac Sim runtime (sets USD & Omniverse vars)
if [ -f "/isaac-sim/setup.sh" ]; then
  source /isaac-sim/setup.sh
fi

# 3. Your colcon overlay (only if it exists)
if [ -f "/ros2_ws/install/setup.bash" ]; then
  source /ros2_ws/install/setup.bash
fi

# 4. Allow GUI rendering when DISPLAY is forwarded
if [[ -n "${DISPLAY:-}" ]]; then
  export NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:+${NVIDIA_DRIVER_CAPABILITIES},}graphics"
fi

# 5. Set real-time priority (matching container's --ulimit=rtprio=98)
ulimit -r 98 || true

# 6. Handover to whatever CMD/command the container was launched with
exec "$@"
