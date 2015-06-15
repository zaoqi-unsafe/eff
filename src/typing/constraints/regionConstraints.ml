module RegionPoset = Poset.Make(struct
  type t = Type.region_param
  let compare = Pervasives.compare
  let print = Type.print_region_param ~non_poly:Trio.empty
end)

module FullRegions = Set.Make(struct
  type t = Type.region_param
  let compare = Pervasives.compare
end)

type t = {
  full_regions: FullRegions.t;
  regions: RegionPoset.t
}

let empty = {
  regions = RegionPoset.empty;
  full_regions = FullRegions.empty;
}

let union bnds1 bnds2 = {
  full_regions = FullRegions.union bnds1.full_regions bnds2.full_regions;
  regions = RegionPoset.merge bnds1.regions bnds2.regions;
}

let subst sbst bnds = {
  full_regions = FullRegions.fold (fun r s -> FullRegions.add (sbst.Type.region_param r) s) bnds.full_regions FullRegions.empty;
  regions = RegionPoset.map sbst.Type.region_param bnds.regions;
}

let garbage_collect pos neg bnds = {
  full_regions = FullRegions.filter (fun r -> List.mem r pos) bnds.full_regions;
  regions = RegionPoset.filter (fun x y -> List.mem x neg && List.mem y pos && not (FullRegions.mem y bnds.full_regions)) bnds.regions;
}

let add_full_region r bnds =
  let new_full_regions = r :: RegionPoset.get_succ r bnds.regions in
  {bnds with full_regions = List.fold_right FullRegions.add new_full_regions bnds.full_regions}

let add_region_constraint r1 r2 bnds =
  if FullRegions.mem r1 bnds.full_regions then
    let new_full_regions = r2 :: RegionPoset.get_succ r2 bnds.regions in
    {bnds with full_regions = List.fold_right FullRegions.add new_full_regions bnds.full_regions}
  else
    {bnds with regions = RegionPoset.add r1 r2 bnds.regions}

let print ~non_poly bnds ppf =
  Print.print ppf "%t; FULL: %t"
    (RegionPoset.print bnds.regions)
    (Print.sequence "," (Type.print_region_param ~non_poly) (FullRegions.elements bnds.full_regions))
