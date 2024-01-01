module FlexiMapsExt

using FlexiMaps
using UnionCollections
using UnionCollections.Accessors

FlexiMaps.mapview(f, v::UnionArray) = @modify(v.parts) do ps
    map(p -> mapview(f, p), ps)
end

# TODO disambiguation:
# FlexiMaps.mapview(p::Union{Symbol,Int,String}, A::UnionArray) = mapview(PropertyLens(p), A)

end
