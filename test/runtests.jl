using TestItems
using TestItemRunner
@run_package_tests


@testitem "_" begin
    import Aqua
    Aqua.test_all(UnionCollections; ambiguities=false)
    Aqua.test_ambiguities(UnionCollections)

    import CompatHelperLocal as CHL
    CHL.@check()
end
