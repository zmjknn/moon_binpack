///|
test "rgba_and_pixel_buffer" {
  let red = @moon_binpack.Rgba::new(b'\xFF', b'\x00', b'\x00')
  let green = @moon_binpack.Rgba::from_hex(0x00FF00)
  let trans = @moon_binpack.Rgba::transparent()

  assert_eq(red.r, b'\xFF')
  assert_eq(red.g, b'\x00')
  assert_eq(red.b, b'\x00')
  assert_eq(red.a, b'\xFF')

  assert_eq(green.r, b'\x00')
  assert_eq(green.g, b'\xFF')
  assert_eq(green.b, b'\x00')

  assert_eq(trans.a, b'\x00')

  let buf = @moon_binpack.PixelBuffer::new(32, 32, color=trans)
  assert_eq(buf.width(), 32)
  assert_eq(buf.height(), 32)
  assert_eq(buf.get_pixel(10, 10).a, b'\x00')

  buf.set_pixel(10, 10, red)
  assert_eq(buf.get_pixel(10, 10), red)
}

///|
test "pixel_buffer_blit" {
  let canvas = @moon_binpack.PixelBuffer::new(
    50,
    50,
    color=@moon_binpack.Rgba::transparent(),
  )
  let blue = @moon_binpack.Rgba::new(b'\x00', b'\x00', b'\xFF')
  let sprite = @moon_binpack.PixelBuffer::new(10, 10, color=blue)

  canvas.blit(sprite, 15, 20)

  // Sub-image region should now be blue
  assert_eq(canvas.get_pixel(15, 20), blue)
  assert_eq(canvas.get_pixel(24, 29), blue)

  // Outside region remains transparent
  assert_eq(canvas.get_pixel(14, 20).a, b'\x00')
  assert_eq(canvas.get_pixel(25, 20).a, b'\x00')
}

///|
test "pixel_buffer_extrude_bleeding_prevention" {
  let canvas = @moon_binpack.PixelBuffer::new(
    30,
    30,
    color=@moon_binpack.Rgba::transparent(),
  )
  let red = @moon_binpack.Rgba::new(b'\xFF', b'\x00', b'\x00')

  // Place a 4x4 red square at (10, 10)
  for y = 10; y < 14; y = y + 1 {
    for x = 10; x < 14; x = x + 1 {
      canvas.set_pixel(x, y, red)
    }
  }

  let rect = @moon_binpack.Rect::new(10, 10, 4, 4)
  // Extrude 1 pixel outer border into padding margin
  canvas.extrude_rect(rect, margin=1)

  // Verify that the 1-pixel margin around the rectangle has been replicated
  // Top neighbor (10, 9)
  assert_eq(canvas.get_pixel(10, 9), red)
  // Bottom neighbor (10, 14)
  assert_eq(canvas.get_pixel(10, 14), red)
  // Left neighbor (9, 10)
  assert_eq(canvas.get_pixel(9, 10), red)
  // Right neighbor (14, 10)
  assert_eq(canvas.get_pixel(14, 10), red)
  // Top-left corner (9, 9)
  assert_eq(canvas.get_pixel(9, 9), red)
  // Bottom-right corner (14, 14)
  assert_eq(canvas.get_pixel(14, 14), red)

  // Distant pixel (5, 5) remains unaffected transparent
  assert_eq(canvas.get_pixel(5, 5).a, b'\x00')
}

///|
test "bmp_encoding_validity" {
  let w = 16
  let h = 16
  let red = @moon_binpack.Rgba::new(b'\xFF', b'\x00', b'\x00')
  let buf = @moon_binpack.PixelBuffer::new(w, h, color=red)

  let bmp_arr = buf.to_bmp()
  let expected_size = 54 + w * h * 4
  assert_eq(bmp_arr.length(), expected_size)

  // Check magic number 'BM'
  assert_eq(bmp_arr[0], b'B')
  assert_eq(bmp_arr[1], b'M')

  // Check offset to pixel data = 54
  assert_eq(bmp_arr[10], b'\x36')

  // Check biSize = 40
  assert_eq(bmp_arr[14], b'\x28')

  // Check biBitCount = 32
  assert_eq(bmp_arr[28], b'\x20')

  // Check bytes export
  let bmp_bytes = buf.to_bmp_bytes()
  assert_eq(bmp_bytes.length(), expected_size)
}

///|
test "half_texel_uv_offset" {
  let r = @moon_binpack.Rect::new(10, 20, 30, 40)
  let atlas_w = 100
  let atlas_h = 100

  // With half-texel offset compensation:
  // u_min = (10 + 0.5) / 100.0 = 0.105
  // v_min = (20 + 0.5) / 100.0 = 0.205
  // u_max = (40 - 0.5) / 100.0 = 0.395
  // v_max = (60 - 0.5) / 100.0 = 0.595
  let uv = r.to_uv(atlas_w, atlas_h, half_texel_inset=true)
  assert_true(uv.u_min > 0.104 && uv.u_min < 0.106)
  assert_true(uv.v_min > 0.204 && uv.v_min < 0.206)
  assert_true(uv.u_max > 0.394 && uv.u_max < 0.396)
  assert_true(uv.v_max > 0.594 && uv.v_max < 0.596)

  // Standard raw UV without inset
  let raw_uv = r.to_uv(atlas_w, atlas_h, half_texel_inset=false)
  assert_eq(raw_uv.u_min, 0.1)
  assert_eq(raw_uv.v_min, 0.2)
  assert_eq(raw_uv.u_max, 0.4)
  assert_eq(raw_uv.v_max, 0.6)
}

///|
test "atlas_baker_full_pipeline" {
  let c1 = @moon_binpack.Rgba::new(b'\xFF', b'\x00', b'\x00')
  let c2 = @moon_binpack.Rgba::new(b'\x00', b'\xFF', b'\x00')
  let c3 = @moon_binpack.Rgba::new(b'\x00', b'\x00', b'\xFF')

  let img1 = @moon_binpack.PixelBuffer::new(20, 20, color=c1)
  let img2 = @moon_binpack.PixelBuffer::new(30, 15, color=c2)
  let img3 = @moon_binpack.PixelBuffer::new(15, 25, color=c3)

  let items = [
    @moon_binpack.ImageItem::new(1, img1),
    @moon_binpack.ImageItem::new(2, img2),
    @moon_binpack.ImageItem::new(3, img3),
  ]

  let opts = @moon_binpack.AtlasOptions::{
    max_width: 256,
    max_height: 256,
    padding: 2,
    border_padding: 2,
    allow_rotation: false,
    auto_grow_pot: true,
    heuristic: @moon_binpack.MaxRectsHeuristic::BestShortSideFit,
  }

  let baker = @moon_binpack.AtlasBaker::new(options=opts, extrude_margin=1)
  let baked = baker.bake(items)

  assert_eq(baked.length(), 1)
  let page0 = baked[0]
  assert_eq(page0.frames.length(), 3)
  assert_eq(page0.uv_frames.length(), 3)
  assert_true(page0.image.width() >= 64)
  assert_true(page0.image.height() >= 64)

  // Check that the baked page can be exported to valid BMP
  let bmp = page0.image.to_bmp()
  assert_true(bmp.length() > 54)

  // Verify pixels match the respective source images
  for f in page0.frames {
    let p = page0.image.get_pixel(f.x, f.y)
    if f.id == 1 {
      assert_eq(p, c1)
    } else if f.id == 2 {
      assert_eq(p, c2)
    } else if f.id == 3 {
      assert_eq(p, c3)
    }
  }
}

///|
test "regression_id_preservation_single_item_42" {
  let red = @moon_binpack.Rgba::from_hex(0xFF0000)
  let img = @moon_binpack.PixelBuffer::new(16, 16, color=red)
  let item = @moon_binpack.ImageItem::new(42, img)

  let baker = @moon_binpack.AtlasBaker::new(extrude_margin=1)
  let baked = baker.bake([item])

  assert_eq(baked.length(), 1)
  let page = baked[0]
  assert_eq(page.frames.length(), 1)
  let frame = page.frames[0]
  // ID must be strictly preserved as 42
  assert_eq(frame.id, 42)

  // Pixel at frame.x, frame.y MUST NOT be blank/transparent! It must be red!
  let pixel = page.image.get_pixel(frame.x, frame.y)
  assert_eq(pixel.r, b'\xFF')
  assert_eq(pixel.g, b'\x00')
  assert_eq(pixel.b, b'\x00')
  assert_eq(pixel.a, b'\xFF')

  // Also verify bake_best
  let (baked_best, _winner) = baker.bake_best([item])
  assert_eq(baked_best.length(), 1)
  let best_page = baked_best[0]
  assert_eq(best_page.frames.length(), 1)
  let best_frame = best_page.frames[0]
  assert_eq(best_frame.id, 42)
  let best_pixel = best_page.image.get_pixel(best_frame.x, best_frame.y)
  assert_eq(best_pixel.r, b'\xFF')
  assert_eq(best_pixel.g, b'\x00')
  assert_eq(best_pixel.b, b'\x00')
  assert_eq(best_pixel.a, b'\xFF')
}

///|
test "regression_id_preservation_items_1_and_2_no_drop_or_swap" {
  let red = @moon_binpack.Rgba::from_hex(0xFF0000)
  let green = @moon_binpack.Rgba::from_hex(0x00FF00)
  let img1 = @moon_binpack.PixelBuffer::new(24, 16, color=red)
  let img2 = @moon_binpack.PixelBuffer::new(16, 24, color=green)

  let items = [
    @moon_binpack.ImageItem::new(1, img1),
    @moon_binpack.ImageItem::new(2, img2),
  ]

  let baker = @moon_binpack.AtlasBaker::new(extrude_margin=1)
  let (baked_pages, _winner) = baker.bake_best(items)

  assert_eq(baked_pages.length(), 1)
  let page = baked_pages[0]
  assert_eq(page.frames.length(), 2)

  let mut frame1 : @moon_binpack.Rect? = None
  let mut frame2 : @moon_binpack.Rect? = None
  for f in page.frames {
    if f.id == 1 {
      frame1 = Some(f)
    } else if f.id == 2 {
      frame2 = Some(f)
    }
  }

  // Both frames with ID 1 and 2 must exist
  assert_true(frame1 is Some(_))
  assert_true(frame2 is Some(_))

  match (frame1, frame2) {
    (Some(f1), Some(f2)) => {
      // Frame 1 MUST contain red pixels (img1), NOT blank and NOT green!
      let p1 = page.image.get_pixel(f1.x, f1.y)
      assert_eq(p1.r, b'\xFF')
      assert_eq(p1.g, b'\x00')
      assert_eq(p1.b, b'\x00')
      assert_eq(p1.a, b'\xFF')

      // Frame 2 MUST contain green pixels (img2), NOT blank and NOT red!
      let p2 = page.image.get_pixel(f2.x, f2.y)
      assert_eq(p2.r, b'\x00')
      assert_eq(p2.g, b'\xFF')
      assert_eq(p2.b, b'\x00')
      assert_eq(p2.a, b'\xFF')
    }
    _ => ()
  }
}
