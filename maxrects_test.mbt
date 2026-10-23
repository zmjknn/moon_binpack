///|
test "maxrects_basic_packing" {
  let packer = @moon_binpack.MaxRectsPacker::new(100, 100)

  let r1 = packer.insert(50, 50, id=1)
  let r2 = packer.insert(50, 50, id=2)
  let r3 = packer.insert(50, 50, id=3)
  let r4 = packer.insert(50, 50, id=4)

  assert_true(r1 != None)
  assert_true(r2 != None)
  assert_true(r3 != None)
  assert_true(r4 != None)

  let rects = [r1, r2, r3, r4]
  for i = 0; i < rects.length(); i = i + 1 {
    for j = i + 1; j < rects.length(); j = j + 1 {
      match (rects[i], rects[j]) {
        (Some(a), Some(b)) => assert_false(a.intersects(b))
        _ => panic()
      }
    }
  }

  // 4 * (50 * 50) = 10000 -> 100% full occupancy
  assert_eq(packer.occupancy(), 1.0)
}

///|
test "maxrects_rotation" {
  // Bin is 100x50. A 20x90 item won't fit unless rotated to 90x20
  let packer = @moon_binpack.MaxRectsPacker::new(100, 50)
  let r = packer.insert(20, 90, id=1, allow_rotation=true)
  assert_true(r != None)
  match r {
    Some(rect) => {
      assert_true(rect.rotated)
      assert_eq(rect.width, 90)
      assert_eq(rect.height, 20)
    }
    None => panic()
  }

  // Without rotation, 20x90 does not fit into 100x50
  let packer2 = @moon_binpack.MaxRectsPacker::new(100, 50)
  let r_fail = packer2.insert(20, 90, id=2, allow_rotation=false)
  assert_eq(r_fail, None)
}

///|
test "maxrects_heuristics" {
  let heuristics = [
    @moon_binpack.MaxRectsHeuristic::BestShortSideFit,
    @moon_binpack.MaxRectsHeuristic::BestLongSideFit,
    @moon_binpack.MaxRectsHeuristic::BestAreaFit,
    @moon_binpack.MaxRectsHeuristic::BottomLeftRule,
    @moon_binpack.MaxRectsHeuristic::ContactPointRule,
  ]

  let items = [
    @moon_binpack.Size::new(30, 20),
    @moon_binpack.Size::new(25, 40),
    @moon_binpack.Size::new(50, 20),
    @moon_binpack.Size::new(15, 15),
    @moon_binpack.Size::new(35, 30),
  ]

  for h in heuristics {
    let packer = @moon_binpack.MaxRectsPacker::new(100, 100)
    let (packed, unpacked) = packer.insert_batch(items, heuristic=h)
    assert_eq(unpacked.length(), 0)
    assert_eq(packed.length(), 5)

    // Check all non-overlapping
    for i = 0; i < packed.length(); i = i + 1 {
      for j = i + 1; j < packed.length(); j = j + 1 {
        assert_false(packed[i].intersects(packed[j]))
      }
    }
  }
}
