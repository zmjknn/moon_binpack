# moon_binpack 项目申报书

## 基本信息
- **项目名称**：`moon_binpack`：工业级二维矩形装箱与纹理图集布局引擎
- **参赛者**：zmjknn
- **联系方式**：[请在此填写您的手机号/微信/邮箱]
- **GitHub 仓库链接**：https://github.com/zmjknn/moon_binpack
- **项目方向**：MoonBit 算法基础库 / 2D 图形与排版基础设施
- **是否为移植项目**：是

## 项目简介
moon_binpack 计划将经典工业级二维矩形装箱（2D Bin Packing Problem, 2D-BPP）的核心几何优化能力移植到 MoonBit 生态，为 2D 游戏引擎、UI 渲染系统、CSS Sprite 合成、字体字形图集（Glyph Atlas）烘焙、前端 Canvas 绘制以及工业排料切割提供高性能、可复用的自动空间规划与纹理图集布局引擎。项目面向需要在 MoonBit 及 WebAssembly 环境中进行图形排版、资源打包和几何优化的库作者与应用开发者，提供 Rect/Size 几何原语、MaxRects、Guillotine、Shelf 三大主流启发式装箱算法调度、自适应 2 的幂次方纹理图集分配器，以及 SVG 矢量可视化与标准 JSON 布局格式导出。

二维矩形装箱属于 NP-Hard 难题，工业界高度依赖成熟的几何启发式算法在毫秒级时间内获得超过 90% 的极高空间利用率。随着 MoonBit 在 WebAssembly、图形渲染和全栈领域的快速演进，社区亟需一个纯原生、零外部 C 依赖的二维装箱底层库。传统的跨语言方案往往需要在 JS 宿主中调用重量级 C/C++ WebAssembly 模块，面临昂贵的数据跨边界序列化成本和难以适配无宿主独立环境的问题。将该算法引擎原生移植到 MoonBit，不仅能精准补齐 MoonBit 在“几何优化与图形布局底层算法”上的战略生态缺口（经检索 mooncakes.io 与 GitHub 为 0 竞品空白），还利用 MoonBit 的强类型枚举与模式匹配消除原 C++ 的内存安全风险，带来极致的跨平台一致性与执行性能。

## 核心功能范围
- 提供基础几何模型与空间拓扑核心，支持 Rect、Size、Bin 几何原语，内置包含性判定、旋转变换、边距与内间隙（Padding/Border）控制；
- 提供 MaxRects（最大矩形法，工业界黄金标准）算法实现，支持 BestShortSideFit、BestLongSideFit、BestAreaFit、BottomLeft、ContactPoint 5 种启发式规则，内置相交自由矩形分裂与包含关系去重剪枝；
- 提供 Guillotine（断头台切分法）算法实现，支持 6 种空闲矩形选择规则与 6 种切分规则（ShorterAxis、LongerAxis、MinimizeArea 等），并内置相邻空闲矩形合并（Merge Rectangles）防碎片化算法；
- 提供 Shelf（货架分层法）算法实现，支持 NextFit、FirstFit、BestAreaFit、BestHeightFit 等策略，为等高字体图元与图标提供 O(N log N) 极速装箱；
- 提供高级 AtlasPacker 图集分配器，支持多纹理页（Multi-Bin）自动溢出分配与 2 的幂次方（Power-of-Two: 64/128/256/512/1024/2048/4096）自适应尺寸增长；
- 支持 90 度矩形旋转允许/禁止切换，以及按面积/长边降序的自动批量装箱（Batch Insertion）；
- 支持标准 JSON 布局格式导出，输出清晰的帧坐标清单与利用率指标，无缝对接 WebGL / Pixi.js / Phaser 等图形管线；
- 支持生成响应式 SVG 矢量可视化排版图，带颜色区分、尺寸标注与统计徽章，便于开发调试与直观验证；
- 提供独立开箱即用的命令行工具（CLI Demo），支持通过命令行直接体验装箱排版并输出预览文件；
- 提供完整的自动化测试套件与差分测试，严格保证无重叠（Non-overlapping）、边界包含与旋转一致性等几何不变式。

## 预期验收产物
- `zmjknn/moon_binpack` 核心库：发布至 mooncakes.io，开发者可通过 `moon add zmjknn/moon_binpack` 一键引入并在 MoonBit 原生项目中使用其完整 API；
- 独立 CLI 工具：支持通过 `moon run cmd/main` 直接编译运行，一键执行矩形装箱排版并生成实时 SVG 预览与 JSON 布局清单；
- 完备的自动化测试与几何不变式验证：包含 17 组以上的自动化单元测试与基准用例，严格保证对任意有效输入满足不重叠（∀ i ≠ j, Ri ∩ Rj = ∅）、边界包含与面积守恒；
- 自动化 CI 流水线：集成 GitHub Actions，持续验证 `moon check`、`moon test`、`moon build` 与 CLI 运行，保持全绿灯通过；
- 详尽的文档与示例：包含中英文 README、API 使用手册、算法原理说明、SVG 效果展示以及与业界标准（Jukka Jylänki 经典实现）对照的性能指标。

## 移植或参考说明
- **原项目名称**：RectangleBinPack (C++) 与 rect_packer (Rust)
- **原项目链接**：https://github.com/juj/RectangleBinPack 与 https://github.com/Pao/rect_packer
- **原项目许可证**：Public Domain / MIT
- **本项目许可证**：Apache-2.0

### 与原项目相比，本项目会做以下简化和重新设计：
- **纯函数式与代数数据类型建模**：充分利用 MoonBit 的代数数据类型（enum）与模式匹配重新定义启发式策略（MaxRectsHeuristic、GuillotineHeuristic、SplitHeuristic、ShelfHeuristic），消除原 C++ 的散落常量与宏定义；
- **现代包结构与接口统一**：废弃原 C++ 项目陈旧的 Makefile 与繁杂类层次，使用 MoonBit 标准的包结构（moon.mod / moon.pkg），提供统一高阶的 `AtlasPacker` 封装；
- **内存安全与高效数据结构**：摒弃 C++ 的裸指针操作与手动内存管理，基于 MoonBit 的原生定长/动态数组实现高效原地分裂与剪枝，既避免内存泄漏与越界漏洞，又确保在 WebAssembly 目标下的极高运行效率；
- **原生多页与 POT 扩展**：原 C++ 库仅支持固定单 Bin 装箱，本项目新增了现代图形渲染必须的“多页（Multi-Bin）自动溢出”与“2的幂次方自适应增长”算法；
- **内建可视化与格式导出生态**：原项目仅输出纯坐标数组，本项目原生实现了开箱即用的 SVG 矢量图生成与通用 JSON Manifest 导出，极大降低开发者在前端与游戏引擎中的集成成本。
