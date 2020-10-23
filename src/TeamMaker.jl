module TeamMaker

using DataFrames, CSV, CategoricalArrays
using Statistics, StatsBase
using Random

export TeamEvaluators, TeamRequirements, test, readStats, genericEvaluate, joinScores

include("StatReader.jl")
include("TeamRules.jl")
include("TeamImprovement.jl")
include("Tester.jl")

end # module
