module FlexiMapsExt

using FlexiMaps
using UnionCollections
using UnionCollections.Accessors

FlexiMaps.mapview(f, v::UnionArray) = @modify(v.parts) do ps
    map(p -> mapview(f, p), ps)
end

end
