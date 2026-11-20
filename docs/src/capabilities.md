# Solver capabilities

[`JuniperIpoptAlg`](@ref) declares its capabilities through `solver_capabilities`:

- `linear_eq = true`, `nonlinear_eq = true`: equality constraints of any linearity,
- `linear_ineq = true`, `nonlinear_ineq = true`,
- `box = true`,
- `continuous = true`, `binary = true`, `integer = true`: mixed integer problems are the primary use case,
- `infinite_bounds = true`,
- semidefinite constraints (`linear_sd`, `nonlinear_sd`) are **not** supported.

The declaration is checked against the model via `checksubproblem!` before the solve, so unsupported model features are caught early.
