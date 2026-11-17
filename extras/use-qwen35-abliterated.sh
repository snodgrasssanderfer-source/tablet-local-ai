#!/data/data/com.termux/files/usr/bin/bash
# 切换到 Qwen3.5-35B-A3B 去审查版（Huihui abliterated，i1-IQ3_XXS，13.5GB）并关闭"思考"
# 用法：curl -fsSL https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main/extras/use-qwen35-abliterated.sh | bash
set -euo pipefail
RAW="https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main"
F="Huihui-Qwen3.5-35B-A3B-abliterated.i1-IQ3_XXS.gguf"
SIZE=13533320288
URL1="https://hf-mirror.com/mradermacher/Huihui-Qwen3.5-35B-A3B-abliterated-i1-GGUF/resolve/main/$F"
URL2="https://huggingface.co/mradermacher/Huihui-Qwen3.5-35B-A3B-abliterated-i1-GGUF/resolve/main/$F"
M="$HOME/ai/models"; CFG="$HOME/ai/config.env"
[ -f "$CFG" ] || { echo "没找到 ~/ai/config.env，请先运行懒人包的安装脚本。"; exit 1; }

echo "== 更新 ai-start / ai-bench"
for c in ai-start ai-bench; do
  curl -fsSL "$RAW/bin/$c?t=$(date +%s)" -o "$PREFIX/bin/$c" && chmod +x "$PREFIX/bin/$c"
done
ai-stop >/dev/null 2>&1 || true

HAVE=0; [ -f "$M/$F" ] && HAVE=$(stat -c %s "$M/$F")
# 先找手动拷进平板"下载"文件夹的文件（电脑下载后用数据线拷贝过来的情况）
if [ "$HAVE" != "$SIZE" ]; then
  [ -d "$HOME/storage/shared" ] || termux-setup-storage 2>/dev/null || true
  sleep 2
  for d in "$HOME/storage/downloads" "$HOME/storage/shared/Download" "$HOME/storage/shared/Downloads"; do
    if [ -f "$d/$F" ] && [ "$(stat -c %s "$d/$F")" = "$SIZE" ]; then
      echo "== 在 $d 找到已拷贝的模型，移动到 ~/ai/models（几分钟）"
      mv "$d/$F" "$M/$F" && HAVE=$SIZE && break
    fi
  done
fi
if [ "$HAVE" != "$SIZE" ]; then
  FREE_KB=$(df -Pk "$HOME" | awk 'NR==2{print $4}')
  NEED_KB=$(( (SIZE - HAVE) / 1024 + 2 * 1024 * 1024 ))
  if [ "$FREE_KB" -le "$NEED_KB" ]; then
    echo "存储空间不够：还需要约 $((NEED_KB/1024/1024))GB，剩余 $((FREE_KB/1024/1024))GB。"
    echo "已有的模型："; ls -lh "$M"
    echo "可以删掉用不上的模型，例如：rm ~/ai/models/Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf"
    exit 1
  fi
  echo "== 下载 $F（13.5GB，可断点续传；中断后重新运行这条命令会接着下）"
  curl -fL --retry 10 --retry-all-errors --retry-delay 5 -C - -o "$M/$F" "$URL1" \
    || curl -fL --retry 10 --retry-all-errors --retry-delay 5 -C - -o "$M/$F" "$URL2" \
    || { echo "下载失败：这个模型在国内只能连 HuggingFace，网络不稳。"
         echo "办法：在电脑上下载好，用数据线拷到平板的「下载」(Download) 文件夹，再重新运行这条命令，会自动找到它。"
         exit 1; }
fi
[ "$(stat -c %s "$M/$F")" = "$SIZE" ] || { echo "文件大小不对，重新运行这条命令续传。"; exit 1; }

echo "== 修改配置"
sed -i "s|^MODEL=.*|MODEL=\"$M/$F\"|" "$CFG"
sed -i '/^EXTRA_ARGS=/d' "$CFG"
echo "EXTRA_ARGS=(--chat-template-kwargs '{\"enable_thinking\":false}')   # 关闭 Qwen3.5 的思考模式" >> "$CFG"
grep -q '^NGL=' "$CFG" || echo 'NGL=0          # GPU 层数：0 = 纯 CPU；用 GPU 时改成 99' >> "$CFG"
grep -q '^DEVICE=' "$CFG" || echo 'DEVICE=""      # GPU 设备名，见 ai-bench 的输出' >> "$CFG"

echo "== 启动"
ai-start
