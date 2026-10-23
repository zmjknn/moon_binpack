///|
/// A horizontal segment in the Skyline bin packing algorithm.
pub(all) struct SkylineNode {
  x : Int32
  y : Int32
  width : Int32
} derive(Eq, Debug, Default)

///|
pub fn SkylineNode::new(x : Int32, y : Int32, width : Int32) -> SkylineNode {
  { x, y, width, }
}

///|
/// 2D bin packer based on the Skyline algorithm with Min-Waste and Bottom-Left heuristics.
pub struct SkylinePacker {
  bin_width : Int32
  bin_height : Int32
  skyline : Array[SkylineNode]
  used_rectangles : Array[Rect]
  mut used_surface_area : Int32
} derive(Debug)

///|
pub fn SkylinePacker::new(
  bin_width : Int32,
  bin_height : Int32,
) -> SkylinePacker {
  let initial = [SkylineNode::new(0, 0, bin_width)]
  {
    bin_width,
    bin_height,
    skyline: initial,
    used_rectangles: [],
    used_surface_area: 0,
  }
}

///|
pub fn SkylinePacker::bin_width(self : SkylinePacker) -> Int32 {
  self.bin_width
}

///|
pub fn SkylinePacker::bin_height(self : SkylinePacker) -> Int32 {
  self.bin_height
}

///|
pub fn SkylinePacker::used_rectangles(self : SkylinePacker) -> Array[Rect] {
  self.used_rectangles
}

///|
pub fn SkylinePacker::occupancy(self : SkylinePacker) -> Double {
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
/// Checks whether a rectangle of (width, height) can be placed resting on node at `node_index`.
/// Returns (supported_y, waste_area, fits).
fn SkylinePacker::fit_rectangle(
  self : SkylinePacker,
  node_index : Int32,
  width : Int32,
  height : Int32,
) -> (Int32, Int32, Bool) {
  let node = self.skyline[node_index]
  let x = node.x

  if x + width > self.bin_width {
    return (0, 0, false)
  }

  let mut max_y = node.y
  let mut idx = node_index

  while idx < self.skyline.length() && self.skyline[idx].x < x + width {
    if self.skyline[idx].y > max_y {
      max_y = self.skyline[idx].y
    }
    idx = idx + 1
  }

  if max_y + height > self.bin_height {
    return (0, 0, false)
  }

  // Calculate waste area underneath the newly placed rectangle
  let mut waste = 0
  for i = node_index; i < idx; i = i + 1 {
    let cur = self.skyline[i]
    let left = if cur.x > x { cur.x } else { x }
    let cur_right = cur.x + cur.width
    let right = if cur_right < x + width { cur_right } else { x + width }
    let w = right - left
    waste = waste + w * (max_y - cur.y)
  }

  (max_y, waste, true)
}

///|
/// Finds the best position for a rectangle of (width, height) using the specified heuristic.
fn SkylinePacker::find_rectangle(
  self : SkylinePacker,
  width : Int32,
  height : Int32,
  heuristic : SkylineHeuristic,
  allow_rotation : Bool,
) -> Rect? {
  let mut best_node = Rect::new(0, 0, 0, 0)
  let mut best_score1 = 2147483647
  let mut best_score2 = 2147483647
  let mut found = false

  for i = 0; i < self.skyline.length(); i = i + 1 {
    // Normal orientation
    let (y, waste, fits) = self.fit_rectangle(i, width, height)
    if fits {
      let (s1, s2) = match heuristic {
        BottomLeft => (y + height, self.skyline[i].x)
        MinWasteFit => (waste, y + height)
      }
      if s1 < best_score1 || (s1 == best_score1 && s2 < best_score2) {
        best_score1 = s1
        best_score2 = s2
        best_node = Rect::new(
          self.skyline[i].x,
          y,
          width,
          height,
          rotated=false,
        )
        found = true
      }
    }

    // Rotated orientation
    if allow_rotation && width != height {
      let (y_rot, waste_rot, fits_rot) = self.fit_rectangle(i, height, width)
      if fits_rot {
        let (s1, s2) = match heuristic {
          BottomLeft => (y_rot + width, self.skyline[i].x)
          MinWasteFit => (waste_rot, y_rot + width)
        }
        if s1 < best_score1 || (s1 == best_score1 && s2 < best_score2) {
          best_score1 = s1
          best_score2 = s2
          best_node = Rect::new(
            self.skyline[i].x,
            y_rot,
            height,
            width,
            rotated=true,
          )
          found = true
        }
      }
    }
  }

  if found {
    Some(best_node)
  } else {
    None
  }
}

///|
/// Updates the skyline profile with the new level introduced by `placed`.
fn SkylinePacker::add_skyline_level(
  self : SkylinePacker,
  placed : Rect,
) -> Unit {
  let new_node = SkylineNode::new(
    placed.x,
    placed.y + placed.height,
    placed.width,
  )
  let new_skyline = []

  for node in self.skyline {
    if node.x + node.width <= placed.x {
      // Completely to the left
      new_skyline.push(node)
    } else if node.x >= placed.right() {
      // Completely to the right
      new_skyline.push(node)
    } else {
      // Overlaps with [placed.x, placed.right()]
      if node.x < placed.x {
        new_skyline.push(SkylineNode::new(node.x, node.y, placed.x - node.x))
      }
      if node.x + node.width > placed.right() {
        new_skyline.push(
          SkylineNode::new(
            placed.right(),
            node.y,
            node.x + node.width - placed.right(),
          ),
        )
      }
    }
  }

  // Insert new_node in sorted order by x
  let mut inserted = false
  let final_skyline = []
  for node in new_skyline {
    if !inserted && new_node.x <= node.x {
      final_skyline.push(new_node)
      inserted = true
    }
    final_skyline.push(node)
  }
  if !inserted {
    final_skyline.push(new_node)
  }

  self.skyline.clear()
  for node in final_skyline {
    self.skyline.push(node)
  }

  self.merge_skyline()
}

///|
/// Merges adjacent skyline nodes that have the same height.
fn SkylinePacker::merge_skyline(self : SkylinePacker) -> Unit {
  let mut i = 0
  while i < self.skyline.length() - 1 {
    let cur = self.skyline[i]
    let next = self.skyline[i + 1]
    if cur.y == next.y && cur.x + cur.width == next.x {
      self.skyline[i] = SkylineNode::new(cur.x, cur.y, cur.width + next.width)
      let _ = self.skyline.remove(i + 1)
    } else {
      i = i + 1
    }
  }
}

///|
/// Inserts a rectangle of dimensions (width, height) using the Skyline algorithm.
pub fn SkylinePacker::insert(
  self : SkylinePacker,
  width : Int32,
  height : Int32,
  id~ : Int32 = 0,
  heuristic~ : SkylineHeuristic = SkylineHeuristic::BottomLeft,
  allow_rotation~ : Bool = true,
) -> Rect? {
  if width <= 0 || height <= 0 {
    return None
  }

  let candidate = self.find_rectangle(width, height, heuristic, allow_rotation)
  match candidate {
    Some(best) => {
      let placed = Rect::new(
        best.x,
        best.y,
        best.width,
        best.height,
        id~,
        rotated=best.rotated,
      )
      self.add_skyline_level(placed)
      self.used_rectangles.push(placed)
      self.used_surface_area = self.used_surface_area + width * height
      Some(placed)
    }
    None => None
  }
}

///|
/// Packs an array of sizes into the bin with pre-sorting by area descending using Skyline.
pub fn SkylinePacker::insert_batch(
  self : SkylinePacker,
  sizes : Array[Size],
  heuristic~ : SkylineHeuristic = SkylineHeuristic::BottomLeft,
  allow_rotation~ : Bool = true,
) -> (Array[Rect], Array[Size]) {
  let indexed = []
  for i = 0; i < sizes.length(); i = i + 1 {
    indexed.push((sizes[i], i))
  }

  // Stable descending insertion sort by area
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
