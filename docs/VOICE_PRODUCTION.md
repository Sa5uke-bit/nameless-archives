# 第一章配音制作记录

> 当前阶段：六名发声角色第一轮试听（v1）
> 生成方式：阿里云百炼 `qwen3-tts-instruct-flash`，AI 合成语音
> 状态：18 条试听已生成并通过自动检查，等待人工试听确认；未开始生成全部台词

## 1. 制作边界

第一轮只为六个主要发声身份各制作三条试听：中性陈述、受压或对质、低声或含混。试听确认前不创建专属设计音色，也不生成全量对白，避免在角色方向尚未确定时重复消耗额度和返工。

当前六个发声身份是侦探、旁白、乔雯、顾宁、赵成和顾海川。林小满在现有剧本中没有直接台词；标记为“？？？”的两句用于传声管悬疑效果，确认主要人物声音后再决定由哪一音色处理；“咔哒”属于音效而非对白。

## 2. 第一轮选角

| 发声身份 | 角色声音目标 | v1 内置音色 | 选择理由 | 需要避免 |
| --- | --- | --- | --- | --- |
| 侦探 | 三十多岁，低中音，沉稳、清楚、有分析感 | `Moon`（月白） | 率性但不轻浮的男性底色，适合作为玩家长期听见的中心声音 | 过度耍帅、播音腔、替玩家夸张下结论 |
| 旁白 | 成熟、客观、略有纪录片质感 | `Neil`（阿闻） | 咬字稳定，便于承担场景信息与推理节点 | 新闻联播感、恐怖预告腔、抢过角色表演 |
| 乔雯 | 四十岁左右，温和知性、疲惫谨慎 | `Maia`（四月） | 温柔与知性的底色适合她的保护性动机 | 软弱、少女感、故作神秘 |
| 顾宁 | 三十多岁，低沉冷静、强控制、情绪内收 | `Elias`（墨讲师） | 严谨清楚的女性底色可承载事务感，再用指令压低情绪 | 讲课感、哭腔过多、反派感 |
| 赵成 | 五十岁左右，粗粝疲惫、防备而负罪 | `Vincent`（田叔） | 沙哑烟嗓与老维修工的身体感相符 | 武侠豪迈、纯粹凶狠、恐怖故事腔 |
| 顾海川 | 六十岁左右，缓慢、冷静、习惯支配 | `Arthur`（徐大爷） | 年长且不疾不徐，适合“不需要提高音量的权威” | 乡野说书、慈祥长者、脸谱化奸笑 |

音色名称与非实时指令模型兼容性已按阿里云百炼官方音色列表的“非实时语音合成”表核对。第一轮原拟使用的 `Andre` 与 `Katerina` 只支持普通非实时模型、不支持 `qwen3-tts-instruct-flash`，已分别换为 `Moon` 与 `Elias`。这里记录的是试听候选，不代表最终锁定；若内置音色无法满足角色区分度，再考虑设计专属音色。

## 3. 试听内容

试听清单保存在 [`data/voice/chapter_01_auditions_v1.jsonl`](../data/voice/chapter_01_auditions_v1.jsonl)。所有文本逐字取自当前章节 JSON，没有为配音另行改写。每条记录包含稳定 ID、角色、原文、模型、内置音色、表演指示与相对输出路径。

输出目录：`assets/audio/dialogue/auditions/v1/<角色英文名>/`

每个角色按相同顺序试听：

1. `01_neutral.wav`：日常基线；
2. `02_pressure.wav`：对质、承认或高压场面；
3. `03_quiet.wav`：低声、迟疑或余韵场面。

| 发声身份 | 中性陈述 | 受压或对质 | 低声或余韵 |
| --- | --- | --- | --- |
| 侦探 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/detective/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/detective/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/detective/03_quiet.wav) |
| 旁白 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/narrator/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/narrator/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/narrator/03_quiet.wav) |
| 乔雯 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/qiao_wen/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/qiao_wen/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/qiao_wen/03_quiet.wav) |
| 顾宁 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/gu_ning/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/gu_ning/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/gu_ning/03_quiet.wav) |
| 赵成 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/zhao_cheng/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/zhao_cheng/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/zhao_cheng/03_quiet.wav) |
| 顾海川 | [01_neutral.wav](../assets/audio/dialogue/auditions/v1/gu_haichuan/01_neutral.wav) | [02_pressure.wav](../assets/audio/dialogue/auditions/v1/gu_haichuan/02_pressure.wav) | [03_quiet.wav](../assets/audio/dialogue/auditions/v1/gu_haichuan/03_quiet.wav) |

每个 WAV 旁边的 `.meta.json` 由生成脚本写入，记录文本与参数指纹、模型、请求 ID 和用量，不包含 API Key 或临时下载地址。

本轮共合成 535 个剧本文字，18 条音频总时长约 120.16 秒，单条时长约 2.96～11.84 秒。重复执行生成清单时 18 条全部命中指纹并跳过；Godot 4.6.2 已成功导入全部 WAV，完整冒烟测试通过。

## 4. 确认标准

试听时优先判断角色是否成立，而不是某一句是否“好听”：

- 同一角色三种情绪下是否仍像同一个人；
- 六名角色在不看名字时是否容易区分；
- 侦探与旁白是否足够耐听，不会长期压迫玩家；
- 乔雯与顾宁是否年龄、气质和情绪重心不同；
- 赵成与顾海川是否能听出“负罪”与“控制”两种不同力量；
- 人名、“周岚”、林小满、307 等词的读音是否准确；
- 表演是否保持现实主义和克制，没有广播、网文或恐怖片腔调。

确认时可以按“保留 / 换音色 / 调表演 / 重做某一条”记录。优先只调整一个变量，以便判断变化来源。

## 5. 全量配音门槛

只有六名发声身份均确认后，才开始全量生成：

1. 固化角色与音色映射；
2. 确认“？？？”两句的实际声源与处理方式；
3. 从四个章节 JSON 提取全部 133 条可发声文本，排除音效行；
4. 为每条台词生成稳定 ID 和输出路径，并先执行批量干跑；
5. 分角色生成，逐批抽听开场、情绪和低声台词；
6. 在 Godot 中接入对白播放、语音音量与跳过/推进规则。

全量生成前还需决定旁白是否全部配音，以及侦探的重复调查提示是否配音；这会影响最终条数，但不会影响本轮角色试听。

## 6. 来源与使用说明

- 服务：阿里云百炼大模型服务平台；
- 模型：`qwen3-tts-instruct-flash`；
- 音色：百炼内置系统音色；
- 内容：本项目原创剧本台词；
- 资产性质：AI 合成语音，不是人类演员录音，也不模仿具体真人；
- API Key 仅从本机环境变量读取，不进入仓库；
- 正式发行前需再次核对届时适用的百炼服务条款、模型使用政策与商用条件。

官方参考：[Qwen TTS API](https://help.aliyun.com/zh/model-studio/qwen-tts-api/)、[Qwen-TTS 音色列表](https://help.aliyun.com/zh/model-studio/qwen-tts-voice-list)。
