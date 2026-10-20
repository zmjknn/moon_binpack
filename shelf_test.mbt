test "shelf_packer_basic" {
  let packer = ShelfPacker::new(100, 100)

  let r1 = packer.insert(50, 30, id=1, method=ShelfHeuristic::NextFit)
  match r1 {
    Some(r) => {
      assert_eq(r.x, 0)
      assert_eq(r.y, 0)
      assert_eq(r.width, 50)
      assert_eq(r.height, 30)
      assert_eq(r.id, 1)
    }
    None => panic()
  }

  // Second fits on the same shelf
  let r2 = packer.insert(40, 20, id=2, method=ShelfHeuristic::NextFit)
  match r2 {
    Some(r) => {
      assert_eq(r.x, 50)
      assert_eq(r.y, 0)
      assert_eq(r.width, 40)
      assert_eq(r.height, 20)
    }
    None => panic()
  }

  // Third does not fit horizontally (50 + 40 + 20 = 110 > 100), starts new shelf at y = 30
  let r3 = packer.insert(20, 40, id=3, method=ShelfHeuristic::NextFit)
  match r3 {
    Some(r) => {
      assert_eq(r.x, 0)
      assert_eq(r.y, 30)
      assert_eq(r.width, 20)
      assert_eq(r.height, 40)
    }
    None => panic()
  }

  // Non-overlapping check between all placed rectangles
  match (r1, r2, r3) {
    (Some(a), Some(b), Some(c)) => {
      assert_false(a.intersects(b))
      assert_false(a.intersects(c))
      assert_false(b.intersects(c))
    }
    _ => panic()
  }

  assert_true(packer.occupancy() > 0.0)
}

test "shelf_packer_overflow" {
  let packer = ShelfPacker::new(50, 50)
  let r1 = packer.insert(40, 40, id=1)
  assert_true(r1 != None)

  // Needs height 20, but remaining height is 50 - 40 = 10 -> None
  let r2 = packer.insert(40, 20, id=2)
  assert_eq(r2, None)
}

test "shelf_packer_heuristics" {
  let p_first = ShelfPacker::new(100, 100)
  let p_best = ShelfPacker::new(100, 100)
  let p_worst = ShelfPacker::new(100, 100)
  let p_height = ShelfPacker::new(100, 100)

  let sizes = [(30, 20), (20, 20), (40, 20), (50, 30), (30, 10)]

  for s in sizes {
    let (w, h) = s
    let _ = p_first.insert(w, h, method=ShelfHeuristic::FirstFit)
    let _ = p_best.insert(w, h, method=ShelfHeuristic::BestAreaFit)
    let _ = p_worst.insert(w, h, method=ShelfHeuristic::WorstAreaFit)
    let _ = p_height.insert(w, h, method=ShelfHeuristic::BestHeightFit)
  }

  assert_true(p_first.occupancy() > 0.0)
  assert_true(p_best.occupancy() > 0.0)
  assert_true(p_worst.occupancy() > 0.0)
  assert_true(p_height.occupancy() > 0.0)
}
