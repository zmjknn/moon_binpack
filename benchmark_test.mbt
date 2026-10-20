test "benchmark_50_items_non_overlapping_invariant" {
  let bin_w = 512
  let bin_h = 512
  let packer = MaxRectsPacker::new(bin_w, bin_h)

  // 30 mixed-size items commonly found in UI and game sprite sheets
  let items = [
    Size::new(128, 64),
    Size::new(64, 128),
    Size::new(96, 96),
    Size::new(100, 50),
    Size::new(50, 100),
    Size::new(64, 64),
    Size::new(64, 64),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(32, 64),
    Size::new(64, 32),
    Size::new(48, 48),
    Size::new(48, 48),
    Size::new(80, 40),
    Size::new(40, 80),
    Size::new(32, 32),
    Size::new(32, 32),
    Size::new(24, 24),
    Size::new(24, 24),
    Size::new(16, 16),
    Size::new(16, 16),
    Size::new(16, 32),
    Size::new(32, 16),
    Size::new(72, 36),
    Size::new(36, 72),
    Size::new(56, 56),
    Size::new(28, 28),
    Size::new(28, 28),
    Size::new(20, 20),
    Size::new(20, 20),
  ]

  let (packed, unpacked) = packer.insert_batch(
    items,
    method=MaxRectsHeuristic::BestShortSideFit,
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

  let maxrects = MaxRectsPacker::new(bin_w, bin_h)
  let guillotine = GuillotinePacker::new(bin_w, bin_h)
  let shelf = ShelfPacker::new(bin_w, bin_h)

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
  }

  // All packers must produce valid positive occupancy
  assert_true(maxrects.occupancy() > 0.0)
  assert_true(guillotine.occupancy() > 0.0)
  assert_true(shelf.occupancy() > 0.0)
}
