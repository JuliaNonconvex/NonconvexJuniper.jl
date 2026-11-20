# Quick start

Given a model `model` and an initial solution `x0`, the following can be used to optimize the model using Juniper and Ipopt.
```julia
using NonconvexJuniper

alg = JuniperIpoptAlg()
options = JuniperIpoptOptions()
result = optimize(model, alg, x0, options = options)
```
Juniper is a dependency of NonconvexJuniper. Note that the integer constraints must be specified when defining variables. See the [problem definition](../core/models.md) documentation for more details.

## Construct an instance

To construct an instance of the Juniper + Ipopt algorithm, use:
```julia
alg = JuniperIpoptAlg()
```
