///|
/// Interactive CLI entry point and demonstration for moon_binpack.
fn main {
  println("==================================================================")
  println("  moon_binpack: Industrial-grade 2D Rectangle Bin Packing Engine  ")
  println("==================================================================")
  println("")

  let bin_w = 256
  let bin_h = 256
  let packer = @lib.MaxRectsPacker::new(bin_w, bin_h)

  let items = [
    @lib.Size::new(96, 64),
    @lib.Size::new(64, 96),
    @lib.Size::new(80, 48),
    @lib.Size::new(48, 80),
    @lib.Size::new(64, 64),
    @lib.Size::new(48, 48),
    @lib.Size::new(48, 32),
    @lib.Size::new(32, 48),
    @lib.Size::new(32, 32),
    @lib.Size::new(32, 32),
    @lib.Size::new(24, 24),
    @lib.Size::new(24, 24),
    @lib.Size::new(16, 32),
    @lib.Size::new(32, 16),
    @lib.Size::new(16, 16),
    @lib.Size::new(16, 16),
  ]

  println("Packing " + items.length().to_string() + " items into " + bin_w.to_string() + "x" + bin_h.to_string() + " atlas...")

  let (packed, unpacked) = packer.insert_batch(
    items,
    heuristic=@lib.MaxRectsHeuristic::BestShortSideFit,
    allow_rotation=true,
  )

  let occupancy_pct = (packer.occupancy() * 1000.0).to_int().to_double() / 10.0

  println("Result:")
  println("  - Packed items:   " + packed.length().to_string() + " / " + items.length().to_string())
  println("  - Unpacked items: " + unpacked.length().to_string())
  println("  - Occupancy:      " + occupancy_pct.to_string() + "%")
  println("")
  println("Layout Frames:")
  println("  [ID]   X    Y    W    H   Rotated")
  println("  ---------------------------------")
  for r in packed {
    let rot_str = if r.rotated { "Yes" } else { "No" }
    println("  #" + r.id.to_string() + "   " + r.x.to_string() + "   " + r.y.to_string() + "   " + r.width.to_string() + "   " + r.height.to_string() + "   " + rot_str)
  }

  println("")
  let svg = @lib.to_svg(bin_w, bin_h, packed, title="moon_binpack Demo Atlas")
  println("Generated SVG Preview (" + svg.length().to_string() + " bytes).")
  println("Done successfully!")
}
