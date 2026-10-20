///|
/// Configuration options for AtlasPacker.
pub(all) struct AtlasOptions {
  max_width : Int
  max_height : Int
  padding : Int
  border_padding : Int
  allow_rotation : Bool
  auto_grow_pot : Bool
  heuristic : MaxRectsHeuristic
} derive(Eq, Debug)

///|
pub fn AtlasOptions::default() -> AtlasOptions {
  {
    max_width: 2048,
    max_height: 2048,
    padding: 2,
    border_padding: 2,
    allow_rotation: true,
    auto_grow_pot: true,
    heuristic: MaxRectsHeuristic::BestShortSideFit,
  }
}

///|
/// Result of multi-bin atlas packing.
pub(all) struct AtlasResult {
  pages : Array[Bin]
  rects : Array[Rect]
  unpacked : Array[Size]
  stats : PackingStats
} derive(Eq, Debug)

///|
/// High-level 2D texture atlas packer supporting padding, rotation,
/// multi-bin overflow, and adaptive power-of-two growth.
pub struct AtlasPacker {
  options : AtlasOptions
} derive(Debug)

///|
pub fn AtlasPacker::new(options~ : AtlasOptions = AtlasOptions::default()) -> AtlasPacker {
  { options, }
}

///|
/// Packs an array of item sizes into one or more bins according to configured options.
pub fn pack(self : AtlasPacker, items : Array[Size]) -> AtlasResult {
  if items.length() == 0 {
    return {
      pages: [],
      rects: [],
      unpacked: [],
      stats: PackingStats::default(),
    }
  }

  if self.options.auto_grow_pot {
    self.pack_auto_grow(items)
  } else {
    self.pack_fixed_bins(items, self.options.max_width, self.options.max_height)
  }
}

///|
fn pack_auto_grow(self : AtlasPacker, items : Array[Size]) -> AtlasResult {
  // Candidate power of two dimensions
  let pot_sizes = [64, 128, 256, 512, 1024, 2048, 4096]

  // Try to find the smallest single POT bin that fits all items
  for dim in pot_sizes {
    if dim <= self.options.max_width && dim <= self.options.max_height {
      let res = self.pack_fixed_bins(items, dim, dim, single_page_only=true)
      if res.unpacked.length() == 0 {
        return res
      }
    }
  }

  // If cannot fit in single POT bin, fall back to multi-bin packing at max_width/max_height
  self.pack_fixed_bins(items, self.options.max_width, self.options.max_height)
}

///|
fn pack_fixed_bins(
  self : AtlasPacker,
  items : Array[Size],
  bin_w : Int,
  bin_h : Int,
  single_page_only~ : Bool = false
) -> AtlasResult {
  let effective_w = bin_w - self.options.border_padding * 2
  let effective_h = bin_h - self.options.border_padding * 2

  if effective_w <= 0 || effective_h <= 0 {
    return {
      pages: [],
      rects: [],
      unpacked: items,
      stats: PackingStats::default(),
    }
  }

  // Prepare remaining items with original index
  let remaining = []
  for i = 0; i < items.length(); i = i + 1 {
    remaining.push((items[i], i))
  }

  // Sort descending by area
  for i = 1; i < remaining.length(); i = i + 1 {
    let key = remaining[i]
    let mut j = i - 1
    while j >= 0 && remaining[j].0.area() < key.0.area() {
      remaining[j + 1] = remaining[j]
      j = j - 1
    }
    remaining[j + 1] = key
  }

  let pages = []
  let packed_rects = []
  let mut page_idx = 0

  while remaining.length() > 0 {
    let page_bin = Bin::new(bin_w, bin_h)
    pages.push(page_bin)

    let packer = MaxRectsPacker::new(effective_w, effective_h)
    let next_remaining = []
    let mut packed_any_this_page = false

    for item in remaining {
      let (sz, orig_id) = item
      let req_w = sz.width + self.options.padding
      let req_h = sz.height + self.options.padding

      let inserted = packer.insert(
        req_w,
        req_h,
        id=orig_id,
        method=self.options.heuristic,
        allow_rotation=self.options.allow_rotation,
      )

      match inserted {
        Some(placed) => {
          let final_w = if placed.rotated { sz.height } else { sz.width }
          let final_h = if placed.rotated { sz.width } else { sz.height }
          let actual_rect = Rect::new(
            placed.x + self.options.border_padding,
            placed.y + self.options.border_padding,
            final_w,
            final_h,
            id=orig_id,
            rotated=placed.rotated,
            bin_index=page_idx,
          )
          packed_rects.push(actual_rect)
          packed_any_this_page = true
        }
        None => next_remaining.push(item)
      }
    }

    if not(packed_any_this_page) || single_page_only {
      // Cannot make forward progress on this item set
      let unpacked = []
      for it in next_remaining {
        unpacked.push(it.0)
      }
      let stats = PackingStats::compute(
        items.length(),
        packed_rects,
        unpacked,
        pages.length(),
        bin_w * bin_h,
      )
      return { pages, rects: packed_rects, unpacked, stats }
    }

    remaining.clear()
    for it in next_remaining {
      remaining.push(it)
    }
    page_idx = page_idx + 1
  }

  let empty_unpacked : Array[Size] = []
  let stats = PackingStats::compute(
    items.length(),
    packed_rects,
    empty_unpacked,
    pages.length(),
    bin_w * bin_h,
  )

  { pages, rects: packed_rects, unpacked: empty_unpacked, stats }
}
