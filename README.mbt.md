# moon_binpack

[![CI](https://github.com/zmjknn/moon_binpack/actions/workflows/ci.yml/badge.svg)](https://github.com/zmjknn/moon_binpack/actions/workflows/ci.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20261016-purple.svg)](https://www.moonbitlang.com)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-48%20passed-brightgreen.svg)](https://github.com/zmjknn/moon_binpack)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero-success.svg)](moon.mod)

`moon_binpack` is an industrial-grade, zero-dependency 2D rectangle bin packing and anti-bleeding texture atlas baking engine implemented in 100% pure [MoonBit](https://www.moonbitlang.com).

Targeted at 2D game rendering, Web/UI font glyph caching, CSS sprite generation, and WebGPU/WebGL build pipelines, `moon_binpack` provides a clear, decoupled two-tier architecture:
1. **Layer 1: Pure Geometric Topology Engine**: Solves the NP-hard 2D Bin Packing Problem (2D-BPP) across 4 classic algorithm families (MaxRects, Skyline, Guillotine, Shelf) and features an automated **18-heuristic arena (`best_pack`)** with multi-page overflow and Power-of-Two (POT) auto-growth.
2. **Layer 2: Physical Extrusion Texture Baker (Zero GPU Bleeding)**: In-memory RGBA pixel canvas with sub-image blitting, physical 1-pixel edge extrusion, shader half-texel UV inset compensation (supporting both DirectX/WebGPU and WebGL/OpenGL vertical axes), and pure MoonBit uncompressed 32-bit Windows Bitmap (`.bmp`) and Truevision TGA (`.tga`) encoders.
3. **Web & Game Engine Exporters**: Standalone responsive SVG vector visualizers, standard JSON manifests, Pixi.js / Phaser JSON Hash format, CSS sprite rule generators, CSV CAD/spreadsheet data tables, and self-contained interactive dark-mode HTML inspection reports.

---

## Features

### Layer 1: Geometric Layout Engine

- **MaxRects (Maximal Rectangles)**:
  - Tracks all maximal empty spaces for optimal packing density.
  - 5 heuristic placement rules: `BestShortSideFit`, `BestLongSideFit`, `BestAreaFit`, `BottomLeftRule`, `ContactPointRule`.
  - Supports 90° rotation and area-descending batch insertion.
- **Skyline (Dynamic Contour Line)**:
  - High-speed contour line tracking for low computational overhead.
  - Heuristics: `BottomLeft`, `MinWasteFit` with dynamic segment splitting and contiguous elevation merging.
- **Guillotine Cut Packing**:
  - Partitions empty space with recursive edge-to-edge guillotine cuts.
  - 6 selection heuristics: `BestAreaFit`, `BestShortSideFit`, `BestLongSideFit`, `WorstAreaFit`, `WorstShortSideFit`, `WorstLongSideFit`.
  - 6 split heuristics: `ShorterLeftoverAxis`, `LongerLeftoverAxis`, `MinimizeArea`, `MaximizeArea`, `ShorterAxis`, `LongerAxis`.
  - Adjacent free rectangle merging and batch insertion.
- **Shelf Packing**:
  - Ultra-fast $O(N \log N)$ algorithm tailored for uniform-height items such as font glyph caches and icon sets.
  - 5 heuristics: `NextFit`, `FirstFit`, `BestAreaFit`, `BestHeightFit`, `WorstAreaFit`.
- **AtlasPacker & 18-Heuristic Competitive Arena (`best_pack`)**:
  - Automatically tests all 18 heuristics across all 4 algorithm families to select the most space-efficient layout.
  - Automatic multi-page overflow and Power-of-Two (POT: 64 to 4096) adaptive bin sizing.
  - Configurable inner padding and outer border margin.

### Layer 2: Extruded Pixel Texture Baker (Zero GPU Bleeding)

- **Physical 1-Pixel Edge Extrusion (`extrude_rect`)**:
  - Replicates outer 1-pixel border colors outward into surrounding padding margins.
  - Physically eliminates dark borders and neighboring color bleeding caused by GPU bilinear filtering and mipmap interpolation.
- **Shader Half-Texel Inset UV Compensation (`to_uv_ex`)**:
  - Calculates shader-ready normalized UV intervals inset by half a texel:
    $$u_{\min} = \frac{x + 0.5}{W}, \quad v_{\min} = \frac{y + 0.5}{H}, \quad u_{\max} = \frac{x + W - 0.5}{W}, \quad v_{\max} = \frac{y + H - 0.5}{H}$$
  - Dual vertical axis support: top-left origin (DirectX / Vulkan / Metal / WebGPU) and bottom-left origin (`flip_v = true` for WebGL / OpenGL).
- **Pure MoonBit Native Image Encoders**:
  - **Windows Bitmap (`to_bmp`, `to_bmp_bytes`)**: 32-bit uncompressed DIB (`.bmp`) with standard `BM` header.
  - **Truevision TGA (`to_tga`, `to_tga_bytes`)**: 32-bit uncompressed true-color (`.tga`) widely supported by game engines.
- **In-Memory Canvas Utilities**:
  - Sub-image blitting with 90° rotation, solid/outline rect drawing (`draw_rect`), canvas clearing, and Porter-Duff alpha blending (`blend_pixel`).

### Multi-Ecosystem Exporters

- **SVG (`to_svg`)**: Scalable, dark-mode SVG with occupancy badge and individual coordinate labels.
- **Standard JSON (`to_json`)**: Standardized coordinate manifest for generic WebGL / Canvas loaders.
- **Pixi.js / Phaser JSON (`to_pixi_json`)**: TexturePacker compatible JSON Hash format directly loadable in modern HTML5 game engines.
- **CSS Sprites (`to_css`)**: Negative offset background positions for web UI icons.
- **CSV (`to_csv`)**: Flat table for CAD / CNC nesting analysis and statistical inspection.
- **Interactive HTML Report (`to_html`)**: Dark-mode self-contained visual inspection dashboard with metrics cards, SVG layout preview, and coordinate data table.

---

## Installation

Add `moon_binpack` to your MoonBit project:

```bash
moon add zmjknn/moon_binpack
```

Or declare it in your `moon.mod`:

```moonbit nocheck
///|
import {
  "zmjknn/moon_binpack",
}
```

---

## Quick Start

### 1. 18-Heuristic Arena (`best_pack`)

```moonbit nocheck
let items = [
  @moon_binpack.Size::new(128, 64),
  @moon_binpack.Size::new(64, 128),
  @moon_binpack.Size::new(96, 96),
  @moon_binpack.Size::new(48, 48),
]

let (best_res, winning_algo) = @moon_binpack.best_pack(
  items,
  max_width=512,
  max_height=512,
)

println("Winning Heuristic: " + winning_algo)
println("Occupancy: " + (best_res.stats.occupancy * 100.0).to_string() + "%")
```

### 2. Physical 1-Pixel Edge Extrusion & Dual BMP / TGA Baking (Layer 2)

```moonbit nocheck
let img1 = @moon_binpack.PixelBuffer::new(48, 32, color=@moon_binpack.Rgba::from_hex(0xFF4444))
let img2 = @moon_binpack.PixelBuffer::new(32, 48, color=@moon_binpack.Rgba::from_hex(0x44FF44))

let items = [
  @moon_binpack.ImageItem::new(1, img1),
  @moon_binpack.ImageItem::new(2, img2),
]

// Automatically benchmarks layout and bakes with 1-pixel outer edge extrusion
let baker = @moon_binpack.AtlasBaker::new(extrude_margin=1)
let (baked_pages, winner) = baker.bake_best(items)

let page0 = baked_pages[0]

// Pure MoonBit zero-dependency image encoding
let bmp_bytes = page0.image.to_bmp_bytes()
let tga_bytes = page0.image.to_tga_bytes()

// Half-texel UV coordinates for WebGPU / DirectX shaders
let uv_webgpu = page0.uv_frames[0]
```

### 3. Exporters: SVG, CSS, PixiJS JSON, CSV, and HTML

```moonbit nocheck
// Scalable SVG preview
///|
let svg = @moon_binpack.to_svg(512, 512, best_res.rects, title="Atlas Preview")

// TexturePacker / Pixi.js / Phaser JSON manifest

///|
let pixi_json = @moon_binpack.to_pixi_json(
  512,
  512,
  best_res.rects,
  image_name="atlas.png",
)

// Production CSS sprite classes

///|
let css = @moon_binpack.to_css(best_res.rects, class_prefix="sprite")

// CSV layout table for spreadsheet / CAD

///|
let csv = @moon_binpack.to_csv(best_res.rects)

// Standalone interactive dark-mode HTML inspection dashboard

///|
let html = @moon_binpack.to_html(
  512,
  512,
  best_res.rects,
  title="Quality Inspection Report",
)
```

---

## Command Line Interface (CLI) Demo

Run the built-in CLI demonstration:

```bash
moon run cmd/main
```

---

## Testing

Execute the automated test suite:

```bash
moon test
```

Result:

```text
Total tests: 48, passed: 48, failed: 0.
```

---

## References & Attribution

- Jukka Jylänki, *"A Thousand Ways to Pack the Bin - A Practical Approach to Two-Dimensional Rectangle Bin Packing"*
- [RectangleBinPack (C++)](https://github.com/juj/RectangleBinPack) by Jukka Jylänki (Public Domain)
- [rect_packer (Rust)](https://github.com/Pao/rect_packer) by Pao (MIT)

---

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
