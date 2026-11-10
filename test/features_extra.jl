# Additional feature tests for NonconvexJuniper (src/NonconvexJuniper.jl)
# targeting the remaining exported-surface gaps not covered by the main suite
# or coverage_extra.jl: the reexported IpoptAlg/IpoptOptions and the
# positional NamedTuple constructor of JuniperIpoptOptions.

@testitem "reexported IpoptAlg and IpoptOptions" begin
    using NonconvexJuniper, NonconvexCore, LinearAlgebra, Test

    # NonconvexJuniper re-exports IpoptAlg and IpoptOptions from
    # NonconvexIpopt. They must be usable directly through the
    # NonconvexJuniper namespace for continuous problems.
    f(x::AbstractVector) = (x[1] - 1)^2 + (x[2] - 2)^2
    m = Model(f)
    addvar!(m, [0.0, 0.0], [3.0, 3.0])
    alg = IpoptAlg()
    options = IpoptOptions(first_order=true, print_level=0)
    r = NonconvexJuniper.optimize(m, alg, [0.5, 0.5]; options=options)
    @test r.minimizer ≈ [1.0, 2.0] atol = 1e-6
    @test abs(r.minimum) < 1e-6
end

@testitem "JuniperIpoptOptions positional NamedTuple constructor" begin
    using NonconvexJuniper, Test

    # The positional NamedTuple path (used by the keyword forwarding in
    # `Workspace`) must behave like the keyword constructor.
    o = JuniperIpoptOptions((; first_order=false, mip_gap=0.1))
    @test o.first_order === false
    @test o.nt == (mip_gap=0.1,)
    @test o.mip_solver === nothing
    @test o.subsolver_options.nt.hessian_approximation == "exact"

    o2 = JuniperIpoptOptions((; subsolver_options=IpoptOptions(first_order=false)))
    @test o2.first_order === false
    @test o2.nt == NamedTuple()

    o3 = JuniperIpoptOptions((;))
    @test o3.first_order === true
    @test o3.nt == NamedTuple()
    @test o3.mip_solver === nothing
end
