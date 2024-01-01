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

Base.@propagate_inbounds function Base.setindex!(ua::UnionArray, v, I::Int...)
    partix, ix_in_part = ua.ix_to_partix[I...]
    if v isa eltype(ua.parts[partix])
        ua.parts[partix][ix_in_part] = v
    else
        old_partix = partix
        # find new part
        partix = findfirst(p -> v isa eltype(p), ua.parts)
        @assert partix != nothing "No part with eltype $(typeof(v)) found"

        # remove old value, shift indices by one
        popat!(ua.parts[old_partix], ix_in_part)
        map!(ua.ix_to_partix, ua.ix_to_partix) do (p, i)
            if p == old_partix && i > ix_in_part
                (p, i-1)
            else
                (p, i)
            end
        end

        # insert new value and update the index
        push!(ua.parts[partix], v)
        ua.ix_to_partix[I...] = (partix, lastindex(ua.parts[partix]))
    end
    return ua
end

function Base.resize!(ua::UnionVector, newlen::Integer)
    if newlen < length(ua)
        for (partix, ix_in_part) in @view ua.ix_to_partix[end:-1:newlen+1]
            @assert ix_in_part == lastindex(ua.parts[partix])
            pop!(ua.parts[partix])
        end
        resize!(ua.ix_to_partix, newlen)
    elseif newlen > length(ua)
        len₊ = newlen - length(ua)
        part = first(ua.parts)
        for i in 1:len₊
            push!(ua.ix_to_partix, (1, lastindex(part) + i))
        end
        resize!(part, length(part) + len₊)
    end
    return ua
end

function Base.insert!(ua::UnionVector, I::Int, v)
    partix = findfirst(p -> v isa eltype(p), ua.parts)
    @assert partix != nothing "No part with eltype $(typeof(v)) found"
    push!(ua.parts[partix], v)
    insert!(ua.ix_to_partix, I, (partix, lastindex(ua.parts[partix])))
    return ua
end
function Base.deleteat!(ua::UnionVector, I::Int)
    partix, ix_in_part = ua.ix_to_partix[I]
    popat!(ua.parts[partix], ix_in_part)
    map!(ua.ix_to_partix, ua.ix_to_partix) do (p, i)
        if p == partix && i > ix_in_part
            (p, i-1)
        else
            (p, i)
        end
    end
    deleteat!(ua.ix_to_partix, I)
    return ua
end

Base.size(ua::UnionArray) = size(ua.ix_to_partix)
Base.map(f, ua::UnionArray) = @modify(ua.parts) do ps
    map(p -> map(f, p), ps)
end

Base.similar(ua::UnionArray, args...) = error("similar() deliberately not implemented")
Base.similar(ua::UnionArray) = UnionArray(
    map(similar, ua.parts),
    copy(ua.ix_to_partix)
)
Base.similar(ua::UnionArray{T}, ::Type{T}) where {T} = similar(ua)

any_element(ua::UnionArray) = first(first(ua.parts))
any_element(x) = first(x)  # fallback


function Accessors.setindex(ua::UnionArray, v, I::Int...)
    partix, ix_in_part = ua.ix_to_partix[I...]
    if v isa eltype(ua.parts[partix])
        return setindex!(copy(ua), v, I...)
    elseif any(p -> v isa eltype(p), ua.parts)
        return setindex!(copy(ua), v, I...)
    else
        # remove old value, shift indices by one
        parts = ua.parts
        parts = @delete parts[partix][ix_in_part]
        ix_to_partix = map(ua.ix_to_partix) do (p, i)
            if p == partix && i > ix_in_part
                (p, i-1)
            else
                (p, i)
            end
        end

        # create new part with the new value, update its index
        parts = (parts..., [v])
        ix_to_partix = @set ix_to_partix[I...] = (lastindex(parts), lastindex(last(parts)))

        return UnionArray(parts, ix_to_partix)
    end
end

function Accessors.insert(ua::UnionVector, l::IndexLens, v)
    I = only(l.indices)
    if any(p -> v isa eltype(p), ua.parts)
        return insert!(copy(ua), I, v)
    else
        # create new part with the new value
        parts = (ua.parts..., [v])

        # set its index
        ix_to_partix = ua.ix_to_partix
        ix_to_partix = @insert ix_to_partix[I] = (lastindex(parts), lastindex(last(parts)))

        return UnionArray(parts, ix_to_partix)
    end
end

Accessors.delete(obj::UnionVector, l::IndexLens) = deleteat!(copy(obj), only(l.indices))

end
