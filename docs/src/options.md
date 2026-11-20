# Options

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

## Ipopt + IpoptOptions

`NonconvexJuniper` re-exports `IpoptAlg` and `IpoptOptions` from `NonconvexIpopt`. These can be used directly, e.g. when solving continuous problems without the mixed integer branch and bound algorithm, or to construct the `subsolver_options` of `JuniperIpoptOptions`:
```julia
using NonconvexJuniper

alg = IpoptAlg()
options = IpoptOptions(first_order = false, tol = 1e-4)
result = optimize(model, alg, x0, options = options)
```
See the NonconvexIpopt documentation for the full list of options.
