# Additional coverage tests for NonconvexJuniper (src/juniper.jl,
# src/NonconvexJuniper.jl) targeting paths not exercised by the main suite:
# JuniperIpoptOptions keyword branches, the full capability declaration, the
# JuniperIpoptWorkspace constructor and result fields, the JuMP model
# construction branches (ZeroOne vs Integer, subsolver option filtering,
# mip_solver), and the error paths.

@testitem "JuniperIpoptOptions keyword handling" begin
    using NonconvexJuniper, Test

    @testset "defaults" begin
        o = JuniperIpoptOptions()
        @test o.first_order === true
        @test o.mip_solver === nothing
        @test o.nt == NamedTuple()
        # The default subsolver is first order with non-constant Jacobians.
        @test o.subsolver_options.nt.hessian_approximation == "limited-memory"
        @test o.subsolver_options.nt.jac_c_constant == "no"
        @test o.subsolver_options.nt.jac_d_constant == "no"
    end

    @testset "first_order" begin
        o = JuniperIpoptOptions(first_order=false)
        @test o.first_order === false
        @test o.subsolver_options.nt.hessian_approximation == "exact"
        # An explicit first_order=false wins over a conflicting subsolver.
        o = JuniperIpoptOptions(
            first_order=false, subsolver_options=IpoptOptions(first_order=true)
        )
        @test o.first_order === false
        @test o.subsolver_options.nt.hessian_approximation == "limited-memory"
        # Without an explicit first_order, derive it from the subsolver's
        # hessian_approximation.
        @test JuniperIpoptOptions(
            subsolver_options=IpoptOptions(hessian_approximation="exact")
        ).first_order === false
        @test JuniperIpoptOptions(
            subsolver_options=IpoptOptions(hessian_approximation="limited-memory")
        ).first_order === true
        # Subsolver options without a hessian_approximation entry default to
        # first order (the `!hasproperty` branch).
        o = JuniperIpoptOptions(subsolver_options=(nt=(; max_iter=100),))
        @test o.first_order === true
        @test o.subsolver_options.nt.max_iter == 100
    end

    @testset "linear_constraints forwarding" begin
        o = JuniperIpoptOptions(linear_constraints=true)
        @test o.subsolver_options.nt.jac_c_constant == "yes"
        @test o.subsolver_options.nt.jac_d_constant == "yes"
        @test JuniperIpoptOptions(linear_constraints=false).subsolver_options.nt.jac_c_constant ==
            "no"
    end

    @testset "kwargs passthrough to Juniper" begin
        o = JuniperIpoptOptions(mip_gap=0.1, traverse_strategy=:DFS)
        @test o.nt == (mip_gap=0.1, traverse_strategy=:DFS)
        @test o.nt.mip_gap == 0.1
        @test o.nt.traverse_strategy == :DFS
    end
end

@testitem "solver capabilities (every field)" begin
    using NonconvexJuniper, Test

    caps = solver_capabilities(JuniperIpoptAlg())
    @test caps isa ConstraintCapabilities
    @test caps.linear_eq === true
    @test caps.nonlinear_eq === true
    @test caps.linear_ineq === true
    @test caps.nonlinear_ineq === true
    @test caps.linear_sd === false
    @test caps.nonlinear_sd === false
    @test caps.box === true
    @test caps.continuous === true
    @test caps.binary === true
    @test caps.integer === true
    @test caps.infinite_bounds === true
end

@testitem "continuous solve, result fields and workspace construction" begin
    using NonconvexJuniper, NonconvexCore, LinearAlgebra, Test
    import JuMP
    import Cbc
    import Ipopt
    import MathOptInterface as MOI

    alg = JuniperIpoptAlg()
    f(x::AbstractVector) = (x[1] - 1)^2 + (x[2] - 2)^2
    quiet = JuniperIpoptOptions(
        log_levels=[], subsolver_options=IpoptOptions(print_level=0)
    )

    @testset "JuniperIpoptResult fields" begin
        m = Model(f)
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        r = NonconvexJuniper.optimize(m, alg, [0.5, 0.5]; options=quiet)
        @test r isa NonconvexJuniper.JuniperIpoptResult
        @test r.minimizer isa Vector{Float64}
        @test r.minimum isa Float64
        @test r.problem isa NonconvexCore.JuMPProblem
        @test r.fcalls isa Int
        @test r.fcalls > 0
        @test r.status isa Tuple{MOI.TerminationStatusCode,MOI.ResultStatusCode}
        @test r.status[1] in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED)
        @test r.status[2] == MOI.FEASIBLE_POINT
        @test r.minimizer ≈ [1.0, 2.0] atol = 1e-6
        @test abs(r.minimum) < 1e-6
    end

    @testset "workspace construction" begin
        m = Model(f)
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        vecm, x0v, _ = NonconvexCore.tovecmodel(m)
        # Both entry points: the Workspace method (src/juniper.jl) and the
        # JuniperIpoptWorkspace constructor with default options.
        w = NonconvexJuniper.Workspace(vecm, alg, x0v)
        @test w isa NonconvexJuniper.JuniperIpoptWorkspace
        @test w.model === vecm
        @test w.integers isa BitVector
        @test w.integers == [false, false]
        @test w.options isa JuniperIpoptOptions
        @test w.counter isa Base.RefValue{Int}
        @test w.x0 == x0v
        x0v[1] = 123.0
        @test w.x0[1] != 123.0  # the workspace stores a copy of the start point
        # The default-options branch forwards an Ipopt optimizer as nl_solver.
        backend = JuMP.backend(w.problem.model)
        nl = MOI.get(backend, MOI.RawOptimizerAttribute("nl_solver"))
        @test nl isa MOI.OptimizerWithAttributes
        @test MOI.get(backend, MOI.RawOptimizerAttribute("traverse_strategy")) == :BFS
    end

    @testset "mip_solver and Juniper kwargs" begin
        m = Model(f)
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        vecm, x0v, _ = NonconvexCore.tovecmodel(m)
        w = NonconvexJuniper.JuniperIpoptWorkspace(
            vecm,
            x0v;
            options=JuniperIpoptOptions(mip_solver=Cbc.Optimizer, traverse_strategy=:DFS),
        )
        backend = JuMP.backend(w.problem.model)
        @test MOI.get(backend, MOI.RawOptimizerAttribute("mip_solver")) === Cbc.Optimizer
        @test MOI.get(backend, MOI.RawOptimizerAttribute("traverse_strategy")) == :DFS
    end

    @testset "symbolic and sparse are filtered from the subsolver options" begin
        m = Model(f)
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        vecm, x0v, _ = NonconvexCore.tovecmodel(m)
        w = NonconvexJuniper.JuniperIpoptWorkspace(
            vecm,
            x0v;
            options=JuniperIpoptOptions(
                subsolver_options=IpoptOptions(sparse=true, symbolic=true)
            ),
        )
        backend = JuMP.backend(w.problem.model)
        nl = MOI.get(backend, MOI.RawOptimizerAttribute("nl_solver"))
        names = [p.first.name for p in nl.params]
        @test "symbolic" ∉ names
        @test "sparse" ∉ names
        @test "hessian_approximation" in names
    end

    @testset "optimize! resets the call counter" begin
        m = Model(f)
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        vecm, x0v, _ = NonconvexCore.tovecmodel(m)
        w = NonconvexJuniper.JuniperIpoptWorkspace(vecm, x0v; options=quiet)
        w.counter[] = 98765
        r = NonconvexJuniper.optimize!(w)
        @test r isa NonconvexJuniper.JuniperIpoptResult
        @test 0 < r.fcalls < 98765
        @test r.minimizer ≈ [1.0, 2.0] atol = 1e-6
    end
end

@testitem "discrete solves (binary and integer variables)" begin
    using NonconvexJuniper, LinearAlgebra, Test
    import Ipopt
    import MathOptInterface as MOI

    alg = JuniperIpoptAlg()
    quiet = JuniperIpoptOptions(
        log_levels=[], subsolver_options=IpoptOptions(print_level=0)
    )

    @testset "binary variable (ZeroOne constraint branch)" begin
        m = Model(x -> (x[1] - 0.4)^2 + (x[2] - 0.6)^2)
        addvar!(m, 0.0, 1.0; integer=true)
        addvar!(m, 0.0, 1.0)
        r = NonconvexJuniper.optimize(m, alg, [0.3, 0.3]; options=quiet)
        @test r.status[1] in (MOI.OPTIMAL, MOI.LOCALLY_SOLVED)
        @test r.minimizer[1] == 0.0 || r.minimizer[1] == 1.0
        @test r.minimizer[2] ≈ 0.6 atol = 1e-6
        @test abs(r.minimum - 0.16) < 1e-6
    end

    @testset "integer variable with wide bounds (Integer constraint branch)" begin
        m = Model(x -> (x[1] - 1.7)^2)
        addvar!(m, 0.0, 3.0; integer=true)
        r = NonconvexJuniper.optimize(m, alg, [1.5]; options=quiet)
        @test r.minimizer[1] ≈ 2.0 atol = 1e-6
        @test r.minimizer[1] ≈ round(r.minimizer[1]) atol = 1e-7
        @test abs(r.minimum - 0.09) < 1e-6
    end
end

@testitem "error paths" begin
    using NonconvexJuniper, NonconvexCore, Test
    import Ipopt

    alg = JuniperIpoptAlg()

    @testset "start vector length mismatch" begin
        m = Model(x -> sum(abs2, x))
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        @test_throws AssertionError NonconvexJuniper.optimize(m, alg, [1.0])
        vecm, _, _ = NonconvexCore.tovecmodel(m)
        @test_throws AssertionError NonconvexJuniper.Workspace(vecm, alg, [1.0])
    end

    @testset "empty model (zero variables)" begin
        m = Model(x -> sum(abs2, x))
        @test_throws AssertionError NonconvexJuniper.optimize(m, alg, Float64[])
    end

    @testset "invalid subsolver option value" begin
        m = Model(x -> sum(abs2, x))
        addvar!(m, [0.0, 0.0], [3.0, 3.0])
        options = JuniperIpoptOptions(
            log_levels=[],
            subsolver_options=IpoptOptions(print_level=0, max_iter=:not_an_int),
        )
        # Ipopt rejects the wrongly typed option at optimize! time.
        @test_throws ErrorException NonconvexJuniper.optimize(
            m, alg, [1.0, 1.0]; options=options
        )
    end

    @testset "non-finite objective at the start point" begin
        m = Model(x -> sqrt(max(x[2], 0.0)))
        addvar!(m, [0.0, 0.0], [10.0, 10.0]; init=[NaN, NaN])
        err = try
            NonconvexJuniper.optimize(m, alg)
            nothing
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("non-finite value", sprint(showerror, err))
        @test occursin("objective", sprint(showerror, err))
    end

    @testset "non-finite DictModel objective at the start point" begin
        dm = DictModel(d -> 1 / d[:x])
        addvar!(dm, :x, 0.0, 1.0)
        @test_throws ErrorException NonconvexJuniper.optimize(dm, alg)
    end

    @testset "non-finite DictModel constraint at the start point" begin
        dm = DictModel(d -> d[:x])
        addvar!(dm, :x, 0.0, 1.0)
        add_ineq_constraint!(dm, d -> 1 / d[:x])
        err = try
            NonconvexJuniper.optimize(dm, alg)
            nothing
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("inequality constraint #1", sprint(showerror, err))
    end

    @testset "semidefinite constraints are rejected by the capabilities" begin
        m = Model(x -> sum(abs2, x))
        addvar!(m, 0.0, 1.0)
        add_sd_constraint!(m, x -> [x[1] + 1.0;;])
        err = try
            NonconvexJuniper.optimize(m, alg, [0.5])
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("semidefinite", sprint(showerror, err))
        @test occursin("JuniperIpoptAlg", sprint(showerror, err))
    end
end

@testitem "no explicit start point (getinit default and fallback)" begin
    using NonconvexJuniper, NonconvexCore, Test

    # `JuniperIpoptWorkspace(model; ...)` defaults `x0` to
    # `NonconvexCore.getinit(model)` when no start point is given.
    alg = JuniperIpoptAlg()
    m = Model(x -> sum(abs2, x .- [1.0, 2.0]))
    addvar!(m, [0.0, 0.0], [3.0, 3.0]; init=[0.5, 0.5])
    r = NonconvexJuniper.optimize(m, alg)
    @test r.minimizer ≈ [1.0, 2.0] atol = 1e-6
    @test abs(r.minimum) < 1e-6

    # The workspace stores the start point derived by `getinit`, including the
    # midpoint fallback for non-finite initial values.
    m2 = Model(x -> sum(abs2, x))
    addvar!(m2, [0.0, 0.0], [10.0, 10.0]; init=[0.5, 0.5])
    vecm, x0v, _ = NonconvexCore.tovecmodel(m2)
    @test x0v == [0.5, 0.5]
    vecm.init .= NaN
    w = NonconvexJuniper.JuniperIpoptWorkspace(vecm)
    @test w.x0 == [5.0, 5.0]
end
