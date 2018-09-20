module Spikes

# spikes-files.jl
export loadLogfile, loadLogFileSeries

# spikes-math.jl
export heaviside, sigmoid

# parsing.jl
export networkInfo, networkTopology, connectionTopology
export signalEvents, intrinsicPlasticityEvents, learningEvents, membranePotentialUpdateEvents, spikeEvents

include("spikes-files.jl")
include("spikes-math.jl")
include("coordinates.jl")
include("connections.jl")
include("parsing.jl")
include("learning.jl")
include("plots.jl")

# end of module Spikes
end