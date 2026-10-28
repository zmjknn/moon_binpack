///|
/// Realistic benchmark dataset simulating a typical 2D RPG / action game UI sprite sheet:
/// contains 64 items across diverse standard categories:
/// - Small system icons (16x16, 24x24)
/// - Inventory item tiles and action badges (32x32, 40x40, 48x48)
/// - Skill icons and avatar portraits (64x64, 80x80)
/// - Horizontal progress bars and status gauges (128x24, 160x32, 200x40)
/// - Vertical equipment cards and weapon slots (48x128, 64x160)
/// - Character portrait cards and banner cards (120x80, 160x100)
pub fn game_ui_sprites() -> Array[Size] {
  [
    // Small action & status icons
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(20, 20),
    Size::new(20, 20),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    // Standard inventory tiles & buttons
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(40, 40),
    Size::new(40, 40),
    Size::new(40, 40),
    Size::new(40, 40),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    // Equipment & skill icons
    Size::new(56, 56),
    Size::new(56, 56),
    Size::new(64, 64),
    Size::new(64, 64),
    Size::new(64, 64),
    Size::new(64, 64),
    Size::new(72, 72),
    Size::new(80, 80),
    // Horizontal gauges & health bars
    Size::new(96, 32),
    Size::new(96, 32),
    Size::new(128, 24),
    Size::new(128, 32),
    Size::new(128, 48),
    Size::new(160, 32),
    Size::new(180, 36),
    Size::new(200, 40),
    // Vertical weapon slots & banners
    Size::new(32, 96),
    Size::new(32, 128),
    Size::new(48, 96),
    Size::new(48, 128),
    Size::new(48, 144),
    Size::new(64, 128),
    Size::new(64, 160),
    // Rectangular cards & portrait frames
    Size::new(80, 60),
    Size::new(80, 60),
    Size::new(90, 60),
    Size::new(100, 70),
    Size::new(100, 70),
    Size::new(120, 80),
    Size::new(120, 90),
    Size::new(140, 90),
    Size::new(150, 100),
    // Mixed UI fragments
    Size::new(36, 36),
    Size::new(44, 44),
    Size::new(52, 28),
    Size::new(28, 52),
    Size::new(68, 34),
    Size::new(34, 68),
    Size::new(84, 42),
    Size::new(42, 84),
  ]
}

///|
/// Realistic benchmark dataset simulating a vector font glyph cache:
/// 80 characters representing Chinese ideographs (Hanzi), Japanese Kana,
/// and extended Latin glyph bounding boxes with uniform or stepped heights:
/// - 16px font size row (width varies 6px..16px)
/// - 24px font size row (width varies 8px..24px)
/// - 32px font size row (width varies 12px..32px)
/// - 48px headline glyphs (width varies 16px..48px)
pub fn font_glyph_cache() -> Array[Size] {
  [
    // 16px row (narrow to square)
    Size::new(6, 16),
    Size::new(8, 16),
    Size::new(10, 16),
    Size::new(12, 16),
    Size::new(14, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(8, 16),
    Size::new(10, 16),
    Size::new(12, 16),
    Size::new(14, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 16),
    // 24px row
    Size::new(10, 24),
    Size::new(12, 24),
    Size::new(14, 24),
    Size::new(18, 24),
    Size::new(20, 24),
    Size::new(22, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(12, 24),
    Size::new(14, 24),
    Size::new(18, 24),
    Size::new(20, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(24, 24),
    // 32px row (standard high-DPI CJK glyphs)
    Size::new(14, 32),
    Size::new(16, 32),
    Size::new(20, 32),
    Size::new(24, 32),
    Size::new(28, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(16, 32),
    Size::new(20, 32),
    Size::new(24, 32),
    Size::new(28, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 32),
    // 48px headline glyphs
    Size::new(24, 48),
    Size::new(28, 48),
    Size::new(32, 48),
    Size::new(36, 48),
    Size::new(40, 48),
    Size::new(44, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(28, 48),
    Size::new(32, 48),
    Size::new(36, 48),
    Size::new(40, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(48, 48),
  ]
}

///|
/// Pathological / stress test dataset containing 32 extreme aspect ratio items:
/// needle-like horizontal and vertical strips (aspect ratios up to 128:1),
/// prime dimension shapes, and large awkward blocks.
pub fn pathological_aspect_ratios() -> Array[Size] {
  [
    // Extreme horizontal ribbons
    Size::new(128, 2),
    Size::new(128, 3),
    Size::new(200, 4),
    Size::new(250, 5),
    Size::new(300, 6),
    Size::new(150, 3),
    Size::new(180, 4),
    Size::new(220, 5),
    // Extreme vertical needles
    Size::new(2, 128),
    Size::new(3, 128),
    Size::new(4, 200),
    Size::new(5, 250),
    Size::new(6, 300),
    Size::new(3, 150),
    Size::new(4, 180),
    Size::new(5, 220),
    // Prime dimensions (resists clean division)
    Size::new(17, 31),
    Size::new(31, 17),
    Size::new(43, 67),
    Size::new(67, 43),
    Size::new(53, 79),
    Size::new(79, 53),
    Size::new(97, 23),
    Size::new(23, 97),
    // Large dominant blocks mixed with slivers
    Size::new(180, 180),
    Size::new(190, 110),
    Size::new(110, 190),
    Size::new(200, 2),
    Size::new(2, 200),
    Size::new(15, 15),
    Size::new(13, 13),
    Size::new(11, 11),
  ]
}

///|
/// Large-scale dataset of 160 mixed items to stress-test multi-bin automatic overflow,
/// memory stability, and execution speed across multiple atlas pages.
pub fn large_scale_sprites() -> Array[Size] {
  let list = []
  let base_ui = game_ui_sprites()
  for item in base_ui {
    list.push(item)
  }
  let font = font_glyph_cache()
  for item in font {
    list.push(item)
  }
  let path = pathological_aspect_ratios()
  for item in path {
    if list.length() < 160 {
      list.push(item)
    }
  }
  list
}
