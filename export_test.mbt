test "export_svg_and_json" {
  let rects = [
    @moon_binpack.Rect::new(0, 0, 50, 40, id=1),
    @moon_binpack.Rect::new(50, 0, 50, 40, id=2),
    @moon_binpack.Rect::new(0, 40, 100, 60, id=3),
  ]

  let svg = @moon_binpack.to_svg(100, 100, rects, title="Test Atlas")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("Test Atlas"))
  assert_true(svg.contains("100%"))
  assert_true(svg.contains("</svg>"))

  let json = @moon_binpack.to_json(100, 100, rects)
  assert_true(json.contains("\"width\": 100"))
  assert_true(json.contains("\"frames\":"))
  assert_true(json.contains("\"id\": 1"))
}

test "export_css_spritesheet" {
  let rects = [
    @moon_binpack.Rect::new(0, 0, 32, 32, id=10),
    @moon_binpack.Rect::new(32, 0, 48, 64, id=11),
  ]

  let css = @moon_binpack.to_css(rects, class_prefix="icon", image_url="sprites.png")
  assert_true(css.contains(".icon {"))
  assert_true(css.contains("background-image: url('sprites.png');"))
  assert_true(css.contains(".icon-10 {"))
  assert_true(css.contains("width: 32px;"))
  assert_true(css.contains("height: 32px;"))
  assert_true(css.contains("background-position: -0px -0px;"))
  assert_true(css.contains(".icon-11 {"))
  assert_true(css.contains("width: 48px;"))
  assert_true(css.contains("height: 64px;"))
  assert_true(css.contains("background-position: -32px -0px;"))
}

test "export_html_report" {
  let rects = [
    @moon_binpack.Rect::new(0, 0, 100, 100, id=1, rotated=true),
    @moon_binpack.Rect::new(100, 0, 50, 50, id=2),
  ]

  let html = @moon_binpack.to_html(200, 200, rects, title="Unit Test Atlas")
  assert_true(html.contains("<!DOCTYPE html>"))
  assert_true(html.contains("<title>Unit Test Atlas</title>"))
  assert_true(html.contains("Atlas Dimensions"))
  assert_true(html.contains("200 × 200 px"))
  assert_true(html.contains("Occupancy Rate"))
  assert_true(html.contains("<svg"))
  assert_true(html.contains("Frame Details"))
  assert_true(html.contains("<strong>#1</strong>"))
  assert_true(html.contains("<span class=\"tag tag-rot\">Yes</span>"))
  assert_true(html.contains("</html>"))
}

