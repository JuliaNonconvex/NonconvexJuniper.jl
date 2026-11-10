# First and second order mixed integer nonlinear programming algorithms

## Description

There are 2 first and second order MINLP solvers available in `Nonconvex`:
1. [Juniper.jl](https://github.com/lanl-ansi/Juniper.jl) with [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) as a sub-solver. `NonconvexJuniper.jl` allows the use of the branch and bound algorithm in `Juniper.jl` using the `JuniperIpoptAlg` struct.
2. [Pavito.jl](https://github.com/jump-dev/Pavito.jl) with [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) and [Cbc.jl](https://github.com/jump-dev/Cbc.jl) as sub-solvers. `NonconvexPavito.jl` allows the use of the sequential polyhedral outer-approximations algorithm in `Pavito.jl` using the `PavitoIpoptCbcAlg` struct.

## Juniper + Ipopt

### Quick start

Given a model `model` and an initial solution `x0`, the following can be used to optimize the model using Juniper and Ipopt.
```julia
using NonconvexJuniper

alg = JuniperIpoptAlg()
options = JuniperIpoptOptions()
result = optimize(model, alg, x0, options = options)
```
Juniper is a dependency of NonconvexJuniper. Note that the integer constraints must be specified when defining variables. See the [problem definition](../core/models.md) documentation for more details.

### Construct an instance

To construct an instance of the Juniper + Ipopt algorithm, use:
```julia
alg = JuniperIpoptAlg()
```

### Options

The options keyword argument to the `optimize` function shown above must be an instance of the `JuniperIpoptOptions` struct when the algorihm is a `JuniperIpoptAlg`. To specify options use, keyword arguments in the constructor of `JuniperIpoptOptions`, e.g:
```julia
options = JuniperIpoptOptions(first_order = false, linear_constraints = true, subsolver_options = IpoptOptions(), atol = 1e-4)
```
There are 4 important and special options you can pass to the optimizer:
- `first_order`: `true` by default. When `first_order` is `true`, the first order Ipopt algorithm will be used. And when it is `false`, the second order Ipopt algorithm will be used.
- `linear_constraints`: `false` by default. When `linear_constraints` is `true`, the Jacobian of the constraints will be computed and sparsified once at the beginning. When it is `false`, dense Jacobians will be computed in every iteration.
- `subsolver_options`: an instance of `IpoptOptions` to be used in the Ipopt sub-solver.
- `mip_solver`: `nothing` by default. When set, this selects the mixed integer programming (MIP) sub-solver used by Juniper for the branch and bound algorithm, e.g. `mip_solver = Cbc.Optimizer`:
```julia
options = JuniperIpoptOptions(mip_solver = Cbc.Optimizer)
```

All the other options to Juniper can be found in the [Juniper documentation](https://lanl-ansi.github.io/Juniper.jl/stable/options/).

### Results

The result of `optimize` is an `AbstractResult` with the following fields:
- `minimizer`: the solution found.
- `minimum`: the objective value at the solution found.
- `status`: a tuple of the MOI termination and primal statuses, e.g. `(MOI.OPTIMAL, MOI.FEASIBLE_POINT)`.
- `fcalls`: the number of objective function calls.

For example:
```julia
r = optimize(model, alg, x0, options = options)
r.minimizer
r.minimum
r.status
r.fcalls
```

## Ipopt + IpoptOptions

`NonconvexJuniper` re-exports `IpoptAlg` and `IpoptOptions` from `NonconvexIpopt`. These can be used directly, e.g. when solving continuous problems without the mixed integer branch and bound algorithm, or to construct the `subsolver_options` of `JuniperIpoptOptions`:
```julia
using NonconvexJuniper

alg = IpoptAlg()
options = IpoptOptions(first_order = false, tol = 1e-4)
result = optimize(model, alg, x0, options = options)
```
See the NonconvexIpopt documentation for the full list of options.

