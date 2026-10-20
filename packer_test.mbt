test "atlas_packer_auto_grow" {
  let opts = AtlasOptions::{
    max_width: 1024,
    max_height: 1024,
    padding: 2,
    border_padding: 2,
    allow_rotation: true,
    auto_grow_pot: true,
    heuristic: MaxRectsHeuristic::BestShortSideFit,
  }

  let packer = AtlasPacker::new(options=opts)
  let items = [
    Size::new(40, 40),
    Size::new(50, 30),
    Size::new(20, 20),
    Size::new(30, 40),
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
  let opts = AtlasOptions::{
    max_width: 60,
    max_height: 60,
    padding: 0,
    border_padding: 0,
    allow_rotation: false,
    auto_grow_pot: false,
    heuristic: MaxRectsHeuristic::BestShortSideFit,
  }

  let packer = AtlasPacker::new(options=opts)
  let items = [
    Size::new(50, 50),
    Size::new(50, 50),
    Size::new(50, 50),
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
