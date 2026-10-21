test "benchmark_50_items_non_overlapping_invariant" {
  let bin_w = 512
  let bin_h = 512
  let packer = @moon_binpack.MaxRectsPacker::new(bin_w, bin_h)

  // 30 mixed-size items commonly found in UI and game sprite sheets
  let items = [
    @moon_binpack.Size::new(128, 64),
    @moon_binpack.Size::new(64, 128),
    @moon_binpack.Size::new(96, 96),
    @moon_binpack.Size::new(100, 50),
    @moon_binpack.Size::new(50, 100),
    @moon_binpack.Size::new(64, 64),
    @moon_binpack.Size::new(64, 64),
    @moon_binpack.Size::new(32, 32),
    @moon_binpack.Size::new(32, 32),
    @moon_binpack.Size::new(32, 64),
    @moon_binpack.Size::new(64, 32),
    @moon_binpack.Size::new(48, 48),
    @moon_binpack.Size::new(48, 48),
    @moon_binpack.Size::new(80, 40),
    @moon_binpack.Size::new(40, 80),
    @moon_binpack.Size::new(32, 32),
    @moon_binpack.Size::new(32, 32),
    @moon_binpack.Size::new(24, 24),
    @moon_binpack.Size::new(24, 24),
    @moon_binpack.Size::new(16, 16),
    @moon_binpack.Size::new(16, 16),
    @moon_binpack.Size::new(16, 32),
    @moon_binpack.Size::new(32, 16),
    @moon_binpack.Size::new(72, 36),
    @moon_binpack.Size::new(36, 72),
    @moon_binpack.Size::new(56, 56),
    @moon_binpack.Size::new(28, 28),
    @moon_binpack.Size::new(28, 28),
    @moon_binpack.Size::new(20, 20),
    @moon_binpack.Size::new(20, 20),
  ]

  let (packed, unpacked) = packer.insert_batch(
    items,
    heuristic=@moon_binpack.MaxRectsHeuristic::BestShortSideFit,
    allow_rotation=true,
  )

  // Verify all 30 items are packed without any overflow
  assert_eq(unpacked.length(), 0)
  assert_eq(packed.length(), 30)

  // Strict non-overlapping invariant: NO two rectangles may intersect
  for i = 0; i < packed.length(); i = i + 1 {
    let r1 = packed[i]
    // Within bin boundary
    assert_true(r1.x >= 0)
    assert_true(r1.y >= 0)
    assert_true(r1.right() <= bin_w)
    assert_true(r1.bottom() <= bin_h)

    for j = i + 1; j < packed.length(); j = j + 1 {
      let r2 = packed[j]
      assert_false(r1.intersects(r2))
    }
  }

  // Occupancy should be healthy
  assert_true(packer.occupancy() > 0.25)
}

test "algorithm_comparison_benchmark" {
  let bin_w = 300
  let bin_h = 300

  let maxrects = @moon_binpack.MaxRectsPacker::new(bin_w, bin_h)
  let guillotine = @moon_binpack.GuillotinePacker::new(bin_w, bin_h)
  let shelf = @moon_binpack.ShelfPacker::new(bin_w, bin_h)
  let skyline = @moon_binpack.SkylinePacker::new(bin_w, bin_h)

  let sizes = [
    (60, 40),
    (50, 50),
    (40, 60),
    (70, 30),
    (30, 70),
    (80, 40),
    (40, 40),
    (50, 30),
    (30, 30),
    (45, 45),
  ]

  for s in sizes {
    let (w, h) = s
    let _ = maxrects.insert(w, h)
    let _ = guillotine.insert(w, h)
    let _ = shelf.insert(w, h)
    let _ = skyline.insert(w, h)
  }

  // All packers must produce valid positive occupancy
  assert_true(maxrects.occupancy() > 0.0)
  assert_true(guillotine.occupancy() > 0.0)
  assert_true(shelf.occupancy() > 0.0)
  assert_true(skyline.occupancy() > 0.0)
}

test "best_pack_multi_item_benchmark" {
  let items = [
    @moon_binpack.Size::new(128, 64),
    @moon_binpack.Size::new(64, 128),
    @moon_binpack.Size::new(96, 96),
    @moon_binpack.Size::new(80, 48),
    @moon_binpack.Size::new(48, 80),
    @moon_binpack.Size::new(64, 64),
    @moon_binpack.Size::new(48, 48),
    @moon_binpack.Size::new(32, 32),
    @moon_binpack.Size::new(32, 32),
    @moon_binpack.Size::new(32, 64),
    @moon_binpack.Size::new(64, 32),
    @moon_binpack.Size::new(40, 40),
    @moon_binpack.Size::new(24, 24),
    @moon_binpack.Size::new(24, 24),
    @moon_binpack.Size::new(16, 16),
  ]

  let (res, winning_algo) = @moon_binpack.best_pack(items, max_width=512, max_height=512)
  assert_eq(res.unpacked.length(), 0)
  assert_eq(res.rects.length(), items.length())
  assert_true(winning_algo.length() > 0)
  assert_true(res.stats.occupancy > 0.0)

  // Verify non-overlapping
  for i = 0; i < res.rects.length(); i = i + 1 {
    for j = i + 1; j < res.rects.length(); j = j + 1 {
      if res.rects[i].bin_index == res.rects[j].bin_index {
        assert_false(res.rects[i].intersects(res.rects[j]))
      }
    }
  }
}

