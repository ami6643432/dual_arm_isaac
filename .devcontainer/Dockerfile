# syntax=docker/dockerfile:1.5
###############################################################################
# Isaac Sim + ROS 2 Humble development image
###############################################################################
ARG ISAAC_TAG=4.0.0                  # or 4.0.0-headless for CI
FROM nvcr.io/nvidia/isaac-sim:${ISAAC_TAG}

ENV DEBIAN_FRONTEND=noninteractive
ARG USERNAME=developer
ARG UID=1000
ARG GID=1000
ARG ROS_DISTRO=humble

# ---------------------------------------------------------------------------#
# 1) ROS 2 + core robotics stacks                                            #
# ---------------------------------------------------------------------------#
RUN apt-get update && apt-get install -y curl gnupg lsb-release sudo git python3-pip \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
       > /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y \
       ros-${ROS_DISTRO}-desktop-full \
       ros-${ROS_DISTRO}-ros2-control \
       ros-${ROS_DISTRO}-ros2-controllers \
       ros-${ROS_DISTRO}-moveit* \
       ros-${ROS_DISTRO}-xacro ros-dev-tools \
    && rosdep init && rosdep update \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------#
# 2) Non-root user with the right groups                                     #
# ---------------------------------------------------------------------------#
RUN if getent group ${GID} > /dev/null; then \
        groupmod -n ${USERNAME} $(getent group ${GID} | cut -d: -f1); \
    else \
        groupadd -g ${GID} ${USERNAME}; \
    fi \
    && if getent passwd ${UID} > /dev/null; then \
        usermod -l ${USERNAME} -g ${GID} -d /home/${USERNAME} -m $(getent passwd ${UID} | cut -d: -f1); \
    else \
        useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}; \
    fi \
    && usermod -aG sudo,dialout,video,render ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ---------------------------------------------------------------------------#
# 3) Workspace & dependencies from lists                                     #
# ---------------------------------------------------------------------------#
ENV ROS_WS=/ros2_ws
RUN sudo mkdir -p ${ROS_WS}/src && sudo chown -R ${USERNAME}:${USERNAME} ${ROS_WS}
RUN mkdir -p /tmp/devcontainer-files
COPY --chown=${USERNAME}:${USERNAME} rosPkgs.list dep.repos /tmp/devcontainer-files/

# Create default pipPkgs.list first
RUN echo "# Python packages would go here" > /tmp/devcontainer-files/pipPkgs.list

# Then try to overwrite with actual file if it exists (will silently fail if not present)
COPY --chown=${USERNAME}:${USERNAME} ../pipPkgs.list /tmp/devcontainer-files/

# Create default depPkgs.list first (for additional Debian packages)
RUN echo "# Additional Debian packages would go here" > /tmp/devcontainer-files/depPkgs.list
# Then try to overwrite with actual file if it exists
COPY --chown=${USERNAME}:${USERNAME} ../depPkgs.list /tmp/devcontainer-files/

# Install pip packages only if pipPkgs.list has non-commented lines
RUN if grep -v '^#' /tmp/devcontainer-files/pipPkgs.list | grep -q .; then \
        python3 -m pip install --upgrade pip && \
        pip install -r /tmp/devcontainer-files/pipPkgs.list; \
    fi

# Install ROS Debian packages
RUN sudo apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && grep -vE '^\s*(#|$)' /tmp/devcontainer-files/rosPkgs.list | xargs --no-run-if-empty sudo apt-get install -y \
    && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# Install additional Debian packages from depPkgs.list if it exists and has content
RUN if [ -f /tmp/devcontainer-files/depPkgs.list ] && grep -vE '^\s*(#|$)' /tmp/devcontainer-files/depPkgs.list | grep -q .; then \
        echo "Installing additional Debian packages from /tmp/devcontainer-files/depPkgs.list" && \
        sudo apt-get update && \
        export DEBIAN_FRONTEND=noninteractive && \
        grep -vE '^\s*(#|$)' /tmp/devcontainer-files/depPkgs.list | xargs --no-run-if-empty sudo apt-get install -y && \
        sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*; \
    else \
        echo "No additional Debian packages to install from depPkgs.list or file not found/empty."; \
    fi

# ---------------------------------------------------------------------------#
# 4) Entry point that sources everything                                     #
# ---------------------------------------------------------------------------#
COPY ../dep.repos /ros2_ws/dep.repos
COPY --chown=${USERNAME}:${USERNAME} ../entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]