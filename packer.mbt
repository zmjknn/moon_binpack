///|
/// Configuration options for AtlasPacker.
pub(all) struct AtlasOptions {
  max_width : Int32
  max_height : Int32
  padding : Int32
  border_padding : Int32
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
pub fn AtlasPacker::new(
  options~ : AtlasOptions = AtlasOptions::default(),
) -> AtlasPacker {
  { options, }
}

///|
/// Packs an array of item sizes into one or more bins according to configured options.
pub fn AtlasPacker::pack(
  self : AtlasPacker,
  items : Array[Size],
) -> AtlasResult {
  if items.length() == 0 {
    return { pages: [], rects: [], unpacked: [], stats: Default::default(), }
  }

  if self.options.auto_grow_pot {
    self.pack_auto_grow(items)
  } else {
    self.pack_fixed_bins(items, self.options.max_width, self.options.max_height)
  }
}

///|
fn AtlasPacker::pack_auto_grow(
  self : AtlasPacker,
  items : Array[Size],
) -> AtlasResult {
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
fn AtlasPacker::pack_fixed_bins(
  self : AtlasPacker,
  items : Array[Size],
  bin_w : Int32,
  bin_h : Int32,
  single_page_only~ : Bool = false,
) -> AtlasResult {
  let effective_w = bin_w - self.options.border_padding * 2
  let effective_h = bin_h - self.options.border_padding * 2

  if effective_w <= 0 || effective_h <= 0 {
    return { pages: [], rects: [], unpacked: items, stats: Default::default(), }
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
        heuristic=self.options.heuristic,
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

    if !packed_any_this_page || single_page_only {
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
      return { pages, rects: packed_rects, unpacked, stats, }
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

  { pages, rects: packed_rects, unpacked: empty_unpacked, stats, }
}

///|
/// Packs an array of item sizes using the Skyline algorithm with multi-bin overflow and POT growth.
pub fn AtlasPacker::pack_skyline(
  self : AtlasPacker,
  items : Array[Size],
  heuristic~ : SkylineHeuristic = SkylineHeuristic::BottomLeft,
) -> AtlasResult {
  if items.length() == 0 {
    return { pages: [], rects: [], unpacked: [], stats: Default::default(), }
  }

  if self.options.auto_grow_pot {
    self.pack_skyline_auto_grow(items, heuristic~)
  } else {
    self.pack_skyline_fixed_bins(
      items,
      self.options.max_width,
      self.options.max_height,
      heuristic~,
    )
  }
}

///|
fn AtlasPacker::pack_skyline_auto_grow(
  self : AtlasPacker,
  items : Array[Size],
  heuristic~ : SkylineHeuristic,
) -> AtlasResult {
  let pot_sizes = [64, 128, 256, 512, 1024, 2048, 4096]

  for dim in pot_sizes {
    if dim <= self.options.max_width && dim <= self.options.max_height {
      let res = self.pack_skyline_fixed_bins(
        items,
        dim,
        dim,
        heuristic~,
        single_page_only=true,
      )
      if res.unpacked.length() == 0 {
        return res
      }
    }
  }

  self.pack_skyline_fixed_bins(
    items,
    self.options.max_width,
    self.options.max_height,
    heuristic~,
  )
}

///|
fn AtlasPacker::pack_skyline_fixed_bins(
  self : AtlasPacker,
  items : Array[Size],
  bin_w : Int32,
  bin_h : Int32,
  heuristic~ : SkylineHeuristic,
  single_page_only~ : Bool = false,
) -> AtlasResult {
  let effective_w = bin_w - self.options.border_padding * 2
  let effective_h = bin_h - self.options.border_padding * 2

  if effective_w <= 0 || effective_h <= 0 {
    return { pages: [], rects: [], unpacked: items, stats: Default::default(), }
  }

  let remaining = []
  for i = 0; i < items.length(); i = i + 1 {
    remaining.push((items[i], i))
  }

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

    let packer = SkylinePacker::new(effective_w, effective_h)
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
        heuristic~,
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

    if !packed_any_this_page || single_page_only {
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
      return { pages, rects: packed_rects, unpacked, stats, }
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

  { pages, rects: packed_rects, unpacked: empty_unpacked, stats, }
}

///|
/// Packs an array of item sizes using the Guillotine algorithm with multi-bin overflow and POT growth.
pub fn AtlasPacker::pack_guillotine(
  self : AtlasPacker,
  items : Array[Size],
  merge~ : Bool = true,
  rect_choice~ : GuillotineHeuristic = GuillotineHeuristic::BestShortSideFit,
  split_method~ : SplitHeuristic = SplitHeuristic::ShorterLeftoverAxis,
) -> AtlasResult {
  if items.length() == 0 {
    return { pages: [], rects: [], unpacked: [], stats: Default::default(), }
  }

  if self.options.auto_grow_pot {
    self.pack_guillotine_auto_grow(items, merge~, rect_choice~, split_method~)
  } else {
    self.pack_guillotine_fixed_bins(
      items,
      self.options.max_width,
      self.options.max_height,
      merge~,
      rect_choice~,
      split_method~,
    )
  }
}

///|
fn AtlasPacker::pack_guillotine_auto_grow(
  self : AtlasPacker,
  items : Array[Size],
  merge~ : Bool,
  rect_choice~ : GuillotineHeuristic,
  split_method~ : SplitHeuristic,
) -> AtlasResult {
  let pot_sizes = [64, 128, 256, 512, 1024, 2048, 4096]

  for dim in pot_sizes {
    if dim <= self.options.max_width && dim <= self.options.max_height {
      let res = self.pack_guillotine_fixed_bins(
        items,
        dim,
        dim,
        merge~,
        rect_choice~,
        split_method~,
        single_page_only=true,
      )
      if res.unpacked.length() == 0 {
        return res
      }
    }
  }

  self.pack_guillotine_fixed_bins(
    items,
    self.options.max_width,
    self.options.max_height,
    merge~,
    rect_choice~,
    split_method~,
  )
}

///|
fn AtlasPacker::pack_guillotine_fixed_bins(
  self : AtlasPacker,
  items : Array[Size],
  bin_w : Int32,
  bin_h : Int32,
  merge~ : Bool,
  rect_choice~ : GuillotineHeuristic,
  split_method~ : SplitHeuristic,
  single_page_only~ : Bool = false,
) -> AtlasResult {
  let effective_w = bin_w - self.options.border_padding * 2
  let effective_h = bin_h - self.options.border_padding * 2

  if effective_w <= 0 || effective_h <= 0 {
    return { pages: [], rects: [], unpacked: items, stats: Default::default(), }
  }

  let remaining = []
  for i = 0; i < items.length(); i = i + 1 {
    remaining.push((items[i], i))
  }

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

    let packer = GuillotinePacker::new(effective_w, effective_h)
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
        merge~,
        rect_choice~,
        split_method~,
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

    if !packed_any_this_page || single_page_only {
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
      return { pages, rects: packed_rects, unpacked, stats, }
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

  { pages, rects: packed_rects, unpacked: empty_unpacked, stats, }
}

///|
/// Packs an array of item sizes using the Shelf algorithm with multi-bin overflow and POT growth.
pub fn AtlasPacker::pack_shelf(
  self : AtlasPacker,
  items : Array[Size],
  heuristic~ : ShelfHeuristic = ShelfHeuristic::BestAreaFit,
) -> AtlasResult {
  if items.length() == 0 {
    return { pages: [], rects: [], unpacked: [], stats: Default::default(), }
  }

  if self.options.auto_grow_pot {
    self.pack_shelf_auto_grow(items, heuristic~)
  } else {
    self.pack_shelf_fixed_bins(
      items,
      self.options.max_width,
      self.options.max_height,
      heuristic~,
    )
  }
}

///|
fn AtlasPacker::pack_shelf_auto_grow(
  self : AtlasPacker,
  items : Array[Size],
  heuristic~ : ShelfHeuristic,
) -> AtlasResult {
  let pot_sizes = [64, 128, 256, 512, 1024, 2048, 4096]

  for dim in pot_sizes {
    if dim <= self.options.max_width && dim <= self.options.max_height {
      let res = self.pack_shelf_fixed_bins(
        items,
        dim,
        dim,
        heuristic~,
        single_page_only=true,
      )
      if res.unpacked.length() == 0 {
        return res
      }
    }
  }

  self.pack_shelf_fixed_bins(
    items,
    self.options.max_width,
    self.options.max_height,
    heuristic~,
  )
}

///|
fn AtlasPacker::pack_shelf_fixed_bins(
  self : AtlasPacker,
  items : Array[Size],
  bin_w : Int32,
  bin_h : Int32,
  heuristic~ : ShelfHeuristic,
  single_page_only~ : Bool = false,
) -> AtlasResult {
  let effective_w = bin_w - self.options.border_padding * 2
  let effective_h = bin_h - self.options.border_padding * 2

  if effective_w <= 0 || effective_h <= 0 {
    return { pages: [], rects: [], unpacked: items, stats: Default::default(), }
  }

  let remaining = []
  for i = 0; i < items.length(); i = i + 1 {
    remaining.push((items[i], i))
  }

  for i = 1; i < remaining.length(); i = i + 1 {
    let key = remaining[i]
    let mut j = i - 1
    while j >= 0 && remaining[j].0.height < key.0.height {
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

    let packer = ShelfPacker::new(effective_w, effective_h)
    let next_remaining = []
    let mut packed_any_this_page = false

    for item in remaining {
      let (sz, orig_id) = item
      let req_w = sz.width + self.options.padding
      let req_h = sz.height + self.options.padding

      let inserted = packer.insert(req_w, req_h, id=orig_id, heuristic~)

      match inserted {
        Some(placed) => {
          let actual_rect = Rect::new(
            placed.x + self.options.border_padding,
            placed.y + self.options.border_padding,
            sz.width,
            sz.height,
            id=orig_id,
            rotated=false,
            bin_index=page_idx,
          )
          packed_rects.push(actual_rect)
          packed_any_this_page = true
        }
        None => next_remaining.push(item)
      }
    }

    if !packed_any_this_page || single_page_only {
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
      return { pages, rects: packed_rects, unpacked, stats, }
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

  { pages, rects: packed_rects, unpacked: empty_unpacked, stats, }
}

///|
/// Compares two packing results to determine if candidate is better than current best.
/// Criteria:
/// 1. Fewer unpacked items
/// 2. Fewer total bin pages
/// 3. Smaller total bin surface area
/// 4. Higher occupancy rate
fn is_better_result(cand : AtlasResult, best : AtlasResult) -> Bool {
  if cand.unpacked.length() < best.unpacked.length() {
    return true
  }
  if cand.unpacked.length() > best.unpacked.length() {
    return false
  }

  if cand.pages.length() < best.pages.length() {
    return true
  }
  if cand.pages.length() > best.pages.length() {
    return false
  }

  let area_c = if cand.pages.length() > 0 {
    cand.pages[0].area() * cand.pages.length()
  } else {
    0
  }
  let area_b = if best.pages.length() > 0 {
    best.pages[0].area() * best.pages.length()
  } else {
    0
  }
  if area_c < area_b {
    return true
  }
  if area_c > area_b {
    return false
  }

  cand.stats.occupancy > best.stats.occupancy
}

///|
/// Multi-algorithm heuristic arena that tests 18 heuristics across 4 algorithm families
/// (MaxRects, Skyline, Guillotine, Shelf) to find the most compact layout for a given set of items.
/// Returns the winning `AtlasResult` and the name of the winning algorithm.
pub fn best_pack(
  items : Array[Size],
  max_width~ : Int32 = 2048,
  max_height~ : Int32 = 2048,
  padding~ : Int32 = 2,
  border_padding~ : Int32 = 2,
  allow_rotation~ : Bool = true,
  auto_grow_pot~ : Bool = true,
) -> (AtlasResult, String) {
  if items.length() == 0 {
    let empty_res : AtlasResult = {
      pages: [],
      rects: [],
      unpacked: [],
      stats: Default::default(),
    }
    return (empty_res, "None")
  }

  let maxrects_heuristics = [
    (MaxRectsHeuristic::BestShortSideFit, "MaxRects-BSSF"),
    (MaxRectsHeuristic::BestLongSideFit, "MaxRects-BLSF"),
    (MaxRectsHeuristic::BestAreaFit, "MaxRects-BAF"),
    (MaxRectsHeuristic::BottomLeftRule, "MaxRects-BottomLeft"),
    (MaxRectsHeuristic::ContactPointRule, "MaxRects-ContactPoint"),
  ]

  let skyline_heuristics = [
    (SkylineHeuristic::MinWasteFit, "Skyline-MinWaste"),
    (SkylineHeuristic::BottomLeft, "Skyline-BottomLeft"),
  ]

  let guillotine_heuristics = [
    (GuillotineHeuristic::BestShortSideFit, "Guillotine-BSSF"),
    (GuillotineHeuristic::BestLongSideFit, "Guillotine-BLSF"),
    (GuillotineHeuristic::BestAreaFit, "Guillotine-BAF"),
    (GuillotineHeuristic::WorstShortSideFit, "Guillotine-WSSF"),
    (GuillotineHeuristic::WorstLongSideFit, "Guillotine-WLSF"),
    (GuillotineHeuristic::WorstAreaFit, "Guillotine-WAF"),
  ]

  let shelf_heuristics = [
    (ShelfHeuristic::BestAreaFit, "Shelf-BAF"),
    (ShelfHeuristic::BestHeightFit, "Shelf-BHF"),
    (ShelfHeuristic::FirstFit, "Shelf-FirstFit"),
    (ShelfHeuristic::NextFit, "Shelf-NextFit"),
    (ShelfHeuristic::WorstAreaFit, "Shelf-WAF"),
  ]

  let mut best_result : AtlasResult? = None
  let mut best_name = ""

  // MaxRects arena
  for h in maxrects_heuristics {
    let (heuristic, name) = h
    let opts = AtlasOptions::{
      max_width,
      max_height,
      padding,
      border_padding,
      allow_rotation,
      auto_grow_pot,
      heuristic,
    }
    let packer = AtlasPacker::new(options=opts)
    let res = packer.pack(items)

    match best_result {
      None => {
        best_result = Some(res)
        best_name = name
      }
      Some(cur_best) =>
        if is_better_result(res, cur_best) {
          best_result = Some(res)
          best_name = name
        }
    }
  }

  // Skyline arena
  let base_opts = AtlasOptions::{
    max_width,
    max_height,
    padding,
    border_padding,
    allow_rotation,
    auto_grow_pot,
    heuristic: MaxRectsHeuristic::BestShortSideFit,
  }
  let arena_packer = AtlasPacker::new(options=base_opts)

  for h in skyline_heuristics {
    let (heuristic, name) = h
    let res = arena_packer.pack_skyline(items, heuristic~)

    match best_result {
      None => {
        best_result = Some(res)
        best_name = name
      }
      Some(cur_best) =>
        if is_better_result(res, cur_best) {
          best_result = Some(res)
          best_name = name
        }
    }
  }

  // Guillotine arena
  for h in guillotine_heuristics {
    let (rect_choice, name) = h
    let res = arena_packer.pack_guillotine(items, merge=true, rect_choice~)

    match best_result {
      None => {
        best_result = Some(res)
        best_name = name
      }
      Some(cur_best) =>
        if is_better_result(res, cur_best) {
          best_result = Some(res)
          best_name = name
        }
    }
  }

  // Shelf arena
  for h in shelf_heuristics {
    let (heuristic, name) = h
    let res = arena_packer.pack_shelf(items, heuristic~)

    match best_result {
      None => {
        best_result = Some(res)
        best_name = name
      }
      Some(cur_best) =>
        if is_better_result(res, cur_best) {
          best_result = Some(res)
          best_name = name
        }
    }
  }

  match best_result {
    Some(res) => (res, best_name)
    None => {
      let empty : AtlasResult = {
        pages: [],
        rects: [],
        unpacked: [],
        stats: Default::default(),
      }
      (empty, "None")
    }
  }
}
