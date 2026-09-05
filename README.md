# 《无名档案》2D 侦探剧情游戏

> 工作目录：`Narrative2D`
> 文档版本：v2.0
> 状态：五章完整制作版；首次游玩按章节顺序解锁
> 更新日期：2026-09-05

## 游戏概念

《无名档案》是一款完全现实规则下的横版侦探剧情游戏。玩家在五起相互关联、又各自完整成立的案件中调查姓名、声音、时间、地址和自己的案件档案。共同命题是：记录可以证明一个人存在，也可能暴露、误解或再次伤害这个人。

游戏没有战斗、超能力或最后出现的全知幕后组织。核心循环是横向场景探索、询问与对证、选择证据完成推理，再决定已证真相应该公开到哪一层。

## 五章内容

1. 《不存在的住客》：用证词冲突、场景复查和三段推理重建林小满案；结局《姓名》/《档案》。
2. 《谢幕之后》：比较可播放的 A/B 磁带，拆开谢幕者、录音时刻与胸针去向；结局《清白》/《原声》。
3. 《停在四点十七分》：校准多套时间来源，证明一致记录共用错误基准；结局《校正》/《报时》。
4. 《被删去的地址》：叠合旧图、新图、完整底片与排版框，追查地址覆盖和火灾责任；结局《门牌》/《底图》。
5. 《共同的名字》：用四章原件、投递路线和知识边界证明共享委托，制作最后材料索引；结局《沉默》/《全卷》/条件式《索引》。

新玩家从第一章开始，每章达成结局后解锁下一章；后续章节要求此前各章均有通关记录。章节选择显示已达成的结局，已解锁章节可以重玩。第五章读取前四章实际结果。《索引》条件会在终幕明确显示，不使用隐藏善恶值。旧版已存在的跳章存档仍可通过“继续调查”恢复，不删除已有进度；它不会凭空补齐此前章节的通关记录。

## 当前完成情况

- Godot 4.6.2 项目、标题与章节选择、独立存档和跨章结局档案；
- 五章共 20 段正式场景，横向移动、鼠标自动靠近、交互热点与阶段目标；
- 调查笔记、线索去重、证据选择推理、错误反馈和最终陈述；
- A/B 磁带试听、时间线校准、地址图层叠合、八项材料分类四套章节机制；
- 统一写实场景图、透明人物立绘、脚底固定的呼吸/说话轻动作，以及侦探四帧行走动画；行走按实际位移调速、校正逐帧中心和脚底位置，并使用约 0.1 秒起停过渡；
- 601 条阿里云百炼 AI 合成正式对白，逐条清单、指纹元数据与运行时引用；
- 环境声、互动音效、独立语音总线，以及音量、显示、帧率与键位设置；
- 五章自动完整通关、全部调查热点可达、分支结局、存档/档案和视觉截图验证；
- 64 位 Windows 导出配置与可直接运行构建。

## 启动方法

普通试玩可直接运行：

```text
D:\IndieGame\Narrative2D\builds\windows\不存在的住客.exe
```

构建文件名保留第一章时期的兼容名称；标题画面显示完整作品暂名《无名档案》。开发时可用 Godot 打开 `project.godot`，或执行：

```powershell
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --path 'D:\IndieGame\Narrative2D'
```

## 操作

- 鼠标左键点击地面：走到该位置；点击人物或物件：自动靠近并调查；
- 鼠标右键：取消自动移动；
- `A` / `D` 或左右方向键：移动；
- `E`、空格或鼠标左键：调查、推进对白；
- `Tab`：打开或关闭调查笔记；
- `Esc`：关闭当前界面，或打开暂停与设置；
- 章节专用界面：按提示试听磁带、排列事件、叠入图层或选择材料类别。

## 验证与导出

五章自动测试：

```powershell
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'D:\IndieGame\Narrative2D' --scene res://tests/smoke_test.tscn
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'D:\IndieGame\Narrative2D' --scene res://tests/chapter_02_smoke_test.tscn
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'D:\IndieGame\Narrative2D' --scene res://tests/chapter_03_smoke_test.tscn
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'D:\IndieGame\Narrative2D' --scene res://tests/chapter_04_smoke_test.tscn
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'D:\IndieGame\Narrative2D' --scene res://tests/chapter_05_smoke_test.tscn
```

第五章语音数据检查：

```powershell
python tools/build_voice_manifest.py --chapter 5 --check
python tools/validate_voice_pack.py --chapter 5
```

Windows 导出：

```powershell
& 'D:\Godot\Godot_v4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'D:\IndieGame\Narrative2D' --export-release 'Windows Desktop'
```

## 目录结构

```text
Narrative2D/
├─ assets/                # 正式美术、环境声、音效和五章配音
├─ data/dialogue/         # 五章 JSON 对白
├─ data/voice/            # 试听与正式配音生成清单
├─ scenes/                # 地点、人物与 UI 场景
├─ scripts/               # 核心状态、调查、地点与 UI 逻辑
├─ tests/                 # 五章自动通关与视觉捕获
├─ tools/                 # 配音清单和语音包校验
├─ docs/                  # 案件设计、系列圣经、资产与试玩记录
├─ builds/windows/        # 本地导出，不纳入 Git
├─ project.godot
└─ export_presets.cfg
```

## 已知问题与下一步

- 五章流程、资源引用和结局状态已通过自动验证，但第二至第五章尚无不知情玩家实机数据；谜题提示强度、移动节奏和理解难度仍需按实际反馈调整；
- AI 配音已通过文件、格式、指纹、请求 ID 和对白引用检查，但尚未逐条完成人耳听测；个别读音、停顿、表演和场景音量可能需要重制；
- NPC 和主角站姿已有程序化呼吸、说话时的轻微身体倾斜与起伏，语音结束后收回说话动作；尚无分肢手势、转身、口型或逐句情绪表演；
- 主角仍使用四张原始步态，已改善中心抖动、固定播放速度和突然起停；本轮生成的八帧候选存在姿态/透明底问题，未纳入游戏。下一步应制作并逐帧验收真正交替双腿的 8–12 帧步态，或采用分肢骨骼动画；
- 暂无原创配乐、手柄适配和独立制作人员页；
- 画面以 1280×720 和 16:9 窗口验证，其他比例需要额外检查；
- 完整作品暂名、Logo、商店材料和正式发行许可复核尚未完成。

下一轮不再增加第六章。优先顺序是：完整五章人工通关与听测、修订具体卡点、补配乐/动画和手柄、确定正式名称与发行材料。

本轮验证与行为边界见 [`docs/PROGRESSION_PERFORMANCE.md`](docs/PROGRESSION_PERFORMANCE.md)。新增回归场景：`res://tests/progression_performance_test.tscn`；图形捕获场景：`res://tests/performance_visual_capture.tscn`。

## 文档与资产来源

- 总体结构与选择规则：[`docs/SERIES_BIBLE.md`](docs/SERIES_BIBLE.md)
- 各章设计：[`docs/CHAPTER_01.md`](docs/CHAPTER_01.md)、[`CHAPTER_02.md`](docs/CHAPTER_02.md)、[`CHAPTER_03.md`](docs/CHAPTER_03.md)、[`CHAPTER_04.md`](docs/CHAPTER_04.md)、[`CHAPTER_05.md`](docs/CHAPTER_05.md)
- 自然试玩表：[`docs/PLAYTEST_GUIDE.md`](docs/PLAYTEST_GUIDE.md)、[`docs/playtests/`](docs/playtests/)
- 生成美术与提示词：[`docs/GENERATED_ART.md`](docs/GENERATED_ART.md)
- AI 配音制作：[`docs/VOICE_PRODUCTION.md`](docs/VOICE_PRODUCTION.md)
- 外部 CC0 音效：[`docs/THIRD_PARTY_ASSETS.md`](docs/THIRD_PARTY_ASSETS.md)

项目原创剧本、代码与生成美术保存在本仓库。外部声音仅使用已登记许可的素材；AI 合成语音不冒充真人配音，正式发行前需重新核对届时适用的服务条款与商用条件。
