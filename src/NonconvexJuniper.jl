module NonconvexJuniper

export JuniperIpoptAlg, JuniperIpoptOptions, IpoptAlg, IpoptOptions

import JuMP, Ipopt, MathOptInterface
const MOI = MathOptInterface
using Reexport, Parameters, SparseArrays, Zygote
@reexport using NonconvexCore, NonconvexIpopt
using NonconvexCore: @params, VecModel, AbstractResult, JuMPProblem
using NonconvexCore: AbstractOptimizer, get_jump_problem, nvalues
import NonconvexCore: optimize!
using Juniper

include("juniper.jl")

end
