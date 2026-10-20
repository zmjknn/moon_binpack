test "atlas_packer_auto_grow" {
  let opts = @moon_binpack.AtlasOptions::{
    max_width: 1024,
    max_height: 1024,
    padding: 2,
    border_padding: 2,
    allow_rotation: true,
    auto_grow_pot: true,
    heuristic: @moon_binpack.MaxRectsHeuristic::BestShortSideFit,
  }

  let packer = @moon_binpack.AtlasPacker::new(options=opts)
  let items = [
    @moon_binpack.Size::new(40, 40),
    @moon_binpack.Size::new(50, 30),
    @moon_binpack.Size::new(20, 20),
    @moon_binpack.Size::new(30, 40),
  ]

  let res = packer.pack(items)
  assert_eq(res.unpacked.length(), 0)
  assert_eq(res.rects.length(), 4)
  assert_eq(res.pages.length(), 1)

  // Should fit into 128x128 (smallest POT page that fits these items)
  assert_true(res.pages[0].width <= 256)

  // Verify non-overlapping
  for i = 0; i < res.rects.length(); i = i + 1 {
    for j = i + 1; j < res.rects.length(); j = j + 1 {
      assert_false(res.rects[i].intersects(res.rects[j]))
    }
  }
}

test "atlas_packer_multi_bin_overflow" {
  // Bins are small (60x60). 4 items of 50x50 can't fit into one 60x60 bin
  let opts = @moon_binpack.AtlasOptions::{
    max_width: 60,
    max_height: 60,
    padding: 0,
    border_padding: 0,
    allow_rotation: false,
    auto_grow_pot: false,
    heuristic: @moon_binpack.MaxRectsHeuristic::BestShortSideFit,
  }

  let packer = @moon_binpack.AtlasPacker::new(options=opts)
  let items = [
    @moon_binpack.Size::new(50, 50),
    @moon_binpack.Size::new(50, 50),
    @moon_binpack.Size::new(50, 50),
  ]

  let res = packer.pack(items)
  assert_eq(res.unpacked.length(), 0)
  assert_eq(res.rects.length(), 3)
  assert_eq(res.pages.length(), 3)

  // Each rect should be on its own page
  assert_eq(res.rects[0].bin_index, 0)
  assert_eq(res.rects[1].bin_index, 1)
  assert_eq(res.rects[2].bin_index, 2)
}

test "atlas_packer_skyline" {
  let opts = @moon_binpack.AtlasOptions::{
    max_width: 512,
    max_height: 512,
    padding: 2,
    border_padding: 2,
    allow_rotation: true,
    auto_grow_pot: true,
    heuristic: @moon_binpack.MaxRectsHeuristic::BestShortSideFit,
  }

  let packer = @moon_binpack.AtlasPacker::new(options=opts)
  let items = [
    @moon_binpack.Size::new(60, 40),
    @moon_binpack.Size::new(40, 80),
    @moon_binpack.Size::new(50, 50),
    @moon_binpack.Size::new(70, 30),
    @moon_binpack.Size::new(30, 30),
  ]

  let res = packer.pack_skyline(items, heuristic=@moon_binpack.SkylineHeuristic::MinWasteFit)
  assert_eq(res.unpacked.length(), 0)
  assert_eq(res.rects.length(), 5)
  assert_eq(res.pages.length(), 1)

  for i = 0; i < res.rects.length(); i = i + 1 {
    for j = i + 1; j < res.rects.length(); j = j + 1 {
      assert_false(res.rects[i].intersects(res.rects[j]))
    }
  }
}

test "best_pack_arena" {
  let items = [
    @moon_binpack.Size::new(100, 60),
    @moon_binpack.Size::new(80, 80),
    @moon_binpack.Size::new(50, 90),
    @moon_binpack.Size::new(40, 40),
    @moon_binpack.Size::new(70, 50),
    @moon_binpack.Size::new(60, 30),
    @moon_binpack.Size::new(30, 70),
    @moon_binpack.Size::new(45, 45),
  ]

  let (res, algo_name) = @moon_binpack.best_pack(items, max_width=512, max_height=512)
  assert_eq(res.unpacked.length(), 0)
  assert_eq(res.rects.length(), items.length())
  assert_true(algo_name.length() > 0)
  assert_true(res.stats.occupancy > 0.0)

  // Verify no overlap in best packing layout
  for i = 0; i < res.rects.length(); i = i + 1 {
    for j = i + 1; j < res.rects.length(); j = j + 1 {
      if res.rects[i].bin_index == res.rects[j].bin_index {
        assert_false(res.rects[i].intersects(res.rects[j]))
      }
    }
  }
}

test "best_pack_empty" {
  let empty_items : Array[@moon_binpack.Size] = []
  let (res, algo_name) = @moon_binpack.best_pack(empty_items)
  assert_eq(res.rects.length(), 0)
  assert_eq(algo_name, "None")
}

