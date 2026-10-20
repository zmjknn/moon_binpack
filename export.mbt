///|
/// Color palette for SVG rectangle rendering.
let svg_palette : Array[String] = [
  "#4F46E5", "#06B6D4", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899",
  "#3B82F6", "#14B8A6", "#84CC16", "#F97316", "#6366F1", "#0EA5E9", "#D946EF",
]

///|
/// Exports a packed rectangle layout to a self-contained, responsive SVG image.
pub fn to_svg(
  bin_width : Int,
  bin_height : Int,
  rects : Array[Rect],
  title~ : String = "moon_binpack Texture Atlas"
) -> String {
  let mut total_used_area = 0
  for r in rects {
    total_used_area = total_used_area + r.area()
  }
  let total_area = bin_width * bin_height
  let occupancy_pct = if total_area > 0 {
    (total_used_area.to_double() * 1000.0 / total_area.to_double()).to_int().to_double() / 10.0
  } else {
    0.0
  }

  let buf = StringBuilder()
  buf.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" ")
  buf.write_string("viewBox=\"0 0 ")
  buf.write_string(bin_width.to_string())
  buf.write_string(" ")
  buf.write_string((bin_height + 40).to_string())
  buf.write_string("\" width=\"")
  buf.write_string(bin_width.to_string())
  buf.write_string("\" height=\"")
  buf.write_string((bin_height + 40).to_string())
  buf.write_string("\">\n")

  // Background and style
  buf.write_string("  <style>\n")
  buf.write_string("    .bg { fill: #0f172a; }\n")
  buf.write_string("    .bin-border { fill: #1e293b; stroke: #475569; stroke-width: 2; }\n")
  buf.write_string("    .header { font-family: monospace; font-size: 14px; fill: #f8fafc; font-weight: bold; }\n")
  buf.write_string("    .badge { font-family: monospace; font-size: 12px; fill: #38bdf8; }\n")
  buf.write_string("    .item-label { font-family: monospace; font-size: 10px; fill: #ffffff; text-anchor: middle; dominant-baseline: middle; }\n")
  buf.write_string("  </style>\n")

  // Canvas background
  buf.write_string("  <rect width=\"100%\" height=\"100%\" class=\"bg\" />\n")

  // Header info
  buf.write_string("  <text x=\"10\" y=\"25\" class=\"header\">")
  buf.write_string(title)
  buf.write_string("</text>\n")
  buf.write_string("  <text x=\"")
  buf.write_string((bin_width - 10).to_string())
  buf.write_string("\" y=\"25\" class=\"badge\" text-anchor=\"end\">Occupancy: ")
  buf.write_string(occupancy_pct.to_string())
  buf.write_string("% | ")
  buf.write_string(rects.length().to_string())
  buf.write_string(" items</text>\n")

  // Bin outline
  buf.write_string("  <g transform=\"translate(0, 40)\">\n")
  buf.write_string("    <rect x=\"0\" y=\"0\" width=\"")
  buf.write_string(bin_width.to_string())
  buf.write_string("\" height=\"")
  buf.write_string(bin_height.to_string())
  buf.write_string("\" class=\"bin-border\" />\n")

  // Packed rectangles
  for i = 0; i < rects.length(); i = i + 1 {
    let r = rects[i]
    let color_idx = (r.id + i) % svg_palette.length()
    let color = svg_palette[color_idx]

    buf.write_string("    <g>\n")
    buf.write_string("      <rect x=\"")
    buf.write_string(r.x.to_string())
    buf.write_string("\" y=\"")
    buf.write_string(r.y.to_string())
    buf.write_string("\" width=\"")
    buf.write_string(r.width.to_string())
    buf.write_string("\" height=\"")
    buf.write_string(r.height.to_string())
    buf.write_string("\" fill=\"")
    buf.write_string(color)
    buf.write_string("\" stroke=\"#ffffff\" stroke-width=\"1\" opacity=\"0.9\" rx=\"2\" />\n")

    // Label if large enough
    if r.width >= 24 && r.height >= 16 {
      let cx = r.x + r.width / 2
      let cy = r.y + r.height / 2
      buf.write_string("      <text x=\"")
      buf.write_string(cx.to_string())
      buf.write_string("\" y=\"")
      buf.write_string(cy.to_string())
      buf.write_string("\" class=\"item-label\">#")
      buf.write_string(r.id.to_string())
      buf.write_string("</text>\n")
    }

    buf.write_string("    </g>\n")
  }

  buf.write_string("  </g>\n")
  buf.write_string("</svg>\n")

  buf.to_string()
}

///|
/// Exports packed rectangles into a standard JSON texture atlas manifest format.
pub fn to_json(bin_width : Int, bin_height : Int, rects : Array[Rect]) -> String {
  let buf = StringBuilder()
  buf.write_string("{\n")
  buf.write_string("  \"meta\": {\n")
  buf.write_string("    \"width\": ")
  buf.write_string(bin_width.to_string())
  buf.write_string(",\n")
  buf.write_string("    \"height\": ")
  buf.write_string(bin_height.to_string())
  buf.write_string(",\n")
  buf.write_string("    \"count\": ")
  buf.write_string(rects.length().to_string())
  buf.write_string("\n  },\n")
  buf.write_string("  \"frames\": [\n")

  for i = 0; i < rects.length(); i = i + 1 {
    let r = rects[i]
    buf.write_string("    {\n")
    buf.write_string("      \"id\": ")
    buf.write_string(r.id.to_string())
    buf.write_string(",\n")
    buf.write_string("      \"x\": ")
    buf.write_string(r.x.to_string())
    buf.write_string(",\n")
    buf.write_string("      \"y\": ")
    buf.write_string(r.y.to_string())
    buf.write_string(",\n")
    buf.write_string("      \"width\": ")
    buf.write_string(r.width.to_string())
    buf.write_string(",\n")
    buf.write_string("      \"height\": ")
    buf.write_string(r.height.to_string())
    buf.write_string(",\n")
    buf.write_string("      \"rotated\": ")
    buf.write_string(if r.rotated { "true" } else { "false" })
    buf.write_string(",\n")
    buf.write_string("      \"bin\": ")
    buf.write_string(r.bin_index.to_string())
    buf.write_string("\n    }")
    if i + 1 < rects.length() {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }

  buf.write_string("  ]\n")
  buf.write_string("}\n")

  buf.to_string()
}
