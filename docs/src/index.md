# NonconvexJuniper

![JuliaNonconvex logo](https://raw.githubusercontent.com/JuliaNonconvex/NonconvexJuniper.jl/master/docs/src/assets/logo.png)

## Description

There are 2 first and second order MINLP solvers available in `Nonconvex`:
1. [Juniper.jl](https://github.com/lanl-ansi/Juniper.jl) with [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) as a sub-solver. `NonconvexJuniper.jl` allows the use of the branch and bound algorithm in `Juniper.jl` using the `JuniperIpoptAlg` struct.
2. [Pavito.jl](https://github.com/jump-dev/Pavito.jl) with [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) and [Cbc.jl](https://github.com/jump-dev/Cbc.jl) as sub-solvers. `NonconvexPavito.jl` allows the use of the sequential polyhedral outer-approximations algorithm in `Pavito.jl` using the `PavitoIpoptCbcAlg` struct.

See [Quick start](quickstart.md) for the first steps, [Options](options.md) for the algorithm options, [Solver capabilities](capabilities.md) for the model features supported by `JuniperIpoptAlg`, [Result](result.md) for the fields of the returned result and [Docstrings](docstrings.md) for the full API reference.
