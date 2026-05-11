# CT-LIO Docker 设计文档

## 目标

为 CT-LIO（Continuous-Time LiDAR-Inertial Odometry）提供可复现的 Docker 环境，支持在容器内编译项目、运行 rosbag 示例，并通过 X11 + NVIDIA GPU 在主机显示 RViz 可视化界面。

## 环境

- 基础镜像：`ros:noetic-desktop`（Ubuntu 20.04 + ROS Noetic + RViz 预装）
- 主机：Linux + NVIDIA GPU + nvidia-container-toolkit
- 容器内播放 rosbag，X11 转发到主机显示 RViz

## 依赖处理

| 依赖 | 来源 | 备注 |
|------|------|------|
| RViz | 基础镜像内置 | ros:noetic-desktop 已包含 |
| PCL, Eigen, OpenCV | apt | Ubuntu 20.04 系统包 |
| Glog, Gflags | apt | `libgoogle-glog-dev libgflags-dev` |
| CSparse, Cholmod | apt | `libsuitesparse-dev` |
| yaml-cpp | apt | `libyaml-cpp-dev` |
| G2O | apt | `ros-noetic-libg2o`，安装至 `/opt/ros/noetic/` |
| Ceres 2 | 源码编译 | apt 仅有 1.14，需编译 2.1.0 |
| livox_ros_driver | 源码编译 | catkin 包，与 ct-lio 同一 workspace |
| Sophus, tessil | 项目内 thirdparty/ | 已随源码携带 |

## packages.cmake 修改

原始文件含两处硬编码开发者路径，在 Docker 构建时通过 Python 脚本 patch（避免 sed 处理 cmake `${}` 变量的 shell 展开问题）：

1. Ceres 路径：
   ```cmake
   # 原
   find_package(Ceres 2 REQUIRED PATHS /home/zhaochengwei/workspace/3rdparty/ceres_210)
   # 改
   find_package(Ceres 2 REQUIRED)
   ```

2. G2O 路径（库名与 ros-noetic-libg2o 完全匹配）：
   ```cmake
   # 原
   set(G2O_INCLUDE_DIRS ${3RDPARTY_DIR}/g2o-20201223/include)
   set(G2O_LIBRARY_DIRS ${3RDPARTY_DIR}/g2o-20201223/lib)
   # 改
   set(G2O_INCLUDE_DIRS /opt/ros/noetic/include)
   set(G2O_LIBRARY_DIRS /opt/ros/noetic/lib)
   ```

## 文件结构

```
ct-lio/
├── Dockerfile
├── docker-compose.yml
└── docker/
    └── entrypoint.sh
```

## Dockerfile 构建流程

1. 基础：`FROM ros:noetic-desktop`
2. 安装系统 apt 依赖（PCL、Eigen、OpenCV、Glog、SuiteSparse、yaml-cpp、G2O、ROS 相关包）
3. 从源码编译 Ceres 2.1.0（`-DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DBUILD_BENCHMARKS=OFF`）
4. 创建 `/catkin_ws/src`，克隆 livox_ros_driver
5. `COPY . src/ct-lio/` 复制项目
6. Python 脚本 patch packages.cmake（字符串替换，避免 shell 变量展开问题）
7. `catkin_make -DCMAKE_BUILD_TYPE=Release`

## docker-compose.yml 关键配置

```yaml
runtime: nvidia
environment:
  - DISPLAY=${DISPLAY}
  - NVIDIA_VISIBLE_DEVICES=all
  - NVIDIA_DRIVER_CAPABILITIES=all
volumes:
  - /tmp/.X11-unix:/tmp/.X11-unix
  - ./bags:/bags:ro
```

## 运行示例

```bash
# 主机开放 X11 权限
xhost +local:docker

# 启动容器
docker compose run --rm ct-lio bash

# 容器内（RViz 窗口将出现在主机屏幕）
roscore &
roslaunch ct_lio run_eskf.launch &
rosbag play /bags/xxx.bag
```

## 约束

- 不修改原始源码，仅在 Docker 构建时 patch cmake 文件
- bag 文件通过 volume 挂载，不打包进镜像
- RViz 通过 X11 转发 + NVIDIA GPU 硬件加速渲染
