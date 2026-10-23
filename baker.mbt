///|
/// A 32-bit RGBA color representation (8 bits per channel).
pub(all) struct Rgba {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
} derive(Eq, Debug, Default)

///|
pub fn Rgba::new(r : Byte, g : Byte, b : Byte, a~ : Byte = b'\xFF') -> Rgba {
  { r, g, b, a, }
}

///|
pub fn Rgba::transparent() -> Rgba {
  { r: b'\x00', g: b'\x00', b: b'\x00', a: b'\x00', }
}

///|
pub fn Rgba::from_hex(hex : Int32) -> Rgba {
  let r = ((hex >> 16) & 0xFF).to_byte()
  let g = ((hex >> 8) & 0xFF).to_byte()
  let b = (hex & 0xFF).to_byte()
  let a = if hex >> 24 != 0 { ((hex >> 24) & 0xFF).to_byte() } else { b'\xFF' }
  { r, g, b, a, }
}

///|
/// A 2D RGBA bitmap image buffer stored in row-major order.
pub struct PixelBuffer {
  width : Int32
  height : Int32
  pixels : FixedArray[Byte]
} derive(Debug)

///|
pub fn PixelBuffer::new(
  width : Int32,
  height : Int32,
  color~ : Rgba = Rgba::transparent(),
) -> PixelBuffer {
  let total_bytes = width * height * 4
  let pixels = FixedArray::make(total_bytes, b'\x00')
  let buf = { width, height, pixels, }
  if color.r != b'\x00' ||
    color.g != b'\x00' ||
    color.b != b'\x00' ||
    color.a != b'\x00' {
    buf.fill(color)
  }
  buf
}

///|
pub fn PixelBuffer::width(self : PixelBuffer) -> Int32 {
  self.width
}

///|
pub fn PixelBuffer::height(self : PixelBuffer) -> Int32 {
  self.height
}

///|
pub fn PixelBuffer::fill(self : PixelBuffer, color : Rgba) -> Unit {
  let total_pixels = self.width * self.height
  for i = 0; i < total_pixels; i = i + 1 {
    let offset = i * 4
    self.pixels[offset] = color.r
    self.pixels[offset + 1] = color.g
    self.pixels[offset + 2] = color.b
    self.pixels[offset + 3] = color.a
  }
}

///|
pub fn PixelBuffer::get_pixel(self : PixelBuffer, x : Int32, y : Int32) -> Rgba {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    return Rgba::transparent()
  }
  let offset = (y * self.width + x) * 4
  {
    r: self.pixels[offset],
    g: self.pixels[offset + 1],
    b: self.pixels[offset + 2],
    a: self.pixels[offset + 3],
  }
}

///|
pub fn PixelBuffer::set_pixel(
  self : PixelBuffer,
  x : Int32,
  y : Int32,
  color : Rgba,
) -> Unit {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    return
  }
  let offset = (y * self.width + x) * 4
  self.pixels[offset] = color.r
  self.pixels[offset + 1] = color.g
  self.pixels[offset + 2] = color.b
  self.pixels[offset + 3] = color.a
}

///|
/// Copies (blits) pixels from `src` into `self` at destination position `(dst_x, dst_y)`.
/// Supports optional 90-degree clockwise rotation.
pub fn PixelBuffer::blit(
  self : PixelBuffer,
  src : PixelBuffer,
  dst_x : Int32,
  dst_y : Int32,
  rotated~ : Bool = false,
) -> Unit {
  if !rotated {
    for sy = 0; sy < src.height; sy = sy + 1 {
      let dy = dst_y + sy
      if dy < 0 || dy >= self.height {
        continue
      }
      for sx = 0; sx < src.width; sx = sx + 1 {
        let dx = dst_x + sx
        if dx < 0 || dx >= self.width {
          continue
        }
        let src_off = (sy * src.width + sx) * 4
        let dst_off = (dy * self.width + dx) * 4
        self.pixels[dst_off] = src.pixels[src_off]
        self.pixels[dst_off + 1] = src.pixels[src_off + 1]
        self.pixels[dst_off + 2] = src.pixels[src_off + 2]
        self.pixels[dst_off + 3] = src.pixels[src_off + 3]
      }
    }
  } else {
    for sy = 0; sy < src.height; sy = sy + 1 {
      for sx = 0; sx < src.width; sx = sx + 1 {
        let dx = dst_x + (src.height - 1 - sy)
        let dy = dst_y + sx
        if dx >= 0 && dx < self.width && dy >= 0 && dy < self.height {
          let src_off = (sy * src.width + sx) * 4
          let dst_off = (dy * self.width + dx) * 4
          self.pixels[dst_off] = src.pixels[src_off]
          self.pixels[dst_off + 1] = src.pixels[src_off + 1]
          self.pixels[dst_off + 2] = src.pixels[src_off + 2]
          self.pixels[dst_off + 3] = src.pixels[src_off + 3]
        }
      }
    }
  }
}

///|
/// Eliminates GPU bilinear texture sampling bleeding by duplicating
/// the outer 1-pixel border of `rect` into the surrounding padding margin.
pub fn PixelBuffer::extrude_rect(
  self : PixelBuffer,
  rect : Rect,
  margin~ : Int32 = 1,
) -> Unit {
  if margin <= 0 || rect.width <= 0 || rect.height <= 0 {
    return
  }

  // Extrude top and bottom edges
  for m = 1; m <= margin; m = m + 1 {
    for x = rect.x; x < rect.right(); x = x + 1 {
      // Top row duplication
      if rect.y - m >= 0 {
        let top_color = self.get_pixel(x, rect.y)
        self.set_pixel(x, rect.y - m, top_color)
      }
      // Bottom row duplication
      if rect.bottom() - 1 + m < self.height {
        let bot_color = self.get_pixel(x, rect.bottom() - 1)
        self.set_pixel(x, rect.bottom() - 1 + m, bot_color)
      }
    }
  }

  // Extrude left and right edges
  for m = 1; m <= margin; m = m + 1 {
    for y = rect.y; y < rect.bottom(); y = y + 1 {
      // Left col duplication
      if rect.x - m >= 0 {
        let left_color = self.get_pixel(rect.x, y)
        self.set_pixel(rect.x - m, y, left_color)
      }
      // Right col duplication
      if rect.right() - 1 + m < self.width {
        let right_color = self.get_pixel(rect.right() - 1, y)
        self.set_pixel(rect.right() - 1 + m, y, right_color)
      }
    }
  }

  // Extrude 4 corners
  for my = 1; my <= margin; my = my + 1 {
    for mx = 1; mx <= margin; mx = mx + 1 {
      // Top-left
      if rect.x - mx >= 0 && rect.y - my >= 0 {
        self.set_pixel(rect.x - mx, rect.y - my, self.get_pixel(rect.x, rect.y))
      }
      // Top-right
      if rect.right() - 1 + mx < self.width && rect.y - my >= 0 {
        self.set_pixel(
          rect.right() - 1 + mx,
          rect.y - my,
          self.get_pixel(rect.right() - 1, rect.y),
        )
      }
      // Bottom-left
      if rect.x - mx >= 0 && rect.bottom() - 1 + my < self.height {
        self.set_pixel(
          rect.x - mx,
          rect.bottom() - 1 + my,
          self.get_pixel(rect.x, rect.bottom() - 1),
        )
      }
      // Bottom-right
      if rect.right() - 1 + mx < self.width &&
        rect.bottom() - 1 + my < self.height {
        self.set_pixel(
          rect.right() - 1 + mx,
          rect.bottom() - 1 + my,
          self.get_pixel(rect.right() - 1, rect.bottom() - 1),
        )
      }
    }
  }
}

///|
/// Encodes the pixel buffer into a standard uncompressed 32-bit BMP (Windows Bitmap) byte array.
/// Uses a top-down row orientation (-height) so pixel rows can be written directly without vertical flipping.
pub fn PixelBuffer::to_bmp(self : PixelBuffer) -> FixedArray[Byte] {
  let header_size = 54
  let image_size = self.width * self.height * 4
  let file_size = header_size + image_size
  let out = FixedArray::make(file_size, b'\x00')

  // BITMAPFILEHEADER (14 bytes)
  out[0] = b'B'
  out[1] = b'M'
  // bfSize (4 bytes little-endian)
  out[2] = (file_size & 0xFF).to_byte()
  out[3] = ((file_size >> 8) & 0xFF).to_byte()
  out[4] = ((file_size >> 16) & 0xFF).to_byte()
  out[5] = ((file_size >> 24) & 0xFF).to_byte()
  // bfOffBits = 54
  out[10] = b'\x36'

  // BITMAPINFOHEADER (40 bytes)
  // biSize = 40
  out[14] = b'\x28'
  // biWidth (4 bytes)
  out[18] = (self.width & 0xFF).to_byte()
  out[19] = ((self.width >> 8) & 0xFF).to_byte()
  out[20] = ((self.width >> 16) & 0xFF).to_byte()
  out[21] = ((self.width >> 24) & 0xFF).to_byte()
  // biHeight (top-down DIB: -self.height)
  let neg_h = -self.height
  out[22] = (neg_h & 0xFF).to_byte()
  out[23] = ((neg_h >> 8) & 0xFF).to_byte()
  out[24] = ((neg_h >> 16) & 0xFF).to_byte()
  out[25] = ((neg_h >> 24) & 0xFF).to_byte()
  // biPlanes = 1
  out[26] = b'\x01'
  // biBitCount = 32 (BGRA)
  out[28] = b'\x20'
  // biCompression = 0 (BI_RGB)
  // biSizeImage
  out[34] = (image_size & 0xFF).to_byte()
  out[35] = ((image_size >> 8) & 0xFF).to_byte()
  out[36] = ((image_size >> 16) & 0xFF).to_byte()
  out[37] = ((image_size >> 24) & 0xFF).to_byte()
  // biXPelsPerMeter = 2835 (0x0B13)
  out[38] = b'\x13'
  out[39] = b'\x0B'
  // biYPelsPerMeter = 2835
  out[42] = b'\x13'
  out[43] = b'\x0B'

  // Pixel Data: BMP 32-bit stores BGRA (Blue, Green, Red, Alpha)
  let total_pixels = self.width * self.height
  for i = 0; i < total_pixels; i = i + 1 {
    let src_off = i * 4
    let dst_off = header_size + i * 4
    let r = self.pixels[src_off]
    let g = self.pixels[src_off + 1]
    let b = self.pixels[src_off + 2]
    let a = self.pixels[src_off + 3]
    out[dst_off] = b
    out[dst_off + 1] = g
    out[dst_off + 2] = r
    out[dst_off + 3] = a
  }

  out
}

///|
/// Converts the pixel buffer into an immutable `Bytes` object containing standard BMP file data.
pub fn PixelBuffer::to_bmp_bytes(self : PixelBuffer) -> Bytes {
  let arr = self.to_bmp()
  let list = []
  for b in arr {
    list.push(b)
  }
  Bytes::from_array(list)
}

///|
/// Sub-image item to be packed and baked into a master atlas.
pub(all) struct ImageItem {
  id : Int32
  image : PixelBuffer
} derive(Debug)

///|
pub fn ImageItem::new(id : Int32, image : PixelBuffer) -> ImageItem {
  { id, image, }
}

///|
/// Result of baking multiple sub-images into an atlas page.
pub(all) struct BakedAtlas {
  page_index : Int32
  image : PixelBuffer
  frames : Array[Rect]
  uv_frames : Array[UvRect]
} derive(Debug)

///|
/// High-level 2D Texture Atlas Baker that packs sub-images into pixel buffers
/// and applies physical 1-pixel edge extrusion to completely eliminate GPU sampling bleeding.
pub struct AtlasBaker {
  options : AtlasOptions
  extrude_margin : Int32
} derive(Debug)

///|
pub fn AtlasBaker::new(
  options~ : AtlasOptions = AtlasOptions::default(),
  extrude_margin~ : Int32 = 1,
) -> AtlasBaker {
  { options, extrude_margin, }
}

///|
/// Bakes an array of image items into one or more pixel buffer atlas pages,
/// automatically performing:
/// 1. Geometric packing via AtlasPacker
/// 2. Pixel copying (blitting) with rotation support
/// 3. Physical 1-pixel edge color extrusion to eliminate GPU sampling bleeding
/// 4. Half-texel UV coordinate calculation for GPU shaders
pub fn AtlasBaker::bake(
  self : AtlasBaker,
  items : Array[ImageItem],
) -> Array[BakedAtlas] {
  if items.length() == 0 {
    return []
  }

  // Extract sizes
  let sizes = []
  for item in items {
    sizes.push(Size::new(item.image.width, item.image.height))
  }

  let packer = AtlasPacker::new(options=self.options)
  let result = packer.pack(sizes)

  let baked_pages = []

  for p_idx = 0; p_idx < result.pages.length(); p_idx = p_idx + 1 {
    let page_bin = result.pages[p_idx]
    let canvas = PixelBuffer::new(
      page_bin.width,
      page_bin.height,
      color=Rgba::transparent(),
    )
    let page_rects = []
    let page_uvs = []

    for r in result.rects {
      if r.bin_index == p_idx {
        page_rects.push(r)
        let uv = r.to_uv(page_bin.width, page_bin.height, half_texel_inset=true)
        page_uvs.push(uv)

        // Find corresponding source image
        let mut found_src : PixelBuffer? = None
        for item in items {
          if item.id == r.id {
            found_src = Some(item.image)
            break
          }
        }

        match found_src {
          Some(src) => {
            canvas.blit(src, r.x, r.y, rotated=r.rotated)
            if self.extrude_margin > 0 {
              canvas.extrude_rect(r, margin=self.extrude_margin)
            }
          }
          None => ()
        }
      }
    }

    baked_pages.push({
      page_index: p_idx,
      image: canvas,
      frames: page_rects,
      uv_frames: page_uvs,
    })
  }

  baked_pages
}
