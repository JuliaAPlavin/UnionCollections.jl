module DictionariesExt

using Dictionaries
import UnionCollections: any_element, unioncollection
using UnionCollections
using UnionCollections.Accessors

struct UnionDictionary{I,T,VT<:UnionVector{T}} <: AbstractDictionary{I,T}
    indices::Indices{I}
    values::VT
end

UnionDictionary(indices, values) = UnionDictionary(Indices(indices), unionarray(values))
UnionDictionary(dict) = UnionDictionary(keys(dict), values(dict))

unioncollection(dict::AbstractDictionary) = UnionDictionary(dict)

Base.keys(dict::UnionDictionary) = getfield(dict, :indices)
_values(dict) = getfield(dict, :values)
Accessors.set(dict::UnionDictionary, ::typeof(_values), values) = UnionDictionary(keys(dict), values)
Dictionaries.tokenized(dict::UnionDictionary) = _values(dict)

Dictionaries.istokenassigned(dict::UnionDictionary, (_slot, index)) = isassigned(_values(dict), index)
Dictionaries.istokenassigned(dict::UnionDictionary, index::Int) = isassigned(_values(dict), index)
Dictionaries.gettokenvalue(dict::UnionDictionary, (_slot, index)) = _values(dict)[index]
Dictionaries.gettokenvalue(dict::UnionDictionary, index::Int) = _values(dict)[index]

Base.map(f, d::UnionDictionary) = @modify(vs -> map(f, vs), _values(d))

any_element(d::UnionDictionary) = any_element(_values(d))

end
