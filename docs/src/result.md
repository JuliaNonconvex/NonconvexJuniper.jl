# Result

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
