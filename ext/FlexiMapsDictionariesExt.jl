module FlexiMapsDictionariesExt

using Dictionaries
using FlexiMaps
using UnionCollections
using UnionCollections.Accessors

const UnionDictionary = Base.get_extension(UnionCollections, :DictionariesExt).UnionDictionary

FlexiMaps.mapview(f, d::UnionDictionary) = @modify(d.parts) do ps
    map(p -> mapview(f, p), ps)
end

end
