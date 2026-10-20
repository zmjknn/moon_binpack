# moon_binpack

[![CI](https://github.com/zmjknn/moon_binpack/actions/workflows/ci.yml/badge.svg)](https://github.com/zmjknn/moon_binpack/actions/workflows/ci.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20261016-purple.svg)](https://www.moonbitlang.com)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

`moon_binpack` is an industrial-grade, zero-dependency 2D rectangle bin packing and texture atlas layout engine implemented in 100% pure [MoonBit](https://www.moonbitlang.com).

It solves the classic NP-hard 2D Bin Packing Problem (2D-BPP), providing industry-standard heuristics for game developers, UI rendering engines, CSS sprite sheet generators, and font glyph atlas bakers across WebAssembly, Native, and JavaScript targets.

---

## Features

- **MaxRects Packing**:
  - Tracks all maximal overlapping free rectangles for optimal space utilization.
  - 5 heuristic placement rules:
    - Best Short Side Fit (`BestShortSideFit`)
    - Best Long Side Fit (`BestLongSideFit`)
    - Best Area Fit (`BestAreaFit`)
    - Bottom-Left Rule (`BottomLeftRule`)
    - Contact Point Rule (`ContactPointRule`)
  - Supports 90° rectangle rotation and area-descending batch insertion.
- **Guillotine Cut Packing**:
  - Partitions empty spaces using recursive guillotine cuts.
  - 6 free rect selection heuristics (`BestAreaFit`, `BestShortSideFit`, `BestLongSideFit`, `WorstAreaFit`, etc.).
  - 6 split strategies (`ShorterLeftoverAxis`, `LongerLeftoverAxis`, `MinimizeArea`, `MaximizeArea`, `ShorterAxis`, `LongerAxis`).
  - Adjacent free rectangle merging to eliminate space fragmentation.
- **Shelf Packing**:
  - Ultra-fast $O(N \log N)$ algorithm for items of similar heights (e.g. font glyphs, uniform icons).
  - Heuristics: `NextFit`, `FirstFit`, `BestAreaFit`, `BestHeightFit`, `WorstAreaFit`.
- **AtlasPacker (Multi-Bin & POT Adaptive)**:
  - Automatic multi-page allocation for overflowing item sets.
  - Adaptive Power-of-Two (POT: 64, 128, 256, 512, 1024, 2048, 4096) sizing.
  - Inner padding and border margin controls to prevent texture bleeding during bilinear GPU filtering.
- **Visualizer & Exporter**:
  - Standalone responsive SVG visualizer with item dimensions, occupancy badges, and color palettes.
  - Standard JSON layout manifest compatible with WebGL, Pixi.js, Phaser, and custom rendering pipelines.
- **Invariants & Reliability**:
  - Non-overlapping guarantee: $\forall i \neq j, R_i \cap R_j = \emptyset$
  - Boundary containment and area conservation verified by comprehensive automated property tests.

---

## Installation

Add `moon_binpack` to your MoonBit project:

```bash
moon add zmjknn/moon_binpack
```

Or declare it in your `moon.mod`:

```moonbit
import {
  "zmjknn/moon_binpack",
}
```

---

## Quick Start

### 1. MaxRects Packing

```moonbit
let packer = @moon_binpack.MaxRectsPacker::new(512, 512)

let items = [
  @moon_binpack.Size::new(128, 64),
  @moon_binpack.Size::new(96, 96),
  @moon_binpack.Size::new(64, 128),
  @moon_binpack.Size::new(48, 48),
]

let (packed, unpacked) = packer.insert_batch(
  items,
  heuristic=@moon_binpack.MaxRectsHeuristic::BestShortSideFit,
  allow_rotation=true,
)

println("Packed: " + packed.length().to_string() + ", Occupancy: " + (packer.occupancy() * 100.0).to_string() + "%")
```

### 2. High-Level AtlasPacker (Multi-Bin & POT Growth)

```moonbit
let options = @moon_binpack.AtlasOptions::{
  max_width: 1024,
  max_height: 1024,
  padding: 2,
  border_padding: 2,
  allow_rotation: true,
  auto_grow_pot: true,
  heuristic: @moon_binpack.MaxRectsHeuristic::BestShortSideFit,
}

let atlas = @moon_binpack.AtlasPacker::new(options~)
let result = atlas.pack(items)

println("Allocated pages: " + result.pages.length().to_string())
println("Packed rectangles: " + result.rects.length().to_string())
```

### 3. SVG & JSON Export

```moonbit
// Export to responsive standalone SVG
let svg = @moon_binpack.to_svg(512, 512, packed, title="Texture Atlas Preview")

// Export to JSON frame manifest
let json = @moon_binpack.to_json(512, 512, packed)
```

---

## Command Line Interface

Clone the repository and run the built-in CLI demo:

```bash
git clone https://github.com/zmjknn/moon_binpack.git
cd moon_binpack
moon run cmd/main
```

Output:

```text
==================================================================
  moon_binpack: Industrial-grade 2D Rectangle Bin Packing Engine  
==================================================================

Packing 16 items into 256x256 atlas...
Result:
  - Packed items:   16 / 16
  - Unpacked items: 0
  - Occupancy:      52.1%

Layout Frames:
  [ID]   X    Y    W    H   Rotated
  ---------------------------------
  #0   0   0   96   64   No
  #1   96   0   96   64   Yes
  #4   192   0   64   64   No
  #2   0   64   48   80   Yes
  #3   0   144   48   80   No
  ...

Generated SVG Preview (3717 bytes).
Done successfully!
```

---

## Testing & Verification

Run the full automated test suite:

```bash
moon test
```

All algorithms enforce strict invariants:
1. **Non-overlapping**: No placed rectangle intersects with any other placed rectangle.
2. **Boundary Containment**: All placed rectangles reside strictly within the designated bin $[0, \text{bin\_width}] \times [0, \text{bin\_height}]$.
3. **Rotation Consistency**: When rotated, coordinates $(w, h)$ are transposed with the `rotated = true` flag set.

---

## References & Attribution

- Jukka Jylänki, *"A Thousand Ways to Pack the Bin - A Practical Approach to Two-Dimensional Rectangle Bin Packing"*
- [RectangleBinPack (C++)](https://github.com/juj/RectangleBinPack) by Jukka Jylänki
- [rect_packer (Rust)](https://github.com/Pao/rect_packer) by Pao

---

## License

Licensed under the [Apache License, Version 2.0](LICENSE).