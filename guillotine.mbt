///|
/// 2D bin packer based on the Guillotine cut algorithm.
pub struct GuillotinePacker {
  bin_width : Int32
  bin_height : Int32
  free_rectangles : Array[Rect]
  mut used_surface_area : Int32
} derive(Debug)

///|
pub fn GuillotinePacker::new(
  bin_width : Int32,
  bin_height : Int32,
) -> GuillotinePacker {
  let free = [Rect::new(0, 0, bin_width, bin_height)]
  { bin_width, bin_height, free_rectangles: free, used_surface_area: 0, }
}

///|
pub fn GuillotinePacker::bin_width(self : GuillotinePacker) -> Int32 {
  self.bin_width
}

///|
pub fn GuillotinePacker::bin_height(self : GuillotinePacker) -> Int32 {
  self.bin_height
}

///|
pub fn GuillotinePacker::occupancy(self : GuillotinePacker) -> Double {
  let total = self.bin_width * self.bin_height
  if total > 0 {
    self.used_surface_area.to_double() / total.to_double()
  } else {
    0.0
  }
}

///|
/// Attempts to insert a rectangle of dimensions (width, height).
pub fn GuillotinePacker::insert(
  self : GuillotinePacker,
  width : Int32,
  height : Int32,
  id~ : Int32 = 0,
  merge~ : Bool = true,
  rect_choice~ : GuillotineHeuristic = GuillotineHeuristic::BestShortSideFit,
  split_method~ : SplitHeuristic = SplitHeuristic::ShorterLeftoverAxis,
) -> Rect? {
  if width <= 0 || height <= 0 {
    return None
  }

  let (best_index, rotated) = self.find_best_free_rect(
    width, height, rect_choice,
  )
  if best_index == -1 {
    return None
  }

  let free_rect = self.free_rectangles[best_index]
  let placed_w = if rotated { height } else { width }
  let placed_h = if rotated { width } else { height }

  let placed = Rect::new(
    free_rect.x,
    free_rect.y,
    placed_w,
    placed_h,
    id~,
    rotated~,
  )

  // Remove the chosen free rectangle
  let _ = self.free_rectangles.remove(best_index)

  // Split remainder into new free rectangles
  self.split_free_rect(free_rect, placed, split_method)

  if merge {
    self.merge_free_rectangles()
  }

  self.used_surface_area = self.used_surface_area + width * height
  Some(placed)
}

///|
fn GuillotinePacker::find_best_free_rect(
  self : GuillotinePacker,
  width : Int32,
  height : Int32,
  heuristic : GuillotineHeuristic,
) -> (Int32, Bool) {
  let mut best_index = -1
  let mut best_rotated = false
  let mut best_score1 = 2147483647
  let mut best_score2 = 2147483647

  // Worst-fit heuristics maximize score instead
  let is_worst = match heuristic {
    WorstAreaFit | WorstShortSideFit | WorstLongSideFit => true
    _ => false
  }

  if is_worst {
    best_score1 = -1
    best_score2 = -1
  }

  for i = 0; i < self.free_rectangles.length(); i = i + 1 {
    let f = self.free_rectangles[i]

    // Normal orientation
    if width <= f.width && height <= f.height {
      let (score1, score2) = self.score_by_heuristic(
        f, width, height, heuristic,
      )
      if is_worst {
        if score1 > best_score1 ||
          (score1 == best_score1 && score2 > best_score2) {
          best_score1 = score1
          best_score2 = score2
          best_index = i
          best_rotated = false
        }
      } else if score1 < best_score1 ||
        (score1 == best_score1 && score2 < best_score2) {
        best_score1 = score1
        best_score2 = score2
        best_index = i
        best_rotated = false
      }
    }

    // Rotated orientation
    if height <= f.width && width <= f.height {
      let (score1, score2) = self.score_by_heuristic(
        f, height, width, heuristic,
      )
      if is_worst {
        if score1 > best_score1 ||
          (score1 == best_score1 && score2 > best_score2) {
          best_score1 = score1
          best_score2 = score2
          best_index = i
          best_rotated = true
        }
      } else if score1 < best_score1 ||
        (score1 == best_score1 && score2 < best_score2) {
        best_score1 = score1
        best_score2 = score2
        best_index = i
        best_rotated = true
      }
    }
  }

  (best_index, best_rotated)
}

///|
fn GuillotinePacker::score_by_heuristic(
  self : GuillotinePacker,
  f : Rect,
  w : Int32,
  h : Int32,
  heuristic : GuillotineHeuristic,
) -> (Int32, Int32) {
  let _ = self
  let rem_w = f.width - w
  let rem_h = f.height - h
  let short_side = if rem_w < rem_h { rem_w } else { rem_h }
  let long_side = if rem_w > rem_h { rem_w } else { rem_h }

  match heuristic {
    BestAreaFit | WorstAreaFit => (f.area() - w * h, short_side)
    BestShortSideFit | WorstShortSideFit => (short_side, long_side)
    BestLongSideFit | WorstLongSideFit => (long_side, short_side)
  }
}

///|
fn GuillotinePacker::split_free_rect(
  self : GuillotinePacker,
  free : Rect,
  placed : Rect,
  heuristic : SplitHeuristic,
) -> Unit {
  let w = placed.width
  let h = placed.height
  let rem_w = free.width - w
  let rem_h = free.height - h

  let split_horizontal = match heuristic {
    ShorterLeftoverAxis => rem_w <= rem_h
    LongerLeftoverAxis => rem_w > rem_h
    MinimizeArea => rem_w * h <= w * rem_h
    MaximizeArea => rem_w * h > w * rem_h
    ShorterAxis => free.width <= free.height
    LongerAxis => free.width > free.height
  }

  if split_horizontal {
    // Bottom slice full width, right slice matching placed height
    let bottom = Rect::new(free.x, free.y + h, free.width, rem_h)
    let right = Rect::new(free.x + w, free.y, rem_w, h)
    if bottom.width > 0 && bottom.height > 0 {
      self.free_rectangles.push(bottom)
    }
    if right.width > 0 && right.height > 0 {
      self.free_rectangles.push(right)
    }
  } else {
    // Right slice full height, bottom slice matching placed width
    let bottom = Rect::new(free.x, free.y + h, w, rem_h)
    let right = Rect::new(free.x + w, free.y, rem_w, free.height)
    if bottom.width > 0 && bottom.height > 0 {
      self.free_rectangles.push(bottom)
    }
    if right.width > 0 && right.height > 0 {
      self.free_rectangles.push(right)
    }
  }
}

///|
/// Merges adjacent free rectangles that form a single larger rectangle.
pub fn GuillotinePacker::merge_free_rectangles(self : GuillotinePacker) -> Unit {
  let mut i = 0
  while i < self.free_rectangles.length() {
    let mut j = i + 1
    let mut merged = false
    while j < self.free_rectangles.length() {
      let a = self.free_rectangles[i]
      let b = self.free_rectangles[j]

      // Same horizontal span, perfectly aligned vertically
      if a.x == b.x &&
        a.width == b.width &&
        (a.y + a.height == b.y || b.y + b.height == a.y) {
        let min_y = if a.y < b.y { a.y } else { b.y }
        let total_h = a.height + b.height
        self.free_rectangles[i] = Rect::new(a.x, min_y, a.width, total_h)
        let _ = self.free_rectangles.remove(j)
        merged = true
        break
      }

      // Same vertical span, perfectly aligned horizontally
      if a.y == b.y &&
        a.height == b.height &&
        (a.x + a.width == b.x || b.x + b.width == a.x) {
        let min_x = if a.x < b.x { a.x } else { b.x }
        let total_w = a.width + b.width
        self.free_rectangles[i] = Rect::new(min_x, a.y, total_w, a.height)
        let _ = self.free_rectangles.remove(j)
        merged = true
        break
      }

      j = j + 1
    }

    if !merged {
      i = i + 1
    }
  }
}
