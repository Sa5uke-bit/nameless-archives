# 《不存在的住客》候选素材库

> 调研日期：2026-08-14  
> 状态：声音候选已采用；字体、输入图标与参考美术仍仅作初筛

## 选材结论

现成资源适合解决字体、输入图标、环境底噪和少量物件音效，但不适合直接拼成正式场景。当前公开像素素材大多采用俯视、幻想或明确灵异风格，难以准确表现 1996 年中国沿海旧旅馆，也容易削弱本作“看似超自然、最终完全现实”的克制感。

正式美术建议采用统一制作的横向背景与人物，外部素材只承担不决定整体风格的通用部分。

## 优先候选

| 类别 | 候选 | 许可证 | 适合用途 | 当前判断 |
| --- | --- | --- | --- | --- |
| 中文正文字体 | [Noto Sans CJK / Noto Sans SC](https://github.com/notofonts/noto-cjk) | SIL OFL 1.1 | 对话、笔记、菜单 | 高优先级；字形完整、可随游戏分发，需要同时保存许可证 |
| 中文标题字体 | [Noto Serif CJK / Noto Serif SC](https://github.com/notofonts/noto-cjk) | SIL OFL 1.1 | 标题、章节名、证物标题 | 高优先级；与旧档案气质相符，需控制字体包体积 |
| 输入图标 | [Kenney Input Prompts](https://kenney.nl/assets/input-prompts) | CC0 1.0 | `E`、`Tab`、方向键、手柄提示 | 高优先级；提供 PNG、SVG 和多种设备图标 |
| 海边环境音 | [Sea waves on the beach](https://freesound.org/people/felix.blume/sounds/500171/) — felix.blume | CC0 1.0 | 旅馆外海浪底噪 | 已采用官方 OGG 预览，按场景调整音量并循环 |
| 雨窗环境音 | [Gentle Rain from Window](https://freesound.org/people/YostPeter/sounds/523405/) — YostPeter | CC0 1.0 | 大堂与 307 的雨声底层 | 已采用官方 OGG 预览，按场景调整音量并循环 |
| 旧门声音 | [Squeaking old door](https://freesound.org/people/Ittaisha/sounds/819384/) — Ittaisha | CC0 1.0 | 307 房门、员工通道 | 已采用官方 OGG 预览作为场景切换反馈 |
| 钥匙与锁 | [Key Turning in Lock](https://freesound.org/people/Solar01/sounds/662888/) — Solar01 | CC0 1.0 | 进入 307、锁舌反馈 | 已采用官方 OGG 预览作为开锁反馈 |
| 翻页声音 | [Paper Rustle](https://freesound.org/people/BenjaminNelan/sounds/353125/) — BenjaminNelan | CC0 1.0 | 调查笔记、登记簿、维修单 | 已采用官方 OGG 预览作为笔记反馈 |

当前采用的是 Freesound 官方 CDN 提供的 OGG 预览文件，不使用转载来源；原始素材页、作者和 CC0 许可已登记在 `THIRD_PARTY_ASSETS.md`。

## 仅作参考的美术包

| 候选 | 许可证与费用 | 可借鉴内容 | 不直接采用的原因 |
| --- | --- | --- | --- |
| [Haunted Hotel Asset Pack](https://not-jam.itch.io/haunted-hotel-asset-pack) — Not Jam | CC0；自由定价 | 两色调色思路、8×8 旅馆物件、Godot 图块组织 | 包含怪物与明确灵异语汇，分辨率过低，不符合现实悬疑定位 |
| [House Interior Asset Pack](https://styloo.itch.io/houseinteriorassetpack) — styloo | CC0；最低 2.99 美元 | 家具与室内物件拆分方式 | 需要付费且整体更偏通用住宅；试玩确认风格前不购买 |
| [Modern Houses Tileset](https://opengameart.org/content/modern-houses-tileset-topdown) — Ritpop | CC0 | 现代室内常用物件 | 俯视视角与本项目横向构图不兼容 |
| [Kenney UI Pack](https://kenney.nl/assets/ui-pack) | CC0 | 滑块、按钮状态和通用控件 | 可作为结构参考，但默认外观过于明亮、通用，正式界面应重新着色与排版 |

## 推荐接入顺序

1. 已完成：接入海浪、雨声、门锁、旧门和纸张基础声音；
2. 已完成：统一制作大堂、307、洗衣房和人物美术，而不是混用多个场景包；
3. 首轮试玩后再决定是否接入独立中文字体与输入图标；
4. 每个后续纳入的文件继续同步登记到 `THIRD_PARTY_ASSETS.md`；
5. 根据首玩反馈再做音频裁切、循环点、响度与空间感的精修。

## 尚未执行

- 未下载候选字体和输入图标；
- 未购买任何素材；
- 未采用参考美术包；
- 尚未针对真人首玩结果精修音量和循环点。
