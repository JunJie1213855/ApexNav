#!/usr/bin/env bash
# 启动 ROS master + C++ 探索规划器（roslaunch 会自动拉起 roscore）
# 用法: ./scripts/launch_ros_explore_planner.sh
# 前台运行，Ctrl+C 停止
cd "$(dirname "$0")/.."          # 回到 ApexNav 目录

source /opt/ros/noetic/setup.bash
source devel/setup.bash

echo "[ROS] 启动 exploration.launch（exploration_node + tsp_node）..."
echo "[ROS] 出现 'TSP server is ready.' 即就绪；之后反复打印 'No odom...' 是等 habitat 喂数据的正常态"
roslaunch exploration_manager exploration.launch
