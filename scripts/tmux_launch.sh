#!/usr/bin/env bash
# 用 tmux 组织 ApexNav 多服务运行：一个 session，每个服务一个 window
#
# 用法: ./scripts/tmux_launch.sh      （创建 session 并自动 attach）
# 之后: tmux attach -t apexnav        （重新 attach）
# 停止: tmux kill-session -t apexnav
#
# window 布局:
#   0 planner : ROS master + C++ 探索规划器（roslaunch 自动起 roscore）
#   1 gdino   : GroundingDINO (12181)
#   2 blip2   : BLIP-2 ITM    (12182)
#   3 sam     : MobileSAM      (12183)
#   4 yolov7  : YOLOv7         (12184)
#   5 sim     : 仿真测试（就绪提示，手动跑 launch_simulation.sh）
set -e
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
SESSION="apexnav"
PY=/root/miniconda3/envs/apexnav/bin/python

# 环境变量片段
ROS_SETUP="source /opt/ros/noetic/setup.bash && source devel/setup.bash"
VLM_ENV="unset LD_LIBRARY_PATH && export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1"
SIM_ENV="unset LD_LIBRARY_PATH && source /opt/ros/noetic/setup.bash && source devel/setup.bash && export LD_PRELOAD=/lib/x86_64-linux-gnu/libffi.so.7 && export EGL_PLATFORM=surfaceless"

# 若同名 session 已存在则重建
tmux kill-session -t "$SESSION" 2>/dev/null || true

# window 0: ROS + C++ 探索规划器
tmux new-session -d -s "$SESSION" -n planner
tmux send-keys -t "$SESSION:planner" "cd $ROOT && $ROS_SETUP && roslaunch exploration_manager exploration.launch" Enter

# window 1~4: 四个 VLM server
tmux new-window -t "$SESSION" -n gdino
tmux send-keys -t "$SESSION:gdino" "cd $ROOT && $VLM_ENV && $PY -m vlm.detector.grounding_dino --port 12181" Enter

tmux new-window -t "$SESSION" -n blip2
tmux send-keys -t "$SESSION:blip2" "cd $ROOT && $VLM_ENV && $PY -m vlm.itm.blip2itm --port 12182" Enter

tmux new-window -t "$SESSION" -n sam
tmux send-keys -t "$SESSION:sam" "cd $ROOT && $VLM_ENV && $PY -m vlm.segmentor.sam --port 12183" Enter

tmux new-window -t "$SESSION" -n yolov7
tmux send-keys -t "$SESSION:yolov7" "cd $ROOT && $VLM_ENV && $PY -m vlm.detector.yolov7 --port 12184" Enter

# window 5: 仿真测试（就绪提示，待 VLM server 起来后手动跑）
tmux new-window -t "$SESSION" -n sim
tmux send-keys -t "$SESSION:sim" "cd $ROOT && $SIM_ENV \
                                 && echo '=== 就绪，等上面 VLM server 都起来后运行: ===' \
                                 && echo '  ./scripts/launch_simulation.sh --episode 0' && \
                                 echo '  ./scripts/launch_simulation.sh --episode 0 --video'" \
                                 Enter

# 切到 planner window 并 attach
tmux select-window -t "$SESSION:planner"
tmux attach -t "$SESSION"
