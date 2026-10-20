# moon_binpack 项目申报书

## 基本信息
- **项目名称**：`moon_binpack`：工业级二维矩形装箱与纹理图集布局引擎
- **参赛者**：geqain
- **GitHub 仓库链接**：https://github.com/geqain/moon_binpack
- **项目方向**：MoonBit 算法基础库 / 图形与排版基础设施
- **是否为移植项目**：是
- **参考开源项目**：
  - 原项目名称：RectangleBinPack (C++ / Jukka Jylänki) 与 rect_packer (Rust)
  - 原项目链接：https://github.com/juj/RectangleBinPack 与 https://github.com/Pao/rect_packer
  - 原项目许可证：Public Domain / MIT
  - 本项目许可证：Apache-2.0

---

## 1. 项目价值与生态定位

### 具体痛点与背景
在 2D 游戏开发、Web/UI 渲染引擎、CSS Sprite 图集生成、字体字形图集（Glyph Atlas）烘焙、前端 Canvas 绘制以及工业排料切割中，**二维矩形装箱（2D Bin Packing Problem, 2D-BPP）**是高频出现的核心几何优化问题。该问题属于 NP-Hard 难题，工业界普遍依赖高效的启发式几何算法（如 MaxRects、Guillotine、Shelf）在毫秒级时间内计算出空间利用率超过 90% 的紧凑排布方案。

随着 MoonBit 语言快速进军 WebAssembly、边缘计算与全栈生态（例如社区正在构建的 Canvas、SVG、游戏引擎与 UI 框架），开发者亟需一个纯原生、零外部 C 依赖的二维装箱引擎。传统跨语言开发方案依赖在 JS 宿主中调用重量级 C/C++ WebAssembly 模块，面临昂贵的数据跨边界复制成本和难以适配无宿主独立环境的问题。

### 生态位重要性与竞品分析
经全量检索，目前 `mooncakes.io` 官方包仓库与 GitHub 开源社区中，针对 2D 矩形装箱、MaxRects、Guillotine 切分以及纹理图集打包的相关模块**完全空白（0 个现有实现）**。`moon_binpack` 将精准补齐 MoonBit 在“几何优化与图形布局底层算法”上的战略生态缺口，为未来的 MoonBit 游戏框架、富文本字形缓存与图形工具提供标准的公共基础设施。

---

## 2. 交付范围与工程边界

### 核心功能与交付内容
1. **基础几何与空间拓扑核心**：
   - 提供 `Rect`、`Size`、`Bin` 几何原语，支持交集检测、包含性判定、旋转变换与外边框间隙（Padding/Border）支持；
2. **三套工业级主流装箱算法实现**：
   - **MaxRects（最大矩形法，工业界黄金标准）**：基于重叠自由矩形集合的高效空间查找，支持 Best Short Side Fit (BSSF)、Best Long Side Fit (BLSF)、Best Area Fit (BAF)、Bottom-Left (BL) 与 Contact Point (CP) 等 5 种启发式匹配规则，内置相交分裂与重叠去重剪枝；
   - **Guillotine（断头台切分法）**：支持 Short Axis Split、Long Axis Split、Shorter Leftover Axis 等切分规则，并附带相邻空闲矩形合并（Merge Rectangles）防空间碎片化算法；
   - **Shelf（货架分层法）**：实现 Shelf Next-Fit、First-Fit、Best-Fit，专为近似高度图元（如等高字体、图标）提供 $O(N \log N)$ 极速装箱；
3. **高级图集与多页分配器（Atlas Allocator）**：
   - 支持多纹理页（Multi-Bin）自动溢出分配；
   - 支持 2 的幂次方（Power-of-Two, 256/512/1024/2048）纹理尺寸自适应增长收敛；
   - 支持 90 度旋转允许/禁止切换；
4. **可视化与工业级导出**：
   - 提供 SVG 矢量可视化排版图导出（生成带尺寸标签、利用率 Badge、美观配色的排布预览）；
   - 提供通用 JSON 格式导出，无缝适配 WebGL / Pixi / Phaser 等主流图形管线；
5. **完整工程化验证**：
   - 提供独立 CLI 工具，可通过命令行直接执行矩形装箱与预览生成；
   - 提供 100% 覆盖核心路径的单元测试、无重叠验证器与经典基准用例测试集。

### 明确不做的工程边界
- **不涉及 GPU 纹理显存交互与底层像素图光栅化**：项目专注几何拓扑、空间切分与坐标规划计算，以保持 100% 纯 MoonBit 与全平台（Native, Wasm, JS）一致性；
- **不涉及三维（3D）装箱与不规则多边形（Nesting）排料**：聚焦二维正交矩形工业标准，确保极佳的算法收敛性能与代码稳定性。

---

## 3. 预期使用场景

1. **游戏与 UI 引擎的纹理图集（Texture Atlas / Sprite Sheet）打包**：
   游戏开发者将数十到数百张尺寸各异的技能图标、角色序列帧打包进一张 $1024 \times 1024$ 的纹理贴图中，显著降低 GPU Draw Call，避免纹理出血；
2. **矢量字体渲染中的动态字形字库缓存（Dynamic Glyph Atlas Cache）**：
   排版或渲染引擎在运行时按需加载汉字与拉丁字符的点阵/SDF，动态调用装箱算法紧密放入字形纹理缓存中；
3. **前端/全栈图标生成与 CSS Sprite 合成工具链**：
   在静态站点生成器（SSG）或构建工具中，将零散 SVG/PNG 图标自动合并并输出 CSS 坐标偏移映射表和排版预览。

---

## 4. 实现路径与技术理解

### 技术路径与独到设计
1. **基于不可变数据与高效可变切分的双层设计**：
   充分发挥 MoonBit 现代类型系统特性，使用模式匹配与代数数据类型表达切分策略（Heuristics），在内存分配敏感的内层循环中采用原地矩形分裂与剪枝数组，最大化 Wasm 运行性能；
2. **严格的几何正确性与无重叠不变式**：
   每个算法均内置强断言与差分检查，保证对任意输入满足：
   - **不重叠性（Non-overlapping）**：$\forall i \neq j, \text{rect}_i \cap \text{rect}_j = \emptyset$；
   - **边界包含性（Containment）**：所有矩形均严格位于 Bin 边界内；
   - **面积守恒度量（Occupancy）**：精确计算有效填充率 $\frac{\sum \text{area}}{\text{bin\_area}}$，优化空间浪费；
3. **对原 C++ 实现的现代化重构**：
   剔除 C++ 裸指针与宏依赖，利用 MoonBit 的泛型与强类型枚举，以纯函数式接口分发算法，向用户提供 `new_packer(algorithm).pack(...)` 的统一简洁入口。
