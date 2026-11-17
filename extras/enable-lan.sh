#!/data/data/com.termux/files/usr/bin/bash
# 允许同一 Wi-Fi 下的电脑使用平板上的模型（例如 ComfyUI 的"提示词扩写"节点），并设置访问密钥
# 用法：curl -fsSL https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main/extras/enable-lan.sh | bash
# 关闭：sed -i '/^HOST=/d;/^API_KEY=/d' ~/ai/config.env && ai-stop && ai-start
set -euo pipefail
RAW="https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main"
CFG="$HOME/ai/config.env"
curl -fsSL "$RAW/bin/ai-start?t=$(date +%s)" -o "$PREFIX/bin/ai-start" && chmod +x "$PREFIX/bin/ai-start"
KEY=$(grep -s '^API_KEY=' "$CFG" | cut -d= -f2 | tr -d '"' || true)
[ -n "$KEY" ] || KEY=$(head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n')
sed -i '/^HOST=/d;/^API_KEY=/d' "$CFG"
printf 'HOST=0.0.0.0      # 允许局域网访问\nAPI_KEY="%s"   # 访问密钥（酒馆、Operit、电脑都要填）\n' "$KEY" >> "$CFG"
ai-stop >/dev/null 2>&1 || true
ai-start
IP=$(ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v '^127\.' | head -1)
echo
echo "==== 局域网访问已开启 ===="
echo "电脑上填的接口地址： http://${IP:-平板IP}:${PORT:-8080}/v1"
echo "访问密钥（API Key）： $KEY"
echo "注意：平板上的酒馆和 Operit 现在也要填这个密钥。"
