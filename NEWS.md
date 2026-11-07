# NEWS

## 0.6.0

- `JuniperIpoptOptions` gains a `mip_solver` keyword holding an MOI
  optimizer constructor (e.g. `Cbc.Optimizer`). When set, it is forwarded to
  Juniper's `mip_solver` attribute.
