module DictionariesExt

using Dictionaries
import UnionCollections: any_element, unioncollection
using UnionCollections
using UnionCollections.Accessors
using UnionCollections.Accessors.ConstructionBase

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


# see the PR for all AbstractDictionaries:
# https://github.com/andyferris/Dictionaries.jl/pull/43
Base.propertynames(d::UnionDictionary) = keys(d)
Base.@propagate_inbounds Base.getproperty(d::D, s::Symbol) where {D<:UnionDictionary} = d[s]
ConstructionBase.setproperties(obj::UnionDictionary, patch::NamedTuple) = merge(obj, Dictionary(keys(patch), values(patch)))

end
