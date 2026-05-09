FROM ros:noetic-desktop

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 \
    libgoogle-glog-dev libgflags-dev \
    libsuitesparse-dev \
    libpcl-dev \
    libeigen3-dev \
    libopencv-dev \
    libyaml-cpp-dev \
    libboost-all-dev \
    ros-noetic-pcl-ros \
    ros-noetic-pcl-conversions \
    ros-noetic-eigen-conversions \
    ros-noetic-tf \
    ros-noetic-libg2o \
    && rm -rf /var/lib/apt/lists/*

# Build Ceres 2.1.0 from source
# (Ubuntu 20.04 apt only provides Ceres 1.14; project requires Ceres 2)
RUN cd /tmp && \
    git clone --depth 1 --branch 2.1.0 https://github.com/ceres-solver/ceres-solver.git && \
    mkdir ceres-build && cd ceres-build && \
    cmake ../ceres-solver \
        -DBUILD_TESTING=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_BENCHMARKS=OFF \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install && ldconfig && \
    rm -rf /tmp/ceres-solver /tmp/ceres-build

# Setup catkin workspace and clone livox_ros_driver
WORKDIR /catkin_ws
RUN mkdir -p src && \
    cd src && \
    git clone --depth 1 https://github.com/Livox-SDK/livox_ros_driver.git

# Copy ct-lio source
COPY . src/ct-lio/

# Patch packages.cmake (remove hardcoded developer paths)
RUN python3 src/ct-lio/docker/patch_cmake.py

# Build catkin workspace
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && \
    catkin_make -DCMAKE_BUILD_TYPE=Release -j$(nproc)"

# Persist ROS setup in shell
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc && \
    echo "source /catkin_ws/devel/setup.bash" >> /root/.bashrc

# Entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
