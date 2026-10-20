test "guillotine_basic_insertion" {
  let packer = @moon_binpack.GuillotinePacker::new(100, 100)

  let r1 = packer.insert(40, 40, id=1)
  assert_true(r1 != None)
  match r1 {
    Some(r) => {
      assert_eq(r.x, 0)
      assert_eq(r.y, 0)
      assert_eq(r.width, 40)
      assert_eq(r.height, 40)
    }
    None => panic()
  }

  let r2 = packer.insert(60, 40, id=2)
  assert_true(r2 != None)

  let r3 = packer.insert(100, 60, id=3)
  assert_true(r3 != None)

  match (r1, r2, r3) {
    (Some(a), Some(b), Some(c)) => {
      assert_false(a.intersects(b))
      assert_false(a.intersects(c))
      assert_false(b.intersects(c))
    }
    _ => panic()
  }

  // 40*40 + 60*40 + 100*60 = 1600 + 2400 + 6000 = 10000 (100% full!)
  assert_eq(packer.occupancy(), 1.0)
}

test "guillotine_heuristics_and_rotation" {
  let packer = @moon_binpack.GuillotinePacker::new(100, 100)

  // A 80x20 item can fit normally or rotated
  let r = packer.insert(
    20,
    80,
    id=1,
    rect_choice=@moon_binpack.GuillotineHeuristic::BestShortSideFit,
    split_method=@moon_binpack.SplitHeuristic::ShorterLeftoverAxis,
  )
  assert_true(r != None)

  let r2 = packer.insert(
    50,
    50,
    id=2,
    rect_choice=@moon_binpack.GuillotineHeuristic::BestAreaFit,
    split_method=@moon_binpack.SplitHeuristic::LongerAxis,
  )
  assert_true(r2 != None)

  match (r, r2) {
    (Some(a), Some(b)) => assert_false(a.intersects(b))
    _ => panic()
  }
}
