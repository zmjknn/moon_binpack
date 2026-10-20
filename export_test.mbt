test "export_svg_and_json" {
  let rects = [
    Rect::new(0, 0, 50, 40, id=1),
    Rect::new(50, 0, 50, 40, id=2),
    Rect::new(0, 40, 100, 60, id=3),
  ]

  let svg = to_svg(100, 100, rects, title="Test Atlas")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("Test Atlas"))
  assert_true(svg.contains("100%"))
  assert_true(svg.contains("</svg>"))

  let json = to_json(100, 100, rects)
  assert_true(json.contains("\"width\": 100"))
  assert_true(json.contains("\"frames\":"))
  assert_true(json.contains("\"id\": 1"))
}
