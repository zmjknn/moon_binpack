# moon_binpack 项目申报书

## 1. 项目名称
`moon_binpack`：基于 MoonBit 原生实现的工业级二维矩形装箱与纹理图集布局引擎

## 2. 项目简介
`moon_binpack` 是一个纯原生、零外部依赖的二维正交矩形装箱（2D Bin Packing Problem, 2D-BPP）与纹理图集布局引擎。项目针对 2D 游戏渲染、前端富文本排版、字体字形缓存（Glyph Atlas）以及 CSS Sprite 生成等场景，提供高密度空间规划与图集生成能力。二维装箱是经典的几何 NP-Hard 难题，本项目通过系统性移植并重构工业界成熟的启发式算法（MaxRects、Guillotine、Shelf），在毫秒级时间内实现空间利用率超 90% 的紧凑排布。

## 3. 项目方向与通用性说明
- **项目方向**：MoonBit 算法基础库 / 2D 图形与排版基础设施。
- **通用性说明**：经 mooncakes.io 全量检索，MoonBit 生态在二维空间切分、矩形装箱与纹理烘焙领域完全空白（0 个现有库）。本项目作为底层纯几何拓扑与坐标规划算法库，不绑定特定渲染后端或操作系统，可无缝运行于 WebAssembly、Native 及 JavaScript 目标，为 MoonBit 生态内的 Canvas、SVG、WebGPU 游戏框架和 UI 引擎提供通用的基础排版构件。

## 4. 预期使用场景
1. **2D 游戏与 Web 渲染的纹理图集（Texture Atlas）烘焙**：将游戏角色序列帧、UI 部件与图标自动合并进一张 2 的幂次方纹理图集中，大幅减少 GPU Draw Call 并消除边缘采样出血。
2. **矢量字体渲染中的动态字形缓存（Dynamic Glyph Atlas Cache）**：在渲染引擎运行时按需生成文字字形点阵/SDF，动态调用装箱算法紧密放入字形纹理缓存池，大幅降低显存消耗。
3. **前端/全栈构建工具的 CSS Sprite 与 SVG 拼合**：在静态站点生成器或 Web 打包流水线中，将批量 SVG/PNG 图标自动合并排版，并输出坐标偏移映射表（JSON Manifest）及排布预览。

## 5. 拟实现的核心功能
- **基础几何拓扑原语**：提供 `Rect`、`Size`、`Bin`，支持相交检测、包含性判定、90° 旋转变换以及内边距（Padding）与外边框间隙（Border）控制。
- **MaxRects（最大矩形法，业界黄金标准）**：维护最大自由矩形集，支持 BestShortSideFit、BestLongSideFit、BestAreaFit、BottomLeft、ContactPoint 5 种启发式规则，内置重叠矩形相交切分与包含去重剪枝。
- **Guillotine（断头台切分法）**：支持 6 种空闲选择规则与 6 种切分规则（ShorterAxis、LongerAxis、MinimizeArea 等），集成相邻空闲矩形合并（Merge Rectangles）防空间碎片化算法。
- **Shelf（货架分层法）**：支持 NextFit、FirstFit、BestHeightFit、BestAreaFit 策略，为等高图元提供 $O(N \log N)$ 极速装箱。
- **高级 AtlasPacker**：支持多纹理页（Multi-Bin）自动溢出分配、2 的幂次方（64~4096）自适应尺寸递增以及按面积/长边降序批量装箱。
- **可视化与数据导出**：内置一键导出带统计徽章与颜色标注的独立 SVG 预览图，以及标准 JSON 坐标布局清单。

## 6. 项目类型说明
本项目为**移植与增强项目**（Porting & Enhancement）。

## 7. 参考开源项目信息
- **参考项目 1**：RectangleBinPack (C++)
  - 来源链接：https://github.com/juj/RectangleBinPack
  - 许可证：Public Domain
- **参考项目 2**：rect_packer (Rust)
  - 来源链接：https://github.com/Pao/rect_packer
  - 许可证：MIT
- **本项目许可证**：Apache-2.0
- **对比与改造说明**：
  1. 现代类型系统建模：使用 MoonBit 代数数据类型（Enum）与模式匹配彻底替代原 C++ 宏定义和散落常量；
  2. 内存安全与轻量高效：摒弃裸指针，利用 MoonBit 动态数组进行原地分裂与剪枝，零外部依赖，天然适配 Wasm；
  3. 增强功能：新增原 C++ 库没有的多 Bin 自动溢出分配、POT 尺寸自适应收敛，以及 SVG/JSON 开箱即用导出能力。

## 8. GitHub 仓库链接与工程指标
- **GitHub 仓库链接**：https://github.com/zmjknn/moon_binpack
- **有效 Commit 记录**：仓库已包含 **20 个独立、语义明确的原生开发 Commit**（涵盖架构设计、算法拆分、测试用例编写、CI 集成），严格遵循提交规范，绝无无意义拆分。
- **自动化验证**：内置 17 组严格不变式测试（非重叠性、边界包含性、面积守恒性），配置 GitHub Actions CI，实现代码推送自动构建测试全绿灯。
