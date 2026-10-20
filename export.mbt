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

///|
/// Exports packed rectangles into standard CSS Sprite rules.
/// Generates a common base class and individual utility classes with width, height,
/// and negative background-position offsets.
pub fn to_css(
  rects : Array[Rect],
  class_prefix~ : String = "sprite",
  image_url~ : String = "atlas.png"
) -> String {
  let buf = StringBuilder()
  buf.write_string("/* Generated by moon_binpack CSS Sprite Exporter */\n")
  buf.write_string(".")
  buf.write_string(class_prefix)
  buf.write_string(" {\n")
  buf.write_string("  display: inline-block;\n")
  buf.write_string("  background-image: url('")
  buf.write_string(image_url)
  buf.write_string("');\n")
  buf.write_string("  background-repeat: no-repeat;\n")
  buf.write_string("}\n\n")

  for i = 0; i < rects.length(); i = i + 1 {
    let r = rects[i]
    buf.write_string(".")
    buf.write_string(class_prefix)
    buf.write_string("-")
    buf.write_string(r.id.to_string())
    buf.write_string(" {\n")
    buf.write_string("  width: ")
    buf.write_string(r.width.to_string())
    buf.write_string("px;\n")
    buf.write_string("  height: ")
    buf.write_string(r.height.to_string())
    buf.write_string("px;\n")
    buf.write_string("  background-position: -")
    buf.write_string(r.x.to_string())
    buf.write_string("px -")
    buf.write_string(r.y.to_string())
    buf.write_string("px;\n")
    buf.write_string("}\n")
    if i + 1 < rects.length() {
      buf.write_string("\n")
    }
  }

  buf.to_string()
}

///|
/// Exports packed rectangles into a standalone, interactive HTML visual inspection report.
pub fn to_html(
  bin_width : Int,
  bin_height : Int,
  rects : Array[Rect],
  title~ : String = "moon_binpack Texture Atlas Report"
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

  let svg_content = to_svg(bin_width, bin_height, rects, title~)

  let buf = StringBuilder()
  buf.write_string("<!DOCTYPE html>\n")
  buf.write_string("<html lang=\"en\">\n<head>\n")
  buf.write_string("  <meta charset=\"UTF-8\">\n")
  buf.write_string("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n")
  buf.write_string("  <title>")
  buf.write_string(title)
  buf.write_string("</title>\n")
  buf.write_string("  <style>\n")
  buf.write_string("    :root {\n")
  buf.write_string("      --bg: #0b0f19;\n")
  buf.write_string("      --card-bg: #111827;\n")
  buf.write_string("      --border: #1f2937;\n")
  buf.write_string("      --text: #f9fafb;\n")
  buf.write_string("      --text-muted: #9ca3af;\n")
  buf.write_string("      --accent: #38bdf8;\n")
  buf.write_string("    }\n")
  buf.write_string("    body {\n")
  buf.write_string("      margin: 0;\n")
  buf.write_string("      padding: 24px;\n")
  buf.write_string("      background-color: var(--bg);\n")
  buf.write_string("      color: var(--text);\n")
  buf.write_string("      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;\n")
  buf.write_string("    }\n")
  buf.write_string("    .container { max-width: 1200px; margin: 0 auto; }\n")
  buf.write_string("    .header { margin-bottom: 24px; }\n")
  buf.write_string("    .header h1 { margin: 0 0 8px 0; font-size: 24px; font-weight: 700; }\n")
  buf.write_string("    .header p { margin: 0; color: var(--text-muted); font-size: 14px; }\n")
  buf.write_string("    .metrics-grid {\n")
  buf.write_string("      display: grid;\n")
  buf.write_string("      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));\n")
  buf.write_string("      gap: 16px;\n")
  buf.write_string("      margin-bottom: 24px;\n")
  buf.write_string("    }\n")
  buf.write_string("    .card {\n")
  buf.write_string("      background: var(--card-bg);\n")
  buf.write_string("      border: 1px solid var(--border);\n")
  buf.write_string("      border-radius: 8px;\n")
  buf.write_string("      padding: 16px;\n")
  buf.write_string("    }\n")
  buf.write_string("    .card .label { font-size: 12px; color: var(--text-muted); text-transform: uppercase; margin-bottom: 4px; }\n")
  buf.write_string("    .card .value { font-size: 20px; font-weight: bold; color: var(--accent); font-family: monospace; }\n")
  buf.write_string("    .preview-card { margin-bottom: 24px; overflow-x: auto; text-align: center; }\n")
  buf.write_string("    .preview-card svg { max-width: 100%; height: auto; border-radius: 4px; }\n")
  buf.write_string("    table { width: 100%; border-collapse: collapse; font-family: monospace; font-size: 13px; }\n")
  buf.write_string("    th, td { padding: 10px 14px; text-align: left; border-bottom: 1px solid var(--border); }\n")
  buf.write_string("    th { background: #1f2937; color: var(--text-muted); font-size: 11px; text-transform: uppercase; }\n")
  buf.write_string("    tr:hover { background-color: rgba(255, 255, 255, 0.03); }\n")
  buf.write_string("    .tag { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 11px; }\n")
  buf.write_string("    .tag-rot { background: #3730a3; color: #a5b4fc; }\n")
  buf.write_string("    .footer { margin-top: 32px; text-align: center; font-size: 12px; color: var(--text-muted); }\n")
  buf.write_string("  </style>\n</head>\n<body>\n")
  buf.write_string("  <div class=\"container\">\n")
  buf.write_string("    <div class=\"header\">\n")
  buf.write_string("      <h1>")
  buf.write_string(title)
  buf.write_string("</h1>\n")
  buf.write_string("      <p>Interactive Texture Atlas Inspection Report generated by moon_binpack</p>\n")
  buf.write_string("    </div>\n\n")

  // Metrics cards
  buf.write_string("    <div class=\"metrics-grid\">\n")
  buf.write_string("      <div class=\"card\"><div class=\"label\">Atlas Dimensions</div><div class=\"value\">")
  buf.write_string(bin_width.to_string())
  buf.write_string(" × ")
  buf.write_string(bin_height.to_string())
  buf.write_string(" px</div></div>\n")

  buf.write_string("      <div class=\"card\"><div class=\"label\">Occupancy Rate</div><div class=\"value\">")
  buf.write_string(occupancy_pct.to_string())
  buf.write_string("%</div></div>\n")

  buf.write_string("      <div class=\"card\"><div class=\"label\">Packed Items</div><div class=\"value\">")
  buf.write_string(rects.length().to_string())
  buf.write_string("</div></div>\n")

  buf.write_string("      <div class=\"card\"><div class=\"label\">Used Surface Area</div><div class=\"value\">")
  buf.write_string(total_used_area.to_string())
  buf.write_string(" px²</div></div>\n")
  buf.write_string("    </div>\n\n")

  // SVG Preview
  buf.write_string("    <div class=\"card preview-card\">\n")
  buf.write_string(svg_content)
  buf.write_string("\n    </div>\n\n")

  // Details Table
  buf.write_string("    <div class=\"card\">\n")
  buf.write_string("      <div class=\"label\" style=\"margin-bottom: 12px;\">Frame Details</div>\n")
  buf.write_string("      <table>\n")
  buf.write_string("        <thead>\n")
  buf.write_string("          <tr>\n")
  buf.write_string("            <th>#</th><th>ID</th><th>X</th><th>Y</th><th>Width</th><th>Height</th><th>Rotated</th><th>Bin</th>\n")
  buf.write_string("          </tr>\n")
  buf.write_string("        </thead>\n")
  buf.write_string("        <tbody>\n")

  for i = 0; i < rects.length(); i = i + 1 {
    let r = rects[i]
    buf.write_string("          <tr>\n")
    buf.write_string("            <td>")
    buf.write_string((i + 1).to_string())
    buf.write_string("</td>\n")
    buf.write_string("            <td><strong>#")
    buf.write_string(r.id.to_string())
    buf.write_string("</strong></td>\n")
    buf.write_string("            <td>")
    buf.write_string(r.x.to_string())
    buf.write_string("</td>\n")
    buf.write_string("            <td>")
    buf.write_string(r.y.to_string())
    buf.write_string("</td>\n")
    buf.write_string("            <td>")
    buf.write_string(r.width.to_string())
    buf.write_string("</td>\n")
    buf.write_string("            <td>")
    buf.write_string(r.height.to_string())
    buf.write_string("</td>\n")
    buf.write_string("            <td>")
    if r.rotated {
      buf.write_string("<span class=\"tag tag-rot\">Yes</span>")
    } else {
      buf.write_string("No")
    }
    buf.write_string("</td>\n")
    buf.write_string("            <td>")
    buf.write_string(r.bin_index.to_string())
    buf.write_string("</td>\n")
    buf.write_string("          </tr>\n")
  }

  buf.write_string("        </tbody>\n")
  buf.write_string("      </table>\n")
  buf.write_string("    </div>\n\n")

  buf.write_string("    <div class=\"footer\">\n")
  buf.write_string("      Powered by <strong>moon_binpack</strong> — High-Performance 2D Bin Packing Engine in Pure MoonBit\n")
  buf.write_string("    </div>\n")
  buf.write_string("  </div>\n</body>\n</html>\n")

  buf.to_string()
}

