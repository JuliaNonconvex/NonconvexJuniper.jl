@testitem "Aqua" begin
    using Aqua, NonconvexJuniper

    # All Aqua quality gates are enabled. No tests are skipped.
    Aqua.test_all(NonconvexJuniper)
end
