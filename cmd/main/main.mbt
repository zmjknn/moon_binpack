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

  println(
    "Packing " +
    items.length().to_string() +
    " items into " +
    bin_w.to_string() +
    "x" +
    bin_h.to_string() +
    " atlas...",
  )

  let (packed, unpacked) = packer.insert_batch(
    items,
    heuristic=@lib.MaxRectsHeuristic::BestShortSideFit,
    allow_rotation=true,
  )

  let occupancy_pct = (packer.occupancy() * 1000.0).to_int().to_double() / 10.0

  println("Result:")
  println(
    "  - Packed items:   " +
    packed.length().to_string() +
    " / " +
    items.length().to_string(),
  )
  println("  - Unpacked items: " + unpacked.length().to_string())
  println("  - Occupancy:      " + occupancy_pct.to_string() + "%")
  println("")
  println("Layout Frames:")
  println("  [ID]   X    Y    W    H   Rotated")
  println("  ---------------------------------")
  for r in packed {
    let rot_str = if r.rotated { "Yes" } else { "No" }
    println(
      "  #" +
      r.id.to_string() +
      "   " +
      r.x.to_string() +
      "   " +
      r.y.to_string() +
      "   " +
      r.width.to_string() +
      "   " +
      r.height.to_string() +
      "   " +
      rot_str,
    )
  }

  println("")
  let svg = @lib.to_svg(bin_w, bin_h, packed, title="moon_binpack Demo Atlas")
  let css = @lib.to_css(packed, class_prefix="sprite")
  let html = @lib.to_html(
    bin_w,
    bin_h,
    packed,
    title="moon_binpack Interactive Report",
  )
  println("Generated Exporters:")
  println("  - SVG Preview:    " + svg.length().to_string() + " bytes")
  println("  - CSS Sprites:    " + css.length().to_string() + " bytes")
  println("  - HTML Report:    " + html.length().to_string() + " bytes")

  println("")
  println("Running Heuristic Arena (best_pack)...")
  let (best_res, winning_algo) = @lib.best_pack(
    items,
    max_width=512,
    max_height=512,
  )
  let best_pct = (best_res.stats.occupancy * 1000.0).to_int().to_double() / 10.0
  println("  - Winning Heuristic: " + winning_algo)
  println("  - Pages:             " + best_res.pages.length().to_string())
  println("  - Occupancy:         " + best_pct.to_string() + "%")

  println("")
  println("Demonstrating Extruded Pixel Texture Baker (Layer 2)...")
  let img1 = @lib.PixelBuffer::new(48, 32, color=@lib.Rgba::from_hex(0xFF4444))
  let img2 = @lib.PixelBuffer::new(32, 48, color=@lib.Rgba::from_hex(0x44FF44))
  let img3 = @lib.PixelBuffer::new(24, 24, color=@lib.Rgba::from_hex(0x4444FF))

  let baker_items = [
    @lib.ImageItem::new(1, img1),
    @lib.ImageItem::new(2, img2),
    @lib.ImageItem::new(3, img3),
  ]

  let baker = @lib.AtlasBaker::new(extrude_margin=1)
  let baked_pages = baker.bake(baker_items)
  if baked_pages.length() > 0 {
    let p0 = baked_pages[0]
    let bmp = p0.image.to_bmp()
    println(
      "  - Baked Atlas Dimensions: " +
      p0.image.width().to_string() +
      "x" +
      p0.image.height().to_string() +
      " px",
    )
    println("  - Extruded Bleeding Margin: 1 px duplicate border")
    println(
      "  - Generated Windows Bitmap: " +
      bmp.length().to_string() +
      " bytes (32-bit uncompressed BMP)",
    )
    if p0.uv_frames.length() > 0 {
      let uv = p0.uv_frames[0]
      println(
        "  - Frame #1 Shader Half-Texel UV: [" +
        uv.u_min.to_string() +
        ", " +
        uv.v_min.to_string() +
        "] -> [" +
        uv.u_max.to_string() +
        ", " +
        uv.v_max.to_string() +
        "]",
      )
    }
  }

  println("")
  println("Done successfully!")
}
