<p align="center">
  <img src="assets/logo.png" width="400" alt="NonconvexJuniper.jl logo">
</p>

[![Documentation (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://julianonconvex.github.io/NonconvexJuniper.jl/stable)
[![Documentation (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://julianonconvex.github.io/NonconvexJuniper.jl/dev)
[![Build Status](https://github.com/JuliaNonconvex/NonconvexJuniper.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaNonconvex/NonconvexJuniper.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaNonconvex/NonconvexJuniper.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaNonconvex/NonconvexJuniper.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-Blue-4473c9.svg)](https://github.com/invenia/BlueStyle)
[![JET](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

# NonconvexJuniper.jl

Mixed-integer nonlinear programming with Juniper.jl

Branch and bound MINLP with Ipopt as the continuous sub-solver.

NonconvexJuniper.jl is part of the [JuliaNonconvex](https://github.com/JuliaNonconvex) ecosystem built on [NonconvexCore.jl](https://github.com/JuliaNonconvex/NonconvexCore.jl) under the [Nonconvex.jl](https://github.com/JuliaNonconvex/Nonconvex.jl) umbrella.

## Quick start

```julia
using NonconvexJuniper

alg = JuniperIpoptAlg()
options = JuniperIpoptOptions()
result = optimize(model, alg, x0, options = options)
```

## Documentation

The full documentation is available at [https://julianonconvex.github.io/NonconvexJuniper.jl/stable](https://julianonconvex.github.io/NonconvexJuniper.jl/stable) (stable) and [https://julianonconvex.github.io/NonconvexJuniper.jl/dev](https://julianonconvex.github.io/NonconvexJuniper.jl/dev) (development).

## Installation

```julia
using Pkg
Pkg.add("NonconvexJuniper")
```
