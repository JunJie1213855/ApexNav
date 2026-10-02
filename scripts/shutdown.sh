# 关闭 ros 和 TSP探索节点
pkill -f roslaunch; pkill -f rosmaster; pkill -f roscore
pkill -f exploration_node; pkill -f tsp_node


# 关闭相关服务
pkill -f "vlm.detector.grounding_dino"
pkill -f "vlm.itm.blip2itm"
pkill -f "vlm.segmentor.sam"
pkill -f "vlm.detector.yolov7"

# 关闭 tmux session
tmux kill-session -t apexnav