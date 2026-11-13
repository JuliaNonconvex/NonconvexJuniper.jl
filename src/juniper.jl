function _warn_callback_ignored()
    @warn "The `callback` keyword is not supported by NonconvexJuniper and will be ignored."
    return nothing
end
_warn_callback_ignored(nt::NamedTuple) = haskey(nt, :callback) && _warn_callback_ignored()

@params struct JuniperIpoptOptions
    nt::NamedTuple
    subsolver_options::Any
    first_order::Bool
    mip_solver::Any
end
function JuniperIpoptOptions(;
    first_order=nothing,
    linear_constraints=false,
    mip_solver=nothing,
    subsolver_options=IpoptOptions(;
        first_order=first_order === nothing ? true : first_order,
        linear_constraints=linear_constraints,
    ),
    kwargs...,
)
    return _juniper_ipopt_options((;
        first_order, linear_constraints, mip_solver, subsolver_options, kwargs...
    ))
end
# A positional-NamedTuple path: JET (on Julia 1.13) cannot resolve
# `Core.kwcall` on `Base.Pairs` forwarding during its virtual top-level
# replay, so forwarded options go through this positional method.
function JuniperIpoptOptions(nt::NamedTuple)
    return _juniper_ipopt_options(nt)
end
function _juniper_ipopt_options(nt::NamedTuple)
    first_order = get(nt, :first_order, nothing)
    linear_constraints = get(nt, :linear_constraints, false)
    mip_solver = get(nt, :mip_solver, nothing)
    subsolver_options = get(
        nt,
        :subsolver_options,
        IpoptOptions(;
            first_order=first_order === nothing ? true : first_order,
            linear_constraints=linear_constraints,
        ),
    )
    # Only derive first_order from the subsolver options when it was not given
    # explicitly; an explicit first_order now always wins over a conflicting
    # hessian_approximation in subsolver_options.
    first_order = if first_order === nothing
        (
            !hasproperty(subsolver_options.nt, :hessian_approximation) ||
            subsolver_options.nt.hessian_approximation == "limited-memory"
        )
    else
        first_order
    end
    known = (:first_order, :linear_constraints, :mip_solver, :subsolver_options)
    rest = [k for k in keys(nt) if k ∉ known]
    return JuniperIpoptOptions(nt[Tuple(rest)], subsolver_options, first_order, mip_solver)
end

@params mutable struct JuniperIpoptWorkspace <: Workspace
    model::VecModel
    problem::JuMPProblem
    x0::AbstractVector
    integers::AbstractVector{<:Bool}
    options::JuniperIpoptOptions
    counter::Base.RefValue{Int}
end
function JuniperIpoptWorkspace(
    model::VecModel,
    x0::AbstractVector=NonconvexCore.getinit(model);
    options=JuniperIpoptOptions(),
    kwargs...,
)
    haskey(kwargs, :callback) && _warn_callback_ignored()
    ks = Tuple(k for k in keys(kwargs) if k !== :callback)
    rest = kwargs[ks]
    merged = isempty(rest) ? options : _juniper_merge_options(options, rest)
    return _juniper_ipopt_workspace(model, x0, merged)
end
# A positional-NamedTuple path: JET (on Julia 1.13) cannot resolve
# `Core.kwcall` on `Base.Pairs` forwarding during its virtual top-level
# replay, so forwarded options go through this positional method.
function JuniperIpoptWorkspace(model::VecModel, x0::AbstractVector, nt::NamedTuple)
    _warn_callback_ignored(nt)
    ks = Tuple(k for k in keys(nt) if k !== :callback)
    opt_nt = nt[ks]
    options = if haskey(opt_nt, :options)
        rest = (; (k => v for (k, v) in pairs(opt_nt) if k !== :options)...)
        if isempty(rest)
            opt_nt[:options]
        else
            _juniper_merge_options(opt_nt[:options], rest)
        end
    else
        # Forward direct option kwargs (e.g. `first_order`) to the options
        # constructor instead of silently dropping them; `callback` is
        # handled above.
        JuniperIpoptOptions(opt_nt)
    end
    return _juniper_ipopt_workspace(model, x0, options)
end
# Direct keyword arguments take precedence over an explicitly passed
# `options` object.
function _juniper_merge_options(options::JuniperIpoptOptions, rest::NamedTuple)
    base = (;
        options.nt...,
        first_order=options.first_order,
        mip_solver=options.mip_solver,
        subsolver_options=options.subsolver_options,
    )
    return JuniperIpoptOptions(; base..., rest...)
end
function _juniper_ipopt_workspace(
    model::VecModel, x0::AbstractVector, options::JuniperIpoptOptions
)
    integers = model.integer
    @assert length(integers) == length(x0)
    nt1 = options.subsolver_options.nt
    ks = setdiff(keys(nt1), (:symbolic, :sparse))
    subsolver_options = Dict{String,Any}(string(k) => nt1[k] for k in ks)
    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, subsolver_options...)
    nt2 = options.nt
    solver_options = Dict{String,Any}(string(k) => nt2[k] for k in keys(nt2))
    options.mip_solver === nothing || (solver_options["mip_solver"] = options.mip_solver)
    optimizer = JuMP.optimizer_with_attributes(
        Juniper.Optimizer, "nl_solver" => nl_solver, solver_options...
    )
    objective = NonconvexCore.getobjective(model)
    objective === nothing && throw(ArgumentError("The model has no objective."))
    ineq = isempty(model.ineq_constraints.fs) ? nothing : model.ineq_constraints
    eq = isempty(model.eq_constraints.fs) ? nothing : model.eq_constraints
    obj = NonconvexCore.CountingFunction(objective)
    problem = NonconvexCore.get_jump_problem(
        obj,
        ineq,
        eq,
        copy(x0),
        integers,
        NonconvexCore.getmin(model),
        NonconvexCore.getmax(model),
        options.first_order,
        optimizer,
        NonconvexCore.DEFAULT_AD_BACKEND[],
    )
    return JuniperIpoptWorkspace(model, problem, copy(x0), integers, options, obj.counter)
end
@params struct JuniperIpoptResult <: AbstractResult
    minimizer::Any
    minimum::Any
    problem::Any
    status::Any
    fcalls::Int
end

function optimize!(workspace::JuniperIpoptWorkspace)
    @unpack problem, options, x0, counter = workspace
    counter[] = 0
    jump_problem = workspace.problem
    jump_model = jump_problem.model
    moi_model = JuMP.backend(jump_model)
    MOI.set.(Ref(moi_model), Ref(MOI.VariablePrimalStart()), workspace.problem.vars, x0)
    MOI.optimize!(moi_model)
    minimizer = MOI.get(moi_model, MOI.VariablePrimal(), jump_problem.vars)
    objval = MOI.get(moi_model, MOI.ObjectiveValue())
    term_status = MOI.get(moi_model, MOI.TerminationStatus())
    primal_status = MOI.get(moi_model, MOI.PrimalStatus())
    return JuniperIpoptResult(
        minimizer, objval, problem, (term_status, primal_status), counter[]
    )
end

struct JuniperIpoptAlg <: AbstractOptimizer end

function NonconvexCore.solver_capabilities(::JuniperIpoptAlg)
    return ConstraintCapabilities(;
        linear_eq=true,
        nonlinear_eq=true,
        linear_ineq=true,
        nonlinear_ineq=true,
        linear_sd=false,
        nonlinear_sd=false,
        box=true,
        continuous=true,
        binary=true,
        integer=true,
        infinite_bounds=true,
    )
end

function Workspace(
    model::VecModel, optimizer::JuniperIpoptAlg, x0::AbstractVector; kwargs...
)
    return JuniperIpoptWorkspace(model, x0, (; kwargs...))
end

# Without an explicit start point, default to the model's initial values.
function Workspace(model::VecModel, optimizer::JuniperIpoptAlg; kwargs...)
    return JuniperIpoptWorkspace(model, NonconvexCore.getinit(model), (; kwargs...))
end
