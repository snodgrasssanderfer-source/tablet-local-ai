#!/data/data/com.termux/files/usr/bin/bash
# 平板本地 AI 懒人包：Qwen3-30B-A3B（llama.cpp）+ SillyTavern（酒馆）
# 用法（在 Termux 里）：
#   curl -fsSL https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main/install.sh | bash
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main}"
AI="$HOME/ai"
MODELS="$AI/models"
ST_DIR="$AI/SillyTavern"
MS="https://www.modelscope.cn/models/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF/resolve/master"
HFM="https://hf-mirror.com/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF/resolve/main"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[注意] %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[错误] %s\033[0m\n' "$*"; exit 1; }
ask()  { local a; read -r -p "$1" a </dev/tty || true; printf '%s' "${a:-$2}"; }

# ---- 0. 环境检查 ----
[ -n "${PREFIX:-}" ] && [[ "$PREFIX" == *com.termux* ]] || die "请在 Termux 里运行这个脚本。"
[ "$(uname -m)" = "aarch64" ] || die "只支持 64 位 ARM 设备（aarch64），当前是 $(uname -m)。"

say "平板本地 AI 懒人包开始安装"
echo "将安装：llama.cpp（模型服务）、Qwen3-30B-A3B-Instruct-2507、SillyTavern（酒馆）"

# ---- 1. 国内镜像 ----
if [ "$(ask '是否使用国内镜像加速软件源和 npm？[Y/n] ' y)" != "n" ]; then
  CN=1
  echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
else
  CN=0
fi

# ---- 2. 选择模型 ----
echo
echo "选择模型量化版本（越大越聪明，也越占内存）："
echo "  1) Q4_K_M  18.6GB  推荐先试（24GB 内存的平板比较紧，可能被系统杀掉）"
echo "  2) IQ4_XS  16.4GB  质量接近 Q4，省 2GB"
echo "  3) Q3_K_M  14.7GB  最稳，质量略降"
case "$(ask '输入 1/2/3（默认 1）：' 1)" in
  2) QUANT=IQ4_XS; SIZE=16378073504 ;;
  3) QUANT=Q3_K_M; SIZE=14711847328 ;;
  *) QUANT=Q4_K_M; SIZE=18556686752 ;;
esac
FILE="Qwen3-30B-A3B-Instruct-2507-$QUANT.gguf"

# ---- 3. 空间检查 ----
mkdir -p "$MODELS" "$AI/logs"
FREE_KB=$(df -Pk "$HOME" | awk 'NR==2{print $4}')
HAVE=0; [ -f "$MODELS/$FILE" ] && HAVE=$(stat -c %s "$MODELS/$FILE")
NEED_KB=$(( (SIZE - HAVE) / 1024 + 3 * 1024 * 1024 ))
[ "$FREE_KB" -gt "$NEED_KB" ] || die "存储空间不足：还需要约 $((NEED_KB/1024/1024))GB，当前剩余 $((FREE_KB/1024/1024))GB。"

# ---- 4. 安装软件包 ----
say "更新软件源并安装 llama.cpp、Node.js、git（几分钟）"
apt-get update -y
apt-get -y -o Dpkg::Options::=--force-confnew full-upgrade
apt-get -y -o Dpkg::Options::=--force-confnew install llama-cpp nodejs-lts git curl
command -v llama-server >/dev/null || die "llama-server 没有装上，请把上面的报错截图发出来。"

# ---- 5. 下载模型（可断点续传） ----
say "下载模型 $FILE（约 $((SIZE/1000000000))GB，时间取决于网速；中断后重新运行本脚本会接着下）"
dl() { curl -fL --retry 10 --retry-delay 5 -C - -o "$MODELS/$FILE" "$1/$FILE"; }
if [ "$HAVE" != "$SIZE" ]; then
  dl "$MS" || { warn "魔搭下载失败，改用 HF 镜像"; dl "$HFM"; } || die "模型下载失败，请检查网络后重新运行。"
fi
[ "$(stat -c %s "$MODELS/$FILE")" = "$SIZE" ] || die "模型文件大小不对，可能没下完整。重新运行本脚本即可续传。"

# ---- 6. 安装酒馆 ----
say "安装 SillyTavern（酒馆）"
if [ ! -d "$ST_DIR/.git" ]; then
  git clone --depth 1 -b release https://github.com/SillyTavern/SillyTavern "$ST_DIR" \
    || die "下载酒馆失败（GitHub 连不上时可以开加速器后重试）。"
fi
cd "$ST_DIR"
[ "$CN" = 1 ] && export npm_config_registry=https://registry.npmmirror.com
npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev

# ---- 7. 配置与启动命令 ----
say "写入配置和启动命令"
if [ ! -f "$AI/config.env" ]; then
  cat > "$AI/config.env" <<EOF
# 改完保存后运行 ai-stop 再 ai-start 生效
MODEL="$MODELS/$FILE"
CTX=8192        # 上下文长度：内存吃紧就改小（如 4096），够用可改大（如 16384）
THREADS=6       # CPU 线程数，6～8
PORT=8080       # 模型接口端口：http://127.0.0.1:8080/v1
ST_PORT=8000    # 酒馆端口：http://127.0.0.1:8000
EOF
else
  sed -i "s|^MODEL=.*|MODEL=\"$MODELS/$FILE\"|" "$AI/config.env"
fi
CDN="https://cdn.jsdelivr.net/gh/snodgrasssanderfer-source/tablet-local-ai@main"
for c in ai-start ai-stop ai-status; do
  curl -fsSL "$REPO_RAW/bin/$c" -o "$PREFIX/bin/$c" || curl -fsSL "$CDN/bin/$c" -o "$PREFIX/bin/$c" \
    || die "下载 $c 失败"
  chmod +x "$PREFIX/bin/$c"
done

say "安装完成！"
cat <<'EOF'
接下来：
  1. 输入 ai-start 启动（第一次加载模型要 1～3 分钟）
  2. 启动后浏览器会自动打开酒馆：http://127.0.0.1:8000
     在酒馆里连接模型的方法见说明文档 README
  3. 其他命令：ai-stop（停止）、ai-status（查看状态）
  4. 配置文件：~/ai/config.env
EOF
