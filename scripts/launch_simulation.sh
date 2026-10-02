#!/usr/bin/env bash
# 运行 habitat 仿真评测（带 WSL2 渲染 + CUDA 库 workaround）
#
# 用法:
#   ./scripts/launch_simulation.sh                       # hm3dv1 完整评测
#   ./scripts/launch_simulation.sh --episode 0           # 只跑 episode 0
#   ./scripts/launch_simulation.sh --episode 0 --video   # 跑 episode 0 并录视频
#   ./scripts/launch_simulation.sh --video               # 完整评测 + 录视频
#   ./scripts/launch_simulation.sh --dataset mp3d --episode 0
#
# 选项:
#   -d, --dataset NAME   数据集 hm3dv1/hm3dv2/mp3d（默认 hm3dv1）
#   -e, --episode N      只跑 episode N（默认不传 = 全部 episode）
#   -v, --video          录制视频（need_video=true）
#   -h, --help           显示帮助
#   -- 之后的参数原样透传给 habitat_evaluation.py（其他 hydra 覆盖）
set -e
cd "$(dirname "$0")/.."

PY=/root/miniconda3/envs/apexnav/bin/python

# 默认值
DATASET="hm3dv1"
EPISODE=""
VIDEO=false
EXTRA=()

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dataset)          DATASET="$2"; shift 2 ;;
    -e|--episode|--epi)    EPISODE="$2"; shift 2 ;;
    -v|--video)            VIDEO=true; shift ;;
    -h|--help)
      echo "用法: $0 [选项]"
      echo "  -d, --dataset NAME   数据集 hm3dv1/hm3dv2/mp3d（默认 hm3dv1）"
      echo "  -e, --episode N      只跑 episode N（默认全部）"
      echo "  -v, --video          录制视频（need_video=true）"
      echo "  -- ...               透传其他 hydra 覆盖参数"
      exit 0 ;;
    --)                    shift; EXTRA+=("$@"); break ;;
    *)                     EXTRA+=("$1"); shift ;;
  esac
done

# 环境变量（关键 workaround，顺序不可乱）
unset LD_LIBRARY_PATH                      # ① 清 .bashrc 的 cuda-12.1（否则 torch 报错）
source /opt/ros/noetic/setup.bash          # ② 补回 ROS 库路径（rospy/tf 需要）
source devel/setup.bash
export LD_PRELOAD=/lib/x86_64-linux-gnu/libffi.so.7   # ③ WSL2 EGL 渲染 workaround
export EGL_PLATFORM=surfaceless

# 组装 hydra 参数
ARGS=(--dataset "$DATASET" habitat.simulator.habitat_sim_v0.gpu_device_id=-1)
[[ -n "$EPISODE" ]] && ARGS+=(test_epi_num="$EPISODE")
[[ "$VIDEO" == "true" ]] && ARGS+=(need_video=true)
ARGS+=("${EXTRA[@]}")

echo "[SIM] dataset=$DATASET  episode=${EPISODE:-全部}  video=$VIDEO"
echo "[SIM] 执行: habitat_evaluation.py ${ARGS[*]}"
exec $PY habitat_evaluation.py "${ARGS[@]}"
