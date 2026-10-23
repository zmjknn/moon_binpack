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

test "pixel_buffer_blit" {
  let canvas = @moon_binpack.PixelBuffer::new(50, 50, color=@moon_binpack.Rgba::transparent())
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

test "pixel_buffer_extrude_bleeding_prevention" {
  let canvas = @moon_binpack.PixelBuffer::new(30, 30, color=@moon_binpack.Rgba::transparent())
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
}
