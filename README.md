# 平板本地 AI 懒人包

在安卓平板上离线运行 **Qwen3-30B-A3B-Instruct-2507**，接入 **SillyTavern（酒馆）**，再用 **Operit** 做本地 AI 助手（agent）。

```
平板
 ├─ Termux
 │   ├─ llama.cpp 模型服务  →  http://127.0.0.1:8080/v1（OpenAI 兼容接口）
 │   └─ SillyTavern 酒馆    →  http://127.0.0.1:8000
 └─ Operit（agent 应用）  →  连同一个模型接口
```

全部离线运行，聊天内容不出平板。

## 先选方案

| | **方案 A：只装 Operit（最省事）** | **方案 B：Termux + 酒馆 + Operit** |
|---|---|---|
| 安装 | 装一个 App、下载模型、导入 | 装 Termux，粘贴一行命令 |
| 角色扮演 | Operit 自带角色聊天、群聊、记忆 | 酒馆功能最全（角色卡、世界书、插件） |
| agent 能力 | 有 | 有（Operit 连 Termux 里的模型） |

Operit 从 v1.8.1 起内置了 llama.cpp，可以直接加载 GGUF 模型，所以**方案 A 不需要 Termux**。重度酒馆玩家选方案 B。

## 方案 A：只装 Operit

1. 下载安装 Operit：<https://github.com/AAswordman/Operit/releases>（`app-release.apk`，约 400MB）
2. 用平板浏览器下载模型（魔搭，国内速度快），选一个：
   - Q4_K_M（18.6GB，推荐先试）：<https://www.modelscope.cn/models/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF/resolve/master/Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf>
   - Q3_K_M（14.7GB，Q4 跑不动时用）：<https://www.modelscope.cn/models/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF/resolve/master/Qwen3-30B-A3B-Instruct-2507-Q3_K_M.gguf>
3. 打开 Operit 的模型配置，选 **本地模型 / llama.cpp（GGUF）**，导入刚下载的 `.gguf` 文件
4. 上下文长度先设 8192 左右；内存不够就调小，或者换 Q3

> 菜单名称以你装的 Operit 版本为准，找"模型配置 / 本地模型 / GGUF"一类的入口。
> 只想要角色聊天、想用酒馆角色卡，也可以试 [ChatterUI](https://github.com/Vali-98/ChatterUI)：同样内置 llama.cpp，支持酒馆角色卡。

---

以下是**方案 B**。

## 需要什么

- 安卓平板，64 位 ARM。按骁龙 8 Elite Gen 5 + 24GB 内存设计
- 存储空间至少 **25GB**（Q4 模型 18.6GB + 软件）
- 安装时需要联网（下载约 20GB），之后可完全离线

## 安装：三步

### 1. 安装 Termux

从 **F-Droid** 或 **GitHub** 下载，**不要用 Google Play 上的版本**（太旧，装不了软件包）：

- F-Droid：<https://f-droid.org/packages/com.termux/>
- GitHub：<https://github.com/termux/termux-app/releases>（下载 `arm64-v8a` 的 apk）

### 2. 在 Termux 里粘贴这一行，回车

```bash
curl -fsSL https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main/install.sh | bash
```

如果 GitHub 连不上，改用这一行：

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/snodgrasssanderfer-source/tablet-local-ai@main/install.sh | bash
```

安装过程中会问两个问题：
1. **是否用国内镜像**：在国内直接回车（默认使用）
2. **选哪个模型**：直接回车用 Q4_K_M；如果之后发现被系统杀掉，再重新运行安装脚本选 2 或 3

下载模型要一段时间。**中途断了没关系**，重新粘贴同一行命令，会接着下载。

### 3. 启动

```bash
ai-start
```

第一次加载模型要 1～3 分钟，加载好后浏览器会自动打开酒馆。

| 命令 | 作用 |
|---|---|
| `ai-start` | 启动模型和酒馆 |
| `ai-stop` | 全部停止，释放内存 |
| `ai-status` | 查看运行状态和内存 |
| `ai-bench` | 测速：对比纯 CPU 和 GPU 后端（OpenCL / Vulkan）哪个快 |

## 在酒馆里连接模型（只需设置一次）

1. 点击顶部的 **插头图标**（API 连接）
2. API 选 **Chat Completion**（聊天补全）
3. 来源选 **Custom (OpenAI-compatible)**（自定义 / OpenAI 兼容）
4. 地址（Custom Endpoint）填：`http://127.0.0.1:8080/v1`
5. API Key 留空；模型名填 `local-model`（或点获取模型列表直接选）
6. 点 **Connect**（连接），显示绿灯就成功了

> 酒馆可以在设置里把界面语言改成中文，选项名称会变成对应的中文。

## 接入 Operit（本地 agent）

1. 从 GitHub 下载安装：<https://github.com/AAswordman/Operit/releases>（`app-release.apk`，约 400MB）
2. 先在 Termux 里运行 `ai-start`，让模型服务开着
3. 在 Operit 的模型 / API 设置里，添加一个 **OpenAI 兼容**（自定义）的服务：
   - 接口地址：`http://127.0.0.1:8080/v1`
   - API Key：随便填，例如 `local`
   - 模型名：`local-model`
4. 保存后选它作为当前模型

> Operit 不同版本的菜单名称可能略有不同，找"模型配置 / API 设置 / 自定义服务商"一类的入口即可。

## 换成 Qwen3.5 去审查版（角色扮演推荐）

[Huihui-Qwen3.5-35B-A3B-abliterated](https://huggingface.co/mradermacher/Huihui-Qwen3.5-35B-A3B-abliterated-i1-GGUF) 的 i1-IQ3_XXS 量化（13.5GB），比 Q4 小 5GB，24GB 内存的平板能完整装下。在 Termux 里粘贴：

```bash
curl -fsSL https://raw.githubusercontent.com/snodgrasssanderfer-source/tablet-local-ai/main/extras/use-qwen35-abliterated.sh | bash
```

它会下载模型、关闭 Qwen3.5 的"思考"模式、改好配置并启动。

## 试试 GPU 加速

```bash
ai-bench
```

会自动安装 OpenCL 和 Vulkan 两个 GPU 后端，用当前模型分别测纯 CPU 和每个 GPU 后端的速度，结果保存在 `~/ai/logs/bench.txt`。如果某个 GPU 后端明显更快，编辑 `~/ai/config.env`，把 `NGL` 改成 `99`、`DEVICE` 填成那个设备名，然后 `ai-stop` 再 `ai-start`。

## 让它稳定运行

安卓很容易把后台程序杀掉，建议设置：

- **关掉 Termux 的电池优化**：系统设置 → 应用 → Termux → 电池 → 不限制 / 无限制
- `ai-start` 会自动申请唤醒锁，通知栏里 Termux 会显示 "wake lock held"
- 跑模型时平板会发热、耗电快，**最好插着电**
- 用的时候尽量把其他大型 App 关掉

## 常见问题

**模型服务启动后很快退出 / 提示内存不够**
24GB 内存跑 Q4_K_M 很紧。依次尝试：
1. 关掉其他 App 再 `ai-start`
2. 编辑配置，把上下文改小：`nano ~/ai/config.env`，把 `CTX=8192` 改成 `CTX=4096`
3. 重新运行安装脚本，选 2（IQ4_XS）或 3（Q3_K_M）。已下载的软件不会重装

**回复很慢**
这个模型每次只激活约 3B 参数，速度通常还可以。也可以在 `~/ai/config.env` 里把 `THREADS` 改成 8 试试。发热降频时会变慢。

**想看报错**
日志在 `~/ai/logs/`：`llama.log`（模型）、`sillytavern.log`（酒馆）。

**更新酒馆**
```bash
cd ~/ai/SillyTavern && git pull && npm install --omit=dev
```

**卸载**
```bash
ai-stop; rm -rf ~/ai; rm -f $PREFIX/bin/ai-start $PREFIX/bin/ai-stop $PREFIX/bin/ai-status
```

## 用到的开源项目

- [llama.cpp](https://github.com/ggml-org/llama.cpp)（MIT）
- [Qwen3-30B-A3B-Instruct-2507](https://huggingface.co/Qwen/Qwen3-30B-A3B-Instruct-2507)，GGUF 量化来自 [unsloth](https://huggingface.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF)
- [SillyTavern](https://github.com/SillyTavern/SillyTavern)（AGPL-3.0）
- [Operit](https://github.com/AAswordman/Operit)（LGPL-3.0）
- [Termux](https://github.com/termux/termux-app)

本仓库只包含安装脚本，不包含任何模型或软件本体。
