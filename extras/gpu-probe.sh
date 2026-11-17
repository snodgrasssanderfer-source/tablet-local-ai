#!/data/data/com.termux/files/usr/bin/bash
# GPU 探测：试几种让 Termux 用上 Adreno GPU 的"搭桥"方式，结果存到 ~/ai/logs/gpu-probe.txt
# 用法：curl -fsSL https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main/extras/gpu-probe.sh | bash
OUT="$HOME/ai/logs/gpu-probe.txt"; mkdir -p "$HOME/ai/logs"
exec > >(tee "$OUT") 2>&1
devs() { llama-bench --list-devices 2>/dev/null | sed -n '/Available devices/,$p'; }

echo "== 1. 系统里的 OpenCL 驱动文件"
ls -l /vendor/lib64/libOpenCL*.so /system/vendor/lib64/libOpenCL*.so 2>/dev/null || echo "（没找到）"
echo "-- 安卓公开给 App 的库里是否包含 OpenCL："
grep -i opencl /vendor/etc/public.libraries*.txt /system/etc/public.libraries*.txt 2>/dev/null || echo "（未列出）"

echo; echo "== 2. 安装检测工具"
apt-get install -y clinfo opencl-vendor-driver >/dev/null 2>&1 && echo "clinfo 已安装" || echo "clinfo 安装失败"

echo; echo "== 3. clinfo 直接检测"
clinfo -l 2>&1 | head -n 8
echo "-- 指定系统驱动目录后："
LD_LIBRARY_PATH=/vendor/lib64:$PREFIX/lib clinfo -l 2>&1 | head -n 8

echo; echo "== 4. llama.cpp 看到的设备"
echo "-- 默认："; devs
echo "-- 指定系统驱动目录（LD_LIBRARY_PATH=/vendor/lib64）："
LD_LIBRARY_PATH=/vendor/lib64:$PREFIX/lib devs

echo; echo "== 5. 开源 Adreno Vulkan 驱动（Turnip）"
apt-get install -y mesa-vulkan-icd-freedreno >/dev/null 2>&1 && echo "Turnip 已安装" || echo "Turnip 安装失败"
devs

echo; echo "探测完成，结果已保存到 ~/ai/logs/gpu-probe.txt。请把这一屏截图发出来。"
