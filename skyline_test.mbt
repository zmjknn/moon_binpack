test "skyline_basic_insertion" {
  let packer = @moon_binpack.SkylinePacker::new(100, 100)

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

test "skyline_rotation_support" {
  // Bin is 100x50. A 20x90 item won't fit unless rotated to 90x20
  let packer = @moon_binpack.SkylinePacker::new(100, 50)
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
  let packer2 = @moon_binpack.SkylinePacker::new(100, 50)
  let r_fail = packer2.insert(20, 90, id=2, allow_rotation=false)
  assert_eq(r_fail, None)
}

test "skyline_heuristics_comparison" {
  let items = [
    @moon_binpack.Size::new(40, 30),
    @moon_binpack.Size::new(30, 40),
    @moon_binpack.Size::new(50, 20),
    @moon_binpack.Size::new(20, 50),
    @moon_binpack.Size::new(35, 35),
    @moon_binpack.Size::new(25, 25),
  ]

  let p_bl = @moon_binpack.SkylinePacker::new(100, 100)
  let (packed_bl, unpacked_bl) = p_bl.insert_batch(
    items,
    heuristic=@moon_binpack.SkylineHeuristic::BottomLeft,
  )
  assert_eq(unpacked_bl.length(), 0)
  assert_eq(packed_bl.length(), 6)

  // Verify non-overlapping invariant for BottomLeft
  for i = 0; i < packed_bl.length(); i = i + 1 {
    let r1 = packed_bl[i]
    assert_true(r1.x >= 0 && r1.y >= 0 && r1.right() <= 100 && r1.bottom() <= 100)
    for j = i + 1; j < packed_bl.length(); j = j + 1 {
      assert_false(r1.intersects(packed_bl[j]))
    }
  }

  let p_mw = @moon_binpack.SkylinePacker::new(100, 100)
  let (packed_mw, unpacked_mw) = p_mw.insert_batch(
    items,
    heuristic=@moon_binpack.SkylineHeuristic::MinWasteFit,
  )
  assert_eq(unpacked_mw.length(), 0)
  assert_eq(packed_mw.length(), 6)

  // Verify non-overlapping invariant for MinWasteFit
  for i = 0; i < packed_mw.length(); i = i + 1 {
    let r1 = packed_mw[i]
    assert_true(r1.x >= 0 && r1.y >= 0 && r1.right() <= 100 && r1.bottom() <= 100)
    for j = i + 1; j < packed_mw.length(); j = j + 1 {
      assert_false(r1.intersects(packed_mw[j]))
    }
  }
}

test "skyline_node_types" {
  let node = @moon_binpack.SkylineNode::new(10, 20, 30)
  assert_eq(node.x, 10)
  assert_eq(node.y, 20)
  assert_eq(node.width, 30)
}
