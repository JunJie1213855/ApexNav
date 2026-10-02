#!/usr/bin/env bash
# 启动 4 个 VLM server（GroundingDINO / BLIP2ITM / MobileSAM / YOLOv7），后台运行
# 用法: ./scripts/launch_vlm_server.sh
# 停止: pkill -f 'vlm.detector'; pkill -f 'vlm.itm'; pkill -f 'vlm.segmentor'
set -e
cd "$(dirname "$0")/.."          # 回到 ApexNav 目录（data/ 软链、vlm 包依赖）

PY=/root/miniconda3/envs/apexnav/bin/python

# ① 清空 LD_LIBRARY_PATH：.bashrc 的 cuda-12.1 会与 torch cu124 冲突
unset LD_LIBRARY_PATH
# ② 离线读 HF 缓存（huggingface 本机不通，bert 已缓存）
export HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1

echo "[VLM] 后台启动 4 个 server（日志在 /tmp/apex_*.log）..."
nohup $PY -m vlm.detector.grounding_dino --port 12181 > /tmp/apex_gdino.log   2>&1 &
nohup $PY -m vlm.itm.blip2itm          --port 12182 > /tmp/apex_blip2.log   2>&1 &
nohup $PY -m vlm.segmentor.sam          --port 12183 > /tmp/apex_sam.log     2>&1 &
nohup $PY -m vlm.detector.yolov7        --port 12184 > /tmp/apex_yolov7.log  2>&1 &

echo "[VLM] 端口映射:"
echo "   12181 = GroundingDINO 检测"
echo "   12182 = BLIP-2 ITM"
echo "   12183 = MobileSAM 分割"
echo "   12184 = YOLOv7 检测"
echo "[VLM] 每个日志出现 'Running on http://localhost:1218x' 即就绪"
echo "[VLM] 停止: pkill -f 'vlm.detector'; pkill -f 'vlm.itm'; pkill -f 'vlm.segmentor'"
