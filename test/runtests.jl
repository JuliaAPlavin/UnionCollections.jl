using TestItems
using TestItemRunner
@run_package_tests


@testitem "1d vector" begin
    using UnionCollections: any_element
    using UnionCollections.Accessors
    using FlexiMaps

    A = unioncollection([1, 2, "xx", 3, "yyy"])
    @test A isa UnionVector
    @test A == [1, 2, "xx", 3, "yyy"]
    @test eltype(A) == Union{Int, String}
    @test (@inferred any_element(A)) == 1

    ma = @inferred map(length, A)
    @test ma::UnionVector == [1, 1, 2, 1, 3]
    @test eltype(ma) == Int

    suba = @inferred A[2:4]
    @test suba::UnionVector == [2, "xx", 3]
    va = @inferred view(A, 2:4)
    @test va::UnionVector == [2, "xx", 3]

    f(x::Int) = x + 1
    f(x::String) = x * "!"
    ma = @inferred map(f, A)
    @test ma::UnionVector == [2, 3, "xx!", 4, "yyy!"]
    @test eltype(ma) == Union{Int, String}

    ma = @inferred mapview(f, A)
    @test ma::UnionVector == [2, 3, "xx!", 4, "yyy!"]
    @test eltype(ma) == Union{Int, String}

    pred(x::Int) = x > 1
    pred(x::String) = length(x) > 2
    fa = @inferred filter(pred, A)
    @test fa::UnionVector == [2, 3, "yyy"]
    @test (@inferred findall(pred, A)) == [2, 4, 5]
    @test (@inferred Nothing findfirst(pred, A)) == 2


    A = unioncollection([1, 2, "xx", 3, "yyy"])
    resize!(A, 3)
    @test A == [1, 2, "xx"]
    @test sum(length, A.parts) == 3

    A = unioncollection([1, 2, "xx", 3, "yyy"])
    resize!(A, 7)
    @test A[1:5] == [1, 2, "xx", 3, "yyy"]
    @test typeof.(A[6:7]) == [Int, Int]
    @test sum(length, A.parts) == 7

    A = unioncollection([1, 2, "xx", 3, "yyy"])
    @test A[1] == 1
    A[2] = 4
    A[3] = 5
    push!(A, "zz")
    push!(A, 6)
    @test A == [1, 4, 5, 3, "yyy", "zz", 6]

    B = @set A[3] = 6.
    B = @set B[4] = :xxx
    B = @insert last(B) = 1+2im
    B = @delete B[1]
    @test B == [4, 6., :xxx, "yyy", "zz", 6, 1+2im]
    @test B isa UnionArray{Union{Int,Float64,Complex{Int},String,Symbol}}  # should we promote Int and Float to Complex?
    @test A == [1, 4, 5, 3, "yyy", "zz", 6]
end

@testitem "nd array" begin
    using UnionCollections: any_element

    A = unioncollection([1 2; "xx" 4; "yy" 5])
    @test A isa UnionArray
    @test (@inferred any_element(A)) == 1
    ma = @inferred map(length, A)
    @test ma::UnionArray == [1 1; 2 1; 2 1]
end

@testitem "dictionary" begin
    using Dictionaries
    using UnionCollections: any_element
    using FlexiMaps
    using UnionCollections.Accessors

    const UnionDictionary = Base.get_extension(UnionCollections, :DictionariesExt).UnionDictionary

    D = unioncollection(dictionary([:a => 1, :b => "xx", :c => 3]))
    @test D == dictionary([:a => 1, :b => "xx", :c => 3])
    @test eltype(D) == Union{Int, String}
    @test (@inferred any_element(D)) == 1

    @test UnionDictionary(Dict(:a => 1, :b => "xx", :c => 3)) == D

    @test (@inferred map(length, D)) == dictionary([:a => 1, :b => 2, :c => 1])
    @test (@inferred filter(x -> true, D)) == D

    @test D.a == 1
    @test (@set D.a = 5) == dictionary([:a => 5, :b => "xx", :c => 3])
    @test Accessors.getproperties(D) == (a=1, b="xx", c=3)

    D[:a] = 4
    D[:c] = "yy"
    delete!(D, :b)
    insert!(D, :d, "zz")
    @test D == dictionary([:a => 4, :c => "yy", :d => "zz"])
end

@testitem "any_element" begin
    using UnionCollections: any_element

    any_element([1, 2, 3]) == 1
end


@testitem "_" begin
    import Aqua
    Aqua.test_all(UnionCollections; ambiguities=false)
    # Aqua.test_ambiguities(UnionCollections)  # similar() ambiguities

    import CompatHelperLocal as CHL
    CHL.@check()
end
