///|
/// A horizontal shelf in the bin.
struct Shelf {
  mut x : Int32
  y : Int32
  height : Int32
} derive(Eq, Debug)

///|
/// 2D bin packer based on horizontal shelves.
pub struct ShelfPacker {
  bin_width : Int32
  bin_height : Int32
  shelves : Array[Shelf]
  used_rectangles : Array[Rect]
  mut current_y : Int32
  mut used_surface_area : Int32
} derive(Debug)

///|
pub fn ShelfPacker::new(bin_width : Int32, bin_height : Int32) -> ShelfPacker {
  {
    bin_width,
    bin_height,
    shelves: [],
    used_rectangles: [],
    current_y: 0,
    used_surface_area: 0,
  }
}

///|
pub fn ShelfPacker::bin_width(self : ShelfPacker) -> Int32 {
  self.bin_width
}

///|
pub fn ShelfPacker::bin_height(self : ShelfPacker) -> Int32 {
  self.bin_height
}

///|
pub fn ShelfPacker::used_rectangles(self : ShelfPacker) -> Array[Rect] {
  self.used_rectangles
}

///|
pub fn ShelfPacker::occupancy(self : ShelfPacker) -> Double {
  let total = self.bin_width * self.bin_height
  if total > 0 {
    self.used_surface_area.to_double() / total.to_double()
  } else {
    0.0
  }
}

///|
/// Attempts to insert a rectangle of dimensions (width, height) using the specified heuristic.
pub fn ShelfPacker::insert(
  self : ShelfPacker,
  width : Int32,
  height : Int32,
  id~ : Int32 = 0,
  heuristic~ : ShelfHeuristic = ShelfHeuristic::BestAreaFit,
) -> Rect? {
  if width <= 0 ||
    height <= 0 ||
    width > self.bin_width ||
    height > self.bin_height {
    return None
  }

  let res = match heuristic {
    NextFit => self.insert_next_fit(width, height, id)
    FirstFit => self.insert_first_fit(width, height, id)
    BestAreaFit => self.insert_best_area_fit(width, height, id)
    BestHeightFit => self.insert_best_height_fit(width, height, id)
    WorstAreaFit => self.insert_worst_area_fit(width, height, id)
  }
  match res {
    Some(r) => {
      self.used_rectangles.push(r)
      Some(r)
    }
    None => None
  }
}

///|
/// Packs an array of sizes into the bin using the Shelf algorithm with pre-sorting by height descending.
pub fn ShelfPacker::insert_batch(
  self : ShelfPacker,
  sizes : Array[Size],
  heuristic~ : ShelfHeuristic = ShelfHeuristic::BestAreaFit,
) -> (Array[Rect], Array[Size]) {
  let indexed = []
  for i = 0; i < sizes.length(); i = i + 1 {
    indexed.push((sizes[i], i))
  }

  for i = 1; i < indexed.length(); i = i + 1 {
    let key = indexed[i]
    let mut j = i - 1
    while j >= 0 && indexed[j].0.height < key.0.height {
      indexed[j + 1] = indexed[j]
      j = j - 1
    }
    indexed[j + 1] = key
  }

  let packed = []
  let unpacked = []

  for item in indexed {
    let (sz, orig_id) = item
    match self.insert(sz.width, sz.height, id=orig_id, heuristic~) {
      Some(r) => packed.push(r)
      None => unpacked.push(sz)
    }
  }

  (packed, unpacked)
}

///|
fn ShelfPacker::insert_next_fit(
  self : ShelfPacker,
  width : Int32,
  height : Int32,
  id : Int32,
) -> Rect? {
  if self.shelves.length() > 0 {
    let last = self.shelves[self.shelves.length() - 1]
    if last.x + width <= self.bin_width && height <= last.height {
      let r = Rect::new(last.x, last.y, width, height, id~)
      last.x = last.x + width
      self.used_surface_area = self.used_surface_area + width * height
      return Some(r)
    }
  }

  // Create new shelf
  if self.current_y + height <= self.bin_height {
    let new_shelf = Shelf::{ x: width, y: self.current_y, height, }
    let r = Rect::new(0, self.current_y, width, height, id~)
    self.current_y = self.current_y + height
    self.shelves.push(new_shelf)
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else {
    None
  }
}

///|
fn ShelfPacker::insert_first_fit(
  self : ShelfPacker,
  width : Int32,
  height : Int32,
  id : Int32,
) -> Rect? {
  for shelf in self.shelves {
    if shelf.x + width <= self.bin_width && height <= shelf.height {
      let r = Rect::new(shelf.x, shelf.y, width, height, id~)
      shelf.x = shelf.x + width
      self.used_surface_area = self.used_surface_area + width * height
      return Some(r)
    }
  }

  // Start new shelf
  if self.current_y + height <= self.bin_height {
    let new_shelf = Shelf::{ x: width, y: self.current_y, height, }
    let r = Rect::new(0, self.current_y, width, height, id~)
    self.current_y = self.current_y + height
    self.shelves.push(new_shelf)
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else {
    None
  }
}

///|
fn ShelfPacker::insert_best_area_fit(
  self : ShelfPacker,
  width : Int32,
  height : Int32,
  id : Int32,
) -> Rect? {
  let mut best_index = -1
  let mut min_remaining_area = 2147483647

  for i = 0; i < self.shelves.length(); i = i + 1 {
    let shelf = self.shelves[i]
    if shelf.x + width <= self.bin_width && height <= shelf.height {
      let rem = (self.bin_width - shelf.x - width) * shelf.height
      if rem < min_remaining_area {
        min_remaining_area = rem
        best_index = i
      }
    }
  }

  if best_index != -1 {
    let shelf = self.shelves[best_index]
    let r = Rect::new(shelf.x, shelf.y, width, height, id~)
    shelf.x = shelf.x + width
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else if self.current_y + height <= self.bin_height {
    let new_shelf = Shelf::{ x: width, y: self.current_y, height, }
    let r = Rect::new(0, self.current_y, width, height, id~)
    self.current_y = self.current_y + height
    self.shelves.push(new_shelf)
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else {
    None
  }
}

///|
fn ShelfPacker::insert_best_height_fit(
  self : ShelfPacker,
  width : Int32,
  height : Int32,
  id : Int32,
) -> Rect? {
  let mut best_index = -1
  let mut min_height_diff = 2147483647

  for i = 0; i < self.shelves.length(); i = i + 1 {
    let shelf = self.shelves[i]
    if shelf.x + width <= self.bin_width && height <= shelf.height {
      let diff = shelf.height - height
      if diff < min_height_diff {
        min_height_diff = diff
        best_index = i
      }
    }
  }

  if best_index != -1 {
    let shelf = self.shelves[best_index]
    let r = Rect::new(shelf.x, shelf.y, width, height, id~)
    shelf.x = shelf.x + width
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else if self.current_y + height <= self.bin_height {
    let new_shelf = Shelf::{ x: width, y: self.current_y, height, }
    let r = Rect::new(0, self.current_y, width, height, id~)
    self.current_y = self.current_y + height
    self.shelves.push(new_shelf)
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else {
    None
  }
}

///|
fn ShelfPacker::insert_worst_area_fit(
  self : ShelfPacker,
  width : Int32,
  height : Int32,
  id : Int32,
) -> Rect? {
  let mut best_index = -1
  let mut max_remaining_area = -1

  for i = 0; i < self.shelves.length(); i = i + 1 {
    let shelf = self.shelves[i]
    if shelf.x + width <= self.bin_width && height <= shelf.height {
      let rem = (self.bin_width - shelf.x - width) * shelf.height
      if rem > max_remaining_area {
        max_remaining_area = rem
        best_index = i
      }
    }
  }

  if best_index != -1 {
    let shelf = self.shelves[best_index]
    let r = Rect::new(shelf.x, shelf.y, width, height, id~)
    shelf.x = shelf.x + width
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else if self.current_y + height <= self.bin_height {
    let new_shelf = Shelf::{ x: width, y: self.current_y, height, }
    let r = Rect::new(0, self.current_y, width, height, id~)
    self.current_y = self.current_y + height
    self.shelves.push(new_shelf)
    self.used_surface_area = self.used_surface_area + width * height
    Some(r)
  } else {
    None
  }
}
