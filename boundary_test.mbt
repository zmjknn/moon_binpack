///|
test "boundary_zero_and_negative_dimensions" {
  let mr = @moon_binpack.MaxRectsPacker::new(256, 256)
  let sky = @moon_binpack.SkylinePacker::new(256, 256)
  let gui = @moon_binpack.GuillotinePacker::new(256, 256)
  let sh = @moon_binpack.ShelfPacker::new(256, 256)

  // Zero dimension
  assert_true(mr.insert(0, 10) is None)
  assert_true(mr.insert(10, 0) is None)
  assert_true(sky.insert(0, 10) is None)
  assert_true(sky.insert(10, 0) is None)
  assert_true(gui.insert(0, 10) is None)
  assert_true(gui.insert(10, 0) is None)
  assert_true(sh.insert(0, 10) is None)
  assert_true(sh.insert(10, 0) is None)

  // Negative dimension
  assert_true(mr.insert(-5, 10) is None)
  assert_true(mr.insert(10, -5) is None)
  assert_true(sky.insert(-5, 10) is None)
  assert_true(sky.insert(10, -5) is None)
  assert_true(gui.insert(-5, 10) is None)
  assert_true(gui.insert(10, -5) is None)
  assert_true(sh.insert(-5, 10) is None)
  assert_true(sh.insert(10, -5) is None)
}

///|
test "boundary_single_pixel_item" {
  let packer = @moon_binpack.MaxRectsPacker::new(64, 64)
  let r = packer.insert(1, 1, id=42)

  assert_true(r is Some(_))
  match r {
    Some(rect) => {
      assert_eq(rect.id, 42)
      assert_eq(rect.width, 1)
      assert_eq(rect.height, 1)
      assert_true(rect.x >= 0 && rect.y >= 0)
      assert_true(rect.right() <= 64 && rect.bottom() <= 64)
    }
    None => ()
  }
}

///|
test "boundary_item_exactly_matches_bin" {
  let packer = @moon_binpack.MaxRectsPacker::new(256, 256)
  let r = packer.insert(256, 256, id=1)

  assert_true(r is Some(_))
  match r {
    Some(rect) => {
      assert_eq(rect.x, 0)
      assert_eq(rect.y, 0)
      assert_eq(rect.width, 256)
      assert_eq(rect.height, 256)
    }
    None => ()
  }

  // Bin is now 100% full
  assert_eq(packer.occupancy(), 1.0)

  // Subsequent insertion must fail
  assert_true(packer.insert(1, 1) is None)
}

///|
test "boundary_item_exceeds_bin" {
  let mr = @moon_binpack.MaxRectsPacker::new(128, 128)
  let sky = @moon_binpack.SkylinePacker::new(128, 128)
  let gui = @moon_binpack.GuillotinePacker::new(128, 128)
  let sh = @moon_binpack.ShelfPacker::new(128, 128)

  assert_true(mr.insert(129, 64) is None)
  assert_true(mr.insert(64, 129) is None)
  assert_true(sky.insert(129, 64) is None)
  assert_true(sky.insert(64, 129) is None)
  assert_true(gui.insert(129, 64) is None)
  assert_true(gui.insert(64, 129) is None)
  assert_true(sh.insert(129, 64) is None)
  assert_true(sh.insert(64, 129) is None)
}

///|
test "boundary_prime_dimension_bin_and_items" {
  let bin_w = 317
  let bin_h = 419
  let packer = @moon_binpack.MaxRectsPacker::new(bin_w, bin_h)

  let primes = [
    @moon_binpack.Size::new(13, 17),
    @moon_binpack.Size::new(23, 29),
    @moon_binpack.Size::new(31, 37),
    @moon_binpack.Size::new(41, 43),
    @moon_binpack.Size::new(47, 53),
    @moon_binpack.Size::new(59, 61),
    @moon_binpack.Size::new(67, 71),
    @moon_binpack.Size::new(73, 79),
  ]

  let (packed, unpacked) = packer.insert_batch(primes, allow_rotation=true)
  assert_eq(unpacked.length(), 0)
  assert_eq(packed.length(), primes.length())

  // Verify strict containment and non-overlapping on prime coordinates
  for i = 0; i < packed.length(); i = i + 1 {
    let r1 = packed[i]
    assert_true(r1.x >= 0 && r1.y >= 0)
    assert_true(r1.right() <= bin_w && r1.bottom() <= bin_h)

    for j = i + 1; j < packed.length(); j = j + 1 {
      let r2 = packed[j]
      assert_false(r1.intersects(r2))
    }
  }
}

///|
test "boundary_64_identical_tiles" {
  let bin_w = 256
  let bin_h = 256
  let packer = @moon_binpack.MaxRectsPacker::new(bin_w, bin_h)

  let tiles = []
  for i = 0; i < 64; i = i + 1 {
    tiles.push(@moon_binpack.Size::new(32, 32))
  }

  let (packed, unpacked) = packer.insert_batch(tiles, allow_rotation=false)
  assert_eq(unpacked.length(), 0)
  assert_eq(packed.length(), 64)

  // 64 * 32 * 32 = 65536 = 256 * 256 -> 100% occupancy
  assert_eq(packer.occupancy(), 1.0)

  // Verify non-overlapping
  for i = 0; i < packed.length(); i = i + 1 {
    for j = i + 1; j < packed.length(); j = j + 1 {
      assert_false(packed[i].intersects(packed[j]))
    }
  }
}

///|
test "boundary_empty_items_array" {
  let empty_items : Array[@moon_binpack.Size] = []

  let atlas = @moon_binpack.AtlasPacker::new()
  let res = atlas.pack(empty_items)
  assert_eq(res.pages.length(), 0)
  assert_eq(res.rects.length(), 0)
  assert_eq(res.unpacked.length(), 0)

  let (best_res, best_name) = @moon_binpack.best_pack(empty_items)
  assert_eq(best_res.rects.length(), 0)
  assert_eq(best_name, "None")

  let empty_images : Array[@moon_binpack.ImageItem] = []
  let baker = @moon_binpack.AtlasBaker::new()
  let baked = baker.bake(empty_images)
  assert_eq(baked.length(), 0)

  let (baked_best, best_algo) = baker.bake_best(empty_images)
  assert_eq(baked_best.length(), 0)
  assert_eq(best_algo, "None")
}

///|
test "boundary_tga_export_verification" {
  let buf = @moon_binpack.PixelBuffer::new(
    64,
    32,
    color=@moon_binpack.Rgba::from_hex(0x38BDF8),
  )
  let tga_data = buf.to_tga()

  let expected_len = 18 + 64 * 32 * 4
  assert_eq(tga_data.length(), expected_len)

  // Verify TGA header
  assert_eq(tga_data[0], b'\x00') // id length
  assert_eq(tga_data[1], b'\x00') // colormap type
  assert_eq(tga_data[2], b'\x02') // uncompressed true-color
  // Width: 64 = 0x0040 (little endian)
  assert_eq(tga_data[12], b'\x40')
  assert_eq(tga_data[13], b'\x00')
  // Height: 32 = 0x0020 (little endian)
  assert_eq(tga_data[14], b'\x20')
  assert_eq(tga_data[15], b'\x00')
  // Bits per pixel: 32 = 0x20
  assert_eq(tga_data[16], b'\x20')
  // Image descriptor
  assert_eq(tga_data[17], b'\x28')

  // Bytes object test
  let tga_bytes = buf.to_tga_bytes()
  assert_eq(tga_bytes.length(), expected_len)
}

///|
test "boundary_drawing_and_alpha_blending" {
  let buf = @moon_binpack.PixelBuffer::new(32, 32)

  // Fill solid rect
  let red = @moon_binpack.Rgba::new(b'\xFF', b'\x00', b'\x00', a=b'\xFF')
  buf.draw_rect(4, 4, 16, 16, red, fill=true)

  assert_eq(buf.get_pixel(4, 4).r, b'\xFF')
  assert_eq(buf.get_pixel(19, 19).r, b'\xFF')
  assert_eq(buf.get_pixel(3, 3).r, b'\x00')

  // Porter-Duff alpha blending with 50% opacity green
  let semi_green = @moon_binpack.Rgba::new(b'\x00', b'\xFF', b'\x00', a=b'\x80')
  buf.blend_pixel(4, 4, semi_green)
  let blended = buf.get_pixel(4, 4)
  assert_true(blended.g > b'\x00')
  assert_true(blended.r > b'\x00')

  // Clear canvas
  buf.clear()
  assert_eq(buf.get_pixel(4, 4).a, b'\x00')
}

///|
test "boundary_uv_flipped_v_coordinate" {
  let rect = @moon_binpack.Rect::new(10, 20, 30, 40)
  let atlas_w = 100
  let atlas_h = 100

  // Regular UV (DirectX / WebGPU / Metal)
  let uv_std = rect.to_uv_ex(
    atlas_w,
    atlas_h,
    half_texel_inset=true,
    flip_v=false,
  )
  assert_true(uv_std.u_min > 0.0 && uv_std.u_max < 1.0)
  assert_true(uv_std.v_min > 0.0 && uv_std.v_max < 1.0)
  assert_true(uv_std.u_min < uv_std.u_max)
  assert_true(uv_std.v_min < uv_std.v_max)

  // Flipped V (WebGL / OpenGL)
  let uv_flipped = rect.to_uv_ex(
    atlas_w,
    atlas_h,
    half_texel_inset=true,
    flip_v=true,
  )
  assert_true(uv_flipped.v_min > 0.0 && uv_flipped.v_max < 1.0)
  assert_true(uv_flipped.v_min < uv_flipped.v_max)
  // When flipped: v_min_flipped + v_max_std == 1.0
  let sum_v = uv_flipped.v_min + uv_std.v_max
  assert_true((sum_v - 1.0).abs() < 0.0001)
}

///|
test "boundary_exporters_csv_and_pixi_json" {
  let rects = [
    @moon_binpack.Rect::new(0, 0, 64, 32, id=1, rotated=false, bin_index=0),
    @moon_binpack.Rect::new(64, 0, 32, 64, id=2, rotated=true, bin_index=0),
  ]

  // CSV
  let csv = @moon_binpack.to_csv(rects)
  assert_true(csv.contains("id,x,y,width,height,rotated,bin,area"))
  assert_true(csv.contains("1,0,0,64,32,false,0,2048"))
  assert_true(csv.contains("2,64,0,32,64,true,0,2048"))

  // PixiJS JSON
  let pixi_json = @moon_binpack.to_pixi_json(
    128,
    128,
    rects,
    image_name="test_atlas.png",
  )
  assert_true(pixi_json.contains("\"frame_1\""))
  assert_true(pixi_json.contains("\"frame_2\""))
  assert_true(pixi_json.contains("\"image\": \"test_atlas.png\""))
  assert_true(pixi_json.contains("\"format\": \"RGBA8888\""))
}
