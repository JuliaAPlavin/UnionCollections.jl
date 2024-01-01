module UnionCollections

using Accessors

export UnionArray, UnionVector, unioncollection, unionarray


struct UnionArray{T,N,PS<:Tuple} <: AbstractArray{T,N}
    parts::PS
    ix_to_partix::Array{Tuple{Int,Int},N}
end
const UnionVector{T} = UnionArray{T,1}

UnionArray(parts::Tuple, ix_to_partix) = UnionArray{Union{eltype.(parts)...}}(parts, ix_to_partix)
UnionArray{T}(parts, ix_to_partix::AbstractArray{<:Any,N}) where {T,N} = UnionArray{T,N,typeof(parts)}(parts, ix_to_partix)

Base.IndexStyle(::Type{<:UnionArray}) = IndexStyle(Array)  # of ix_to_partix

unioncollection(vals::AbstractArray) = unionarray(vals)

function unionarray(vals::AbstractArray)
    types = unique(map(typeof, vals)) |> Tuple
    parts = map(T -> similar(vals, T, 0), types)
    ix_to_partix = map(vals) do v
        partix = findfirst(==(typeof(v)), types)
        push!(parts[partix], v)
        (partix, lastindex(parts[partix]))
    end
    return UnionArray(parts, ix_to_partix)
end

function unionarray(vals)
    types = unique(map(typeof, vals)) |> Tuple
    parts = map(T -> T[], types)
    ix_to_partix = map(vals) do v
        partix = findfirst(==(typeof(v)), types)
        push!(parts[partix], v)
        (partix, lastindex(parts[partix]))
    end |> collect
    return UnionArray(parts, ix_to_partix)
end

Base.@propagate_inbounds function Base.getindex(ua::UnionArray, I::Int...)
    partix, ix_in_part = ua.ix_to_partix[I...]
    return ua.parts[partix][ix_in_part]
end

Base.@propagate_inbounds function Base.getindex(ua::UnionArray, I...)
    ixs_by_partix = map(_ -> Int[], ua.parts)
    new_ix_to_partix = ua.ix_to_partix[I...]
    map!(new_ix_to_partix, new_ix_to_partix) do (partix, ix_in_part)
        push!(ixs_by_partix[partix], ix_in_part)
        (partix, length(ixs_by_partix[partix]))
    end
    UnionArray(
        map(getindex, ua.parts, ixs_by_partix),
        new_ix_to_partix
    )
end

Base.@propagate_inbounds Base.view(ua::UnionArray, I...) =
    UnionArray(
        ua.parts,
        @view ua.ix_to_partix[I...]
    )

Base.size(ua::UnionArray) = size(ua.ix_to_partix)
Base.map(f, ua::UnionArray) = @modify(ua.parts) do ps
    map(p -> map(f, p), ps)
end

any_element(ua::UnionArray) = first(first(ua.parts))

end
