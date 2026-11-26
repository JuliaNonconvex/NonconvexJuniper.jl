# NEWS

## 0.6.6

- Allow NonconvexIpopt 0.9 (the previous compat pinned it below 0.9, forcing co-resolved environments onto the outdated 0.8.x line).

## 0.6.5

- Docs: the logo now appears only in the sidebar, not in the page body.
## 0.6.4

- Docs: package-name section titles and left-aligned logos (no code changes).
## 0.6.3

- Added docstrings for `JuniperIpoptAlg` and `JuniperIpoptOptions` (REPL help and API reference).


## 0.6.2

- Infeasible terminations without an incumbent return a NaN-filled
  result instead of throwing an opaque MOI exception.

## 0.6.0

- `JuniperIpoptOptions` gains a `mip_solver` keyword holding an MOI
  optimizer constructor (e.g. `Cbc.Optimizer`). When set, it is forwarded to
  Juniper's `mip_solver` attribute.
