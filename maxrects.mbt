///|
/// 2D bin packer based on the Maximal Rectangles (MaxRects) algorithm.
pub struct MaxRectsPacker {
  bin_width : Int32
  bin_height : Int32
  free_rectangles : Array[Rect]
  used_rectangles : Array[Rect]
} derive(Debug)

///|
pub fn MaxRectsPacker::new(
  bin_width : Int32,
  bin_height : Int32,
) -> MaxRectsPacker {
  let free = [Rect::new(0, 0, bin_width, bin_height)]
  { bin_width, bin_height, free_rectangles: free, used_rectangles: [], }
}

///|
pub fn MaxRectsPacker::bin_width(self : MaxRectsPacker) -> Int32 {
  self.bin_width
}

///|
pub fn MaxRectsPacker::bin_height(self : MaxRectsPacker) -> Int32 {
  self.bin_height
}

///|
pub fn MaxRectsPacker::used_rectangles(self : MaxRectsPacker) -> Array[Rect] {
  self.used_rectangles
}

///|
pub fn MaxRectsPacker::occupancy(self : MaxRectsPacker) -> Double {
  let total = self.bin_width * self.bin_height
  let mut used = 0
  for r in self.used_rectangles {
    used = used + r.area()
  }
  if total > 0 {
    used.to_double() / total.to_double()
  } else {
    0.0
  }
}

///|
/// Inserts a rectangle with dimensions (width, height) using the specified heuristic.
pub fn MaxRectsPacker::insert(
  self : MaxRectsPacker,
  width : Int32,
  height : Int32,
  id~ : Int32 = 0,
  heuristic~ : MaxRectsHeuristic = MaxRectsHeuristic::BestShortSideFit,
  allow_rotation~ : Bool = true,
) -> Rect? {
  if width <= 0 || height <= 0 {
    return None
  }

  let (best_node, best_score1, best_score2) = match heuristic {
    BestShortSideFit =>
      self.find_best_short_side_fit(width, height, allow_rotation)
    BestLongSideFit =>
      self.find_best_long_side_fit(width, height, allow_rotation)
    BestAreaFit => self.find_best_area_fit(width, height, allow_rotation)
    BottomLeftRule => self.find_bottom_left(width, height, allow_rotation)
    ContactPointRule => self.find_contact_point(width, height, allow_rotation)
  }

  let _ = best_score1
  let _ = best_score2

  if best_node.width == 0 || best_node.height == 0 {
    return None
  }

  let placed = Rect::new(
    best_node.x,
    best_node.y,
    best_node.width,
    best_node.height,
    id~,
    rotated=best_node.rotated,
  )

  self.split_free_rectangles(placed)
  self.prune_free_rectangles()
  self.used_rectangles.push(placed)

  Some(placed)
}

///|
fn MaxRectsPacker::find_best_short_side_fit(
  self : MaxRectsPacker,
  width : Int32,
  height : Int32,
  allow_rotation : Bool,
) -> (Rect, Int32, Int32) {
  let mut best_node = Rect::new(0, 0, 0, 0)
  let mut best_short_side = 2147483647
  let mut best_long_side = 2147483647

  for f in self.free_rectangles {
    // Normal orientation
    if f.width >= width && f.height >= height {
      let rem_x = f.width - width
      let rem_y = f.height - height
      let short_side = if rem_x < rem_y { rem_x } else { rem_y }
      let long_side = if rem_x > rem_y { rem_x } else { rem_y }

      if short_side < best_short_side ||
        (short_side == best_short_side && long_side < best_long_side) {
        best_node = Rect::new(f.x, f.y, width, height, rotated=false)
        best_short_side = short_side
        best_long_side = long_side
      }
    }

    // Rotated orientation
    if allow_rotation && f.width >= height && f.height >= width {
      let rem_x = f.width - height
      let rem_y = f.height - width
      let short_side = if rem_x < rem_y { rem_x } else { rem_y }
      let long_side = if rem_x > rem_y { rem_x } else { rem_y }

      if short_side < best_short_side ||
        (short_side == best_short_side && long_side < best_long_side) {
        best_node = Rect::new(f.x, f.y, height, width, rotated=true)
        best_short_side = short_side
        best_long_side = long_side
      }
    }
  }

  (best_node, best_short_side, best_long_side)
}

///|
fn MaxRectsPacker::find_best_long_side_fit(
  self : MaxRectsPacker,
  width : Int32,
  height : Int32,
  allow_rotation : Bool,
) -> (Rect, Int32, Int32) {
  let mut best_node = Rect::new(0, 0, 0, 0)
  let mut best_short_side = 2147483647
  let mut best_long_side = 2147483647

  for f in self.free_rectangles {
    // Normal orientation
    if f.width >= width && f.height >= height {
      let rem_x = f.width - width
      let rem_y = f.height - height
      let short_side = if rem_x < rem_y { rem_x } else { rem_y }
      let long_side = if rem_x > rem_y { rem_x } else { rem_y }

      if long_side < best_long_side ||
        (long_side == best_long_side && short_side < best_short_side) {
        best_node = Rect::new(f.x, f.y, width, height, rotated=false)
        best_short_side = short_side
        best_long_side = long_side
      }
    }

    // Rotated orientation
    if allow_rotation && f.width >= height && f.height >= width {
      let rem_x = f.width - height
      let rem_y = f.height - width
      let short_side = if rem_x < rem_y { rem_x } else { rem_y }
      let long_side = if rem_x > rem_y { rem_x } else { rem_y }

      if long_side < best_long_side ||
        (long_side == best_long_side && short_side < best_short_side) {
        best_node = Rect::new(f.x, f.y, height, width, rotated=true)
        best_short_side = short_side
        best_long_side = long_side
      }
    }
  }

  (best_node, best_short_side, best_long_side)
}

///|
fn MaxRectsPacker::find_best_area_fit(
  self : MaxRectsPacker,
  width : Int32,
  height : Int32,
  allow_rotation : Bool,
) -> (Rect, Int32, Int32) {
  let mut best_node = Rect::new(0, 0, 0, 0)
  let mut best_area_fit = 2147483647
  let mut best_short_side = 2147483647

  for f in self.free_rectangles {
    let area_fit = f.area() - width * height

    // Normal orientation
    if f.width >= width && f.height >= height {
      let rem_x = f.width - width
      let rem_y = f.height - height
      let short_side = if rem_x < rem_y { rem_x } else { rem_y }

      if area_fit < best_area_fit ||
        (area_fit == best_area_fit && short_side < best_short_side) {
        best_node = Rect::new(f.x, f.y, width, height, rotated=false)
        best_area_fit = area_fit
        best_short_side = short_side
      }
    }

    // Rotated orientation
    if allow_rotation && f.width >= height && f.height >= width {
      let rem_x = f.width - height
      let rem_y = f.height - width
      let short_side = if rem_x < rem_y { rem_x } else { rem_y }

      if area_fit < best_area_fit ||
        (area_fit == best_area_fit && short_side < best_short_side) {
        best_node = Rect::new(f.x, f.y, height, width, rotated=true)
        best_area_fit = area_fit
        best_short_side = short_side
      }
    }
  }

  (best_node, best_area_fit, best_short_side)
}

///|
fn MaxRectsPacker::find_bottom_left(
  self : MaxRectsPacker,
  width : Int32,
  height : Int32,
  allow_rotation : Bool,
) -> (Rect, Int32, Int32) {
  let mut best_node = Rect::new(0, 0, 0, 0)
  let mut best_y = 2147483647
  let mut best_x = 2147483647

  for f in self.free_rectangles {
    // Normal orientation
    if f.width >= width && f.height >= height {
      let top_y = f.y + height
      if top_y < best_y || (top_y == best_y && f.x < best_x) {
        best_node = Rect::new(f.x, f.y, width, height, rotated=false)
        best_y = top_y
        best_x = f.x
      }
    }

    // Rotated orientation
    if allow_rotation && f.width >= height && f.height >= width {
      let top_y = f.y + width
      if top_y < best_y || (top_y == best_y && f.x < best_x) {
        best_node = Rect::new(f.x, f.y, height, width, rotated=true)
        best_y = top_y
        best_x = f.x
      }
    }
  }

  (best_node, best_y, best_x)
}

///|
fn MaxRectsPacker::find_contact_point(
  self : MaxRectsPacker,
  width : Int32,
  height : Int32,
  allow_rotation : Bool,
) -> (Rect, Int32, Int32) {
  let mut best_node = Rect::new(0, 0, 0, 0)
  let mut best_contact = -1

  for f in self.free_rectangles {
    if f.width >= width && f.height >= height {
      let score = self.contact_point_score(f.x, f.y, width, height)
      if score > best_contact {
        best_node = Rect::new(f.x, f.y, width, height, rotated=false)
        best_contact = score
      }
    }

    if allow_rotation && f.width >= height && f.height >= width {
      let score = self.contact_point_score(f.x, f.y, height, width)
      if score > best_contact {
        best_node = Rect::new(f.x, f.y, height, width, rotated=true)
        best_contact = score
      }
    }
  }

  (best_node, best_contact, 0)
}

///|
fn MaxRectsPacker::contact_point_score(
  self : MaxRectsPacker,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> Int32 {
  let mut score = 0
  if x == 0 || x + w == self.bin_width {
    score = score + h
  }
  if y == 0 || y + h == self.bin_height {
    score = score + w
  }

  for u in self.used_rectangles {
    if (u.x == x + w || u.right() == x) && u.y < y + h && u.bottom() > y {
      let overlap_y1 = if u.y > y { u.y } else { y }
      let overlap_y2 = if u.bottom() < y + h { u.bottom() } else { y + h }
      score = score + (overlap_y2 - overlap_y1)
    }
    if (u.y == y + h || u.bottom() == y) && u.x < x + w && u.right() > x {
      let overlap_x1 = if u.x > x { u.x } else { x }
      let overlap_x2 = if u.right() < x + w { u.right() } else { x + w }
      score = score + (overlap_x2 - overlap_x1)
    }
  }

  score
}

///|
fn MaxRectsPacker::split_free_rectangles(
  self : MaxRectsPacker,
  placed : Rect,
) -> Unit {
  let new_free = []
  let mut i = 0

  while i < self.free_rectangles.length() {
    let f = self.free_rectangles[i]
    if f.intersects(placed) {
      // Top slice
      if placed.y > f.y && placed.y < f.bottom() {
        new_free.push(Rect::new(f.x, f.y, f.width, placed.y - f.y))
      }
      // Bottom slice
      if placed.bottom() < f.bottom() {
        new_free.push(
          Rect::new(f.x, placed.bottom(), f.width, f.bottom() - placed.bottom()),
        )
      }
      // Left slice
      if placed.x > f.x && placed.x < f.right() {
        new_free.push(Rect::new(f.x, f.y, placed.x - f.x, f.height))
      }
      // Right slice
      if placed.right() < f.right() {
        new_free.push(
          Rect::new(placed.right(), f.y, f.right() - placed.right(), f.height),
        )
      }

      let _ = self.free_rectangles.remove(i)
    } else {
      i = i + 1
    }
  }

  for nf in new_free {
    self.free_rectangles.push(nf)
  }
}

///|
fn MaxRectsPacker::prune_free_rectangles(self : MaxRectsPacker) -> Unit {
  let mut i = 0
  while i < self.free_rectangles.length() {
    let mut j = i + 1
    let mut removed = false

    while j < self.free_rectangles.length() {
      let fi = self.free_rectangles[i]
      let fj = self.free_rectangles[j]

      if fj.contains(fi) {
        let _ = self.free_rectangles.remove(i)
        removed = true
        break
      }

      if fi.contains(fj) {
        let _ = self.free_rectangles.remove(j)
      } else {
        j = j + 1
      }
    }

    if !removed {
      i = i + 1
    }
  }
}

///|
/// Packs an array of sizes into the bin with pre-sorting by area descending.
pub fn MaxRectsPacker::insert_batch(
  self : MaxRectsPacker,
  sizes : Array[Size],
  heuristic~ : MaxRectsHeuristic = MaxRectsHeuristic::BestShortSideFit,
  allow_rotation~ : Bool = true,
) -> (Array[Rect], Array[Size]) {
  // Copy and sort by area descending
  let indexed = []
  for i = 0; i < sizes.length(); i = i + 1 {
    indexed.push((sizes[i], i))
  }

  // Simple insertion sort for stable descending area
  for i = 1; i < indexed.length(); i = i + 1 {
    let key = indexed[i]
    let mut j = i - 1
    while j >= 0 && indexed[j].0.area() < key.0.area() {
      indexed[j + 1] = indexed[j]
      j = j - 1
    }
    indexed[j + 1] = key
  }

  let packed = []
  let unpacked = []

  for item in indexed {
    let (sz, orig_id) = item
    match
      self.insert(sz.width, sz.height, id=orig_id, heuristic~, allow_rotation~) {
      Some(r) => packed.push(r)
      None => unpacked.push(sz)
    }
  }

  (packed, unpacked)
}
