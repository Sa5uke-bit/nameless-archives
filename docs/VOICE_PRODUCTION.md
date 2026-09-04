# 四章配音与录音制作记录

> 当前阶段：第一至第四章正式全量配音均已生成并接入
> 生成方式：阿里云百炼 `qwen3-tts-instruct-flash`，AI 合成语音
> 状态：共 485 条正式对白已生成、导入并通过自动检查，等待完整实机听感复核

## 1. 制作范围

用户确认保留试听阶段的全部六个声线：侦探、旁白、乔雯、顾宁、赵成和顾海川。正式包覆盖四个章节 JSON 中的旁白、人物对白和重复调查提示，共 135 条、3615 个剧本文字。

林小满在现有剧本中没有直接台词。“？？？”的两句由顾宁的 `Elias` 声线演绎，并通过 `VoiceDuct` 总线加入低通、轻微混响和音量衰减，表现声音从传声管另一端传来；这不增加第七个角色声线。“咔哒”属于音效字幕，不生成语音。

## 2. 最终角色映射

| 发声身份 | 角色声音目标 | 内置音色 | 选择理由 | 需要避免 |
| --- | --- | --- | --- | --- |
| 侦探 | 三十多岁，低中音，沉稳、清楚、有分析感 | `Moon`（月白） | 率性但不轻浮的男性底色，适合作为玩家长期听见的中心声音 | 过度耍帅、播音腔、替玩家夸张下结论 |
| 旁白 | 成熟、客观、略有纪录片质感 | `Neil`（阿闻） | 咬字稳定，便于承担场景信息与推理节点 | 新闻联播感、恐怖预告腔、抢过角色表演 |
| 乔雯 | 四十岁左右，温和知性、疲惫谨慎 | `Maia`（四月） | 温柔与知性的底色适合她的保护性动机 | 软弱、少女感、故作神秘 |
| 顾宁 | 三十多岁，低沉冷静、强控制、情绪内收 | `Elias`（墨讲师） | 严谨清楚的女性底色可承载事务感，再用指令压低情绪 | 讲课感、哭腔过多、反派感 |
| 赵成 | 五十岁左右，粗粝疲惫、防备而负罪 | `Vincent`（田叔） | 沙哑烟嗓与老维修工的身体感相符 | 武侠豪迈、纯粹凶狠、恐怖故事腔 |
| 顾海川 | 六十岁左右，缓慢、冷静、习惯支配 | `Arthur`（徐大爷） | 年长且不疾不徐，适合“不需要提高音量的权威” | 乡野说书、慈祥长者、脸谱化奸笑 |

音色名称与非实时指令模型兼容性已按阿里云百炼官方音色列表的“非实时语音合成”表核对。试听阶段原拟使用的 `Andre` 与 `Katerina` 只支持普通非实时模型、不支持 `qwen3-tts-instruct-flash`，因此分别改为 `Moon` 与 `Elias`；用户已确认最终保留上表全部声线。

## 3. 试听记录

试听清单保存在 [`data/voice/chapter_01_auditions_v1.jsonl`](../data/voice/chapter_01_auditions_v1.jsonl)，输出位于 `assets/audio/dialogue/auditions/v1/<角色英文名>/`。每个角色有日常基线、受压或对质、低声或余韵三条，共 18 条，供声线确认与后续对照。

| 发声身份 | 中性陈述 | 受压或对质 | 低声或余韵 |
| --- | --- | --- | --- |
| 侦探 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/detective/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/detective/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/detective/03_quiet.wav) |
| 旁白 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/narrator/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/narrator/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/narrator/03_quiet.wav) |
| 乔雯 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/qiao_wen/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/qiao_wen/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/qiao_wen/03_quiet.wav) |
| 顾宁 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/gu_ning/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/gu_ning/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/gu_ning/03_quiet.wav) |
| 赵成 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/zhao_cheng/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/zhao_cheng/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/zhao_cheng/03_quiet.wav) |
| 顾海川 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/gu_haichuan/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/gu_haichuan/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/gu_haichuan/03_quiet.wav) |

试听阶段共合成 535 个剧本文字，18 条音频总时长约 120.16 秒。试听文件继续保留，方便正式包出现表演偏差时回查最初方向。

## 4. 正式包与可复现流程

正式生成清单为 [`data/voice/chapter_01_full.jsonl`](../data/voice/chapter_01_full.jsonl)，输出目录为 `assets/audio/dialogue/chapter_01/`。每条记录使用稳定 ID、相对输出路径、角色基础指令和当前台词的表演指示；每个 WAV 旁的 `.meta.json` 记录文本与参数指纹、模型、请求 ID 和用量，不包含 API Key 或临时下载地址。

正式包统计：

- 135 条语音，3615 个剧本文字；
- 总时长约 807.12 秒，即 13 分 27 秒；
- WAV 数据约 38.7 MB，统一为单声道、16 位、24 kHz PCM；
- 六个系统音色，七个对白显示标签（额外标签是“？？？”）；
- 135 个唯一请求 ID；再次执行批量生成时 135 条全部命中参数指纹并跳过。

从剧情数据重建或检查清单：

```powershell
python tools/build_voice_manifest.py --chapter 1
python tools/build_voice_manifest.py --chapter 1 --check
```

使用本机环境变量中的 `DASHSCOPE_API_KEY` 生成语音：

```powershell
python C:\Users\SASUKE\.codex\skills\aliyun-bailian-speech\scripts\bailian_speech.py speak-batch `
  --input data/voice/chapter_01_full.jsonl `
  --output-dir assets/audio/dialogue/chapter_01 `
  --confirm-batch --requests-per-minute 10
```

校验语音包、剧情引用和 WAV 格式：

```powershell
python tools/validate_voice_pack.py --chapter 1
```

`build_voice_manifest.py` 同时将 `voice` 与 `voice_bus` 字段写入四个章节对白 JSON；重复执行应保持结果不变。修改剧本文本后，应先重建清单，再只重新生成指纹变化的音频。

## 5. Godot 接入规则

- HUD 切换到新对白行时加载并播放该行的 `voice`；对白推进、关闭或切换时立即停止上一条，避免声音重叠。
- 语音不控制文字自动推进。玩家仍可按原有操作阅读或跳过，跳过时当前语音同步停止。
- 普通对白使用 `Voice` 总线；传声管中的“？？？”使用其子总线 `VoiceDuct`。
- Esc 设置中“角色与旁白语音”可单独调节，并保存到 `user://settings.cfg` 的 `audio/voice`。
- 没有 `voice` 的音效字幕保持静音，不会误用上一条语音。

Godot 4.6.2 已导入全部正式 WAV；完整冒烟测试覆盖正常对白、无声字幕、传声管总线、语音音量即时生效与跨重启持久化，并已通过。

## 6. 人工复核重点

自动检查只能确认文件、格式、引用和运行时行为，不能替代完整听测。实机试玩时重点记录：

- 同一角色在不同场景中是否仍像同一个人；
- 侦探与旁白是否足够耐听，不会长期压迫玩家；
- 人名、“周岚”、林小满、“307”等词是否读音准确；
- 表演是否保持现实主义和克制，没有广播、网文或恐怖片腔调；
- 停顿是否破坏推理节奏，台词结束是否过早或拖沓；
- 语音、雨声、海浪和互动音效之间是否平衡；
- 传声管两句是否怪异但仍可被理解为现实声学现象。

发现问题时记录“角色、台词开头、问题、希望的方向”，优先只调整一条或一个变量，不重新生成无关文件。

## 7. 第二章《谢幕之后》

第二章正式清单为 [`data/voice/chapter_02_full.jsonl`](../data/voice/chapter_02_full.jsonl)，输出位于 `assets/audio/dialogue/chapter_02/`。共 96 条、2760 个剧本文字，总时长约 613.68 秒（10 分 14 秒），WAV 数据约 29.46 MB；全部为单声道、16 位、24 kHz PCM，96 个请求 ID 与参数指纹均唯一且有效。

第二章沿用侦探 `Moon` 与旁白 `Neil`，新增角色映射如下：

| 发声身份 | 内置音色 | 表演方向 |
| --- | --- | --- |
| 方芸 | `Serena` | 温和但有清楚边界，长期疲惫而谨慎，不塑造成软弱受害者 |
| 杨佩 | `Vivian` | 受过舞台训练，清楚、有控制力，情绪藏在准确咬字之后 |
| 徐峥 | `Ethan` | 年轻音响师，略轻、直接、有一点紧张，避免喜剧化 |
| 梁绍康 | `Eldric Sage` | 年长剧场经理，体面、平稳、善于回避，避免脸谱化反派腔 |

试听清单为 [`data/voice/chapter_02_auditions_v1.jsonl`](../data/voice/chapter_02_auditions_v1.jsonl)，四人各有中性、受压与低声三条，共 12 条、约 72.96 秒，输出位于 `assets/audio/dialogue/auditions/chapter_02_v1/`。正式生成与检查命令：

```powershell
python tools/build_voice_manifest.py --chapter 2
python tools/build_voice_manifest.py --chapter 2 --check
python C:\Users\SASUKE\.codex\skills\aliyun-bailian-speech\scripts\bailian_speech.py speak-batch `
  --input data/voice/chapter_02_full.jsonl `
  --output-dir assets/audio/dialogue/chapter_02 `
  --confirm-batch --requests-per-minute 10
python tools/validate_voice_pack.py --chapter 2
```

### 可播放磁带谜题

磁带中的程书瑜台词“别找我”与场务台词“雨声器还没试”分别由 `Maia`、`Ethan` 合成，源清单为 [`data/voice/chapter_02_tape_source.jsonl`](../data/voice/chapter_02_tape_source.jsonl)。`tools/build_tape_puzzle_audio.py` 读取两条源录音，程序生成轻咳、两次金属铃、掌声、纸张声、底噪和模拟雨声，再输出：

- `assets/audio/tape/chapter_02/tape_a_farewell.wav`：掌声环境中的整理副本；
- `assets/audio/tape/chapter_02/tape_b_rehearsal.wav`：带有纸张声、场务提示与雨声器的连续排练带。

两段均为 18 秒、单声道、16 位、24 kHz PCM。核心 7.4 秒片段只生成一次，再分别混入 A/B 两种上下文，因此“台词—轻咳—双铃”的复制关系在声音本身成立，不依赖界面文字宣告。所有合成源和混音输出都有旁置元数据；程序声音为项目原创生成资产，无外部声音素材许可依赖。重建命令：

```powershell
python tools/build_tape_puzzle_audio.py
```

## 8. 第三章《停在四点十七分》

第三章正式清单为 [`data/voice/chapter_03_full.jsonl`](../data/voice/chapter_03_full.jsonl)，输出位于 `assets/audio/dialogue/chapter_03/`。共 126 条、3602 个剧本文字，总时长约 810.88 秒（13 分 31 秒），WAV 数据约 38.93 MB；全部为单声道、16 位、24 kHz PCM，126 个请求 ID 与参数指纹均唯一且有效。

侦探继续使用 `Moon`，旁白继续使用 `Neil`。四名新角色没有创建付费自定义音色，而是复用前两章已验证兼容 `qwen3-tts-instruct-flash` 的系统声线，再以角色级指令区分表演：

| 发声身份 | 内置音色 | 表演方向 |
| --- | --- | --- |
| 陈默 | `Vincent` | 粗粝疲惫但不凶狠，被长期误解后的谨慎，避免苦情与武侠腔 |
| 罗遥 | `Serena` | 温和清楚、观察力强，压住内疚但保持边界 |
| 邓守义 | `Arthur` | 年长厚实、日常口语，承认错误时沉重但不煽情 |
| 黄维国 | `Eldric Sage` | 平稳的行政控制感，防御而不咆哮，不做脸谱化反派 |

试听清单为 [`data/voice/chapter_03_auditions_v1.jsonl`](../data/voice/chapter_03_auditions_v1.jsonl)，四人各有中性、受压与低声三条，共 12 条，输出位于 `assets/audio/dialogue/auditions/chapter_03_v1/`。本轮选角复用已经通过前两章兼容性检查的音色；正式包完成了文件、侧录、指纹、请求 ID、采样率、声道、位深、时长和对白引用的自动校验。当前环境不能替代人耳判断具体读音与表演，因此仍把完整听测列为待办，不宣称已经完成听感验收。

重建与验证：

```powershell
python tools/build_voice_manifest.py --chapter 3
python tools/build_voice_manifest.py --chapter 3 --check
python C:\Users\SASUKE\.codex\skills\aliyun-bailian-speech\scripts\bailian_speech.py speak-batch `
  --input data/voice/chapter_03_full.jsonl `
  --output-dir assets/audio/dialogue/chapter_03 `
  --confirm-batch --requests-per-minute 10
python tools/validate_voice_pack.py --chapter 3
```

批量生成期间发生过两次网络超时。工具没有自动重试不确定请求；续跑依赖已经写入的参数指纹侧录跳过完成项，最终 126 条全部通过唯一请求 ID 校验，没有盲目覆盖整个语音包。

## 9. 第四章《被删去的地址》

第四章正式清单为 [`data/voice/chapter_04_full.jsonl`](../data/voice/chapter_04_full.jsonl)，输出位于 `assets/audio/dialogue/chapter_04/`。共 128 条、3548 个剧本文字，总时长约 805.92 秒（13 分 26 秒），WAV 数据约 38.69 MB；全部为单声道、16 位、24 kHz PCM，128 个请求 ID 与参数指纹均唯一有效。

| 发声身份 | 内置音色 | 表演方向 |
| --- | --- | --- |
| 蒋禾 | `Vivian` | 年轻但不稚嫩，压住脆弱，陈述事实时坚定，避免受害者哭腔 |
| 温岑 | `Vincent` | 风霜、略粗、偏慢，内疚而不说书 |
| 孙桂琴 | `Maia` | 中低音、严肃、有保护欲，不训话、不煽情 |
| 冯启昌 | `Arthur` | 程序化控制感，防御而不咆哮，不脸谱化 |

试听清单为 [`data/voice/chapter_04_auditions_v1.jsonl`](../data/voice/chapter_04_auditions_v1.jsonl)，四人各三条，输出位于 `assets/audio/dialogue/auditions/chapter_04_v1/`。正式批次发生两次网络超时，续跑只补齐未完成项，并依据侧录指纹跳过已有文件；没有整体覆盖。自动检查已覆盖清单、对白引用、WAV 解码、声道、位深、采样率、文件长度、内容指纹和唯一请求 ID。当前仍未完成逐条人耳听测。

```powershell
python tools/build_voice_manifest.py --chapter 4 --check
python tools/validate_voice_pack.py --chapter 4
```

## 10. 来源与使用说明

- 服务：阿里云百炼大模型服务平台；
- 模型：`qwen3-tts-instruct-flash`；
- 音色：百炼内置系统音色；
- 内容：本项目原创剧本台词；
- 资产性质：AI 合成语音，不是人类演员录音，也不模仿具体真人；
- API Key 仅从本机环境变量读取，不进入仓库；
- 正式发行前需再次核对届时适用的百炼服务条款、模型使用政策与商用条件。

官方参考：[Qwen TTS API](https://help.aliyun.com/zh/model-studio/qwen-tts-api/)、[Qwen-TTS 音色列表](https://help.aliyun.com/zh/model-studio/qwen-tts-voice-list)。
