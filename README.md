# UnionCollections.jl

Efficient collections (arrays and dictionaries) with `Union` element types. Compared to `Vector{Union{...}}`, more operations are type-stable: most notably, `map()`.

Under the hood, elements of different types are stored in separate sub-collections. This allows for operations on the collection as a whole to be type-stable, while `X[i]` fundamentally remain type-unstable.

# Usage

```julia
# create a regular vector and a union vector:
julia> V = Union{Int, String}[1, 2, "x", 3, "yy"]
5-element Vector{Union{Int64, String}} <...>

julia> A = unioncollection(V)
5-element UnionVector{Union{Int64, String}} <...>

# these two work basically the same, but the union vector is more efficient
## Vector:

julia> map(x -> x^3, V)
5-element Vector{Any}:
  1
  8
   "xxx"
 27
   "yyyyyy"

julia> @code_warntype map(x -> x^3, V)
Body::Union{Vector{Any}, Vector{Int64}, Vector{String}}

julia> @btime map(x -> x^2, map(x -> x^3, $V))
  3.445 μs (19 allocations: 792 bytes)

## UnionVector:

julia> map(x -> x^3, A)
5-element UnionVector{Union{Int64, String}, Tuple{Vector{Int64}, Vector{String}}}:
  1
  8
   "xxx"
 27
   "yyyyyy"

julia> @code_warntype map(x -> x^3, A)
Body::UnionVector{Union{Int64, String}}

julia> @btime map(x -> x^2, map(x -> x^3, $A))
  197.597 ns (8 allocations: 392 bytes)
```
