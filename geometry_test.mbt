test "rect_area_and_boundaries" {
  let r = @moon_binpack.Rect::new(10, 20, 30, 40)
  assert_eq(r.x, 10)
  assert_eq(r.y, 20)
  assert_eq(r.width, 30)
  assert_eq(r.height, 40)
  assert_eq(r.right(), 40)
  assert_eq(r.bottom(), 60)
  assert_eq(r.area(), 1200)
  assert_eq(r.perimeter(), 140)
}

test "rect_containment" {
  let outer = @moon_binpack.Rect::new(0, 0, 100, 100)
  let inner = @moon_binpack.Rect::new(10, 10, 50, 50)
  let overlap = @moon_binpack.Rect::new(50, 50, 100, 100)
  let outside = @moon_binpack.Rect::new(200, 200, 10, 10)

  assert_true(outer.contains(inner))
  assert_false(inner.contains(outer))
  assert_false(outer.contains(overlap))
  assert_false(outer.contains(outside))
}

test "rect_intersection" {
  let r1 = @moon_binpack.Rect::new(0, 0, 20, 20)
  let r2 = @moon_binpack.Rect::new(10, 10, 20, 20)
  let r3 = @moon_binpack.Rect::new(30, 30, 10, 10)

  assert_true(r1.intersects(r2))
  assert_true(r2.intersects(r1))
  assert_false(r1.intersects(r3))

  let inter = r1.intersection(r2)
  match inter {
    Some(rect) => {
      assert_eq(rect.x, 10)
      assert_eq(rect.y, 10)
      assert_eq(rect.width, 10)
      assert_eq(rect.height, 10)
      assert_eq(rect.area(), 100)
    }
    None => panic()
  }

  assert_eq(r1.intersection(r3), None)
}

test "size_and_bin" {
  let s = @moon_binpack.Size::new(64, 128)
  assert_eq(s.area(), 8192)

  let b = @moon_binpack.Bin::new(1024, 768)
  assert_eq(b.area(), 786432)
}
