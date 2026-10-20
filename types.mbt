///|
/// Represents a 2D size with integer width and height.
pub(all) struct Size {
  width : Int
  height : Int
} derive(Eq, Debug, Default)

///|
pub fn Size::new(width : Int, height : Int) -> Size {
  { width, height }
}

///|
pub fn area(self : Size) -> Int {
  self.width * self.height
}

///|
/// Represents a target bin with width and height boundaries.
pub(all) struct Bin {
  width : Int
  height : Int
} derive(Eq, Debug, Default)

///|
pub fn Bin::new(width : Int, height : Int) -> Bin {
  { width, height }
}

///|
pub fn area(self : Bin) -> Int {
  self.width * self.height
}

///|
/// Represents a 2D rectangle with position (x, y), dimensions (width, height),
/// an optional identifier, rotation flag, and bin page index.
pub(all) struct Rect {
  x : Int
  y : Int
  width : Int
  height : Int
  id : Int
  rotated : Bool
  bin_index : Int
} derive(Eq, Debug, Default)

///|
pub fn Rect::new(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  id~ : Int = 0,
  rotated~ : Bool = false,
  bin_index~ : Int = 0
) -> Rect {
  { x, y, width, height, id, rotated, bin_index }
}

///|
pub fn area(self : Rect) -> Int {
  self.width * self.height
}

///|
pub fn right(self : Rect) -> Int {
  self.x + self.width
}

///|
pub fn bottom(self : Rect) -> Int {
  self.y + self.height
}

///|
pub fn perimeter(self : Rect) -> Int {
  2 * (self.width + self.height)
}

///|
/// Returns true if this rectangle completely contains `other`.
pub fn contains(self : Rect, other : Rect) -> Bool {
  self.x <= other.x &&
  self.y <= other.y &&
  self.right() >= other.right() &&
  self.bottom() >= other.bottom()
}

///|
/// Returns true if this rectangle intersects with `other` (strict overlap with non-zero area).
pub fn intersects(self : Rect, other : Rect) -> Bool {
  self.x < other.right() &&
  self.right() > other.x &&
  self.y < other.bottom() &&
  self.bottom() > other.y
}

///|
/// Computes the intersection rectangle between `self` and `other`, if one exists.
pub fn intersection(self : Rect, other : Rect) -> Rect? {
  let nx = if self.x > other.x { self.x } else { other.x }
  let ny = if self.y > other.y { self.y } else { other.y }
  let nr = if self.right() < other.right() { self.right() } else { other.right() }
  let nb = if self.bottom() < other.bottom() { self.bottom() } else { other.bottom() }
  if nr > nx && nb > ny {
    Some(Rect::new(nx, ny, nr - nx, nb - ny))
  } else {
    None
  }
}

///|
/// Heuristic options for MaxRects bin packing algorithm.
pub(all) enum MaxRectsHeuristic {
  BestShortSideFit
  BestLongSideFit
  BestAreaFit
  BottomLeftRule
  ContactPointRule
} derive(Eq, Debug)

///|
/// Free rectangle choice heuristics for Guillotine bin packing algorithm.
pub(all) enum GuillotineHeuristic {
  BestAreaFit
  BestShortSideFit
  BestLongSideFit
  WorstAreaFit
  WorstShortSideFit
  WorstLongSideFit
} derive(Eq, Debug)

///|
/// Split heuristics for Guillotine cut algorithm.
pub(all) enum SplitHeuristic {
  ShorterLeftoverAxis
  LongerLeftoverAxis
  MinimizeArea
  MaximizeArea
  ShorterAxis
  LongerAxis
} derive(Eq, Debug)

///|
/// Heuristics for Shelf bin packing algorithm.
pub(all) enum ShelfHeuristic {
  NextFit
  FirstFit
  BestAreaFit
  BestHeightFit
  WorstAreaFit
} derive(Eq, Debug)

///|
/// Packing performance and occupancy statistics.
pub(all) struct PackingStats {
  total_items : Int
  packed_items : Int
  unpacked_items : Int
  total_bin_area : Int
  used_area : Int
  occupancy : Double
  bins_used : Int
} derive(Eq, Debug, Default)

///|
pub fn PackingStats::compute(
  total_items : Int,
  packed : Array[Rect],
  unpacked : Array[Size],
  bins_used : Int,
  bin_area : Int
) -> PackingStats {
  let mut used_area = 0
  for r in packed {
    used_area = used_area + r.area()
  }
  let total_bin_area = bins_used * bin_area
  let occupancy = if total_bin_area > 0 {
    used_area.to_double() / total_bin_area.to_double()
  } else {
    0.0
  }
  {
    total_items,
    packed_items: packed.length(),
    unpacked_items: unpacked.length(),
    total_bin_area,
    used_area,
    occupancy,
    bins_used,
  }
}
