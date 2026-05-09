cmake_path = '/catkin_ws/src/ct-lio/cmake/packages.cmake'

with open(cmake_path, 'r') as f:
    content = f.read()

content = content.replace(
    'find_package(Ceres 2 REQUIRED PATHS /home/zhaochengwei/workspace/3rdparty/ceres_210)',
    'find_package(Ceres 2 REQUIRED)'
)
content = content.replace(
    'set(G2O_INCLUDE_DIRS ${3RDPARTY_DIR}/g2o-20201223/include)',
    'set(G2O_INCLUDE_DIRS /opt/ros/noetic/include)'
)
content = content.replace(
    'set(G2O_LIBRARY_DIRS ${3RDPARTY_DIR}/g2o-20201223/lib)',
    'set(G2O_LIBRARY_DIRS /opt/ros/noetic/lib)'
)

with open(cmake_path, 'w') as f:
    f.write(content)

print('packages.cmake patched successfully')
