using Spikes
# include("coordinates.jl")

"""
Represents the information about a connection between 2 neurons--the 
pre-synaptic and the post-synaptic

# Elements
* `preSynapticId::String`: the ID of the pre-synaptic neuron
* `preSynaptic::Coordinate`: the coordinate of the pre-synaptic neuron
* `postSynapticId::String`: the ID of the post-synaptic neuron
* `postynaptic::Coordinate`: the coordinate of the post-synaptic neuron
* `weight::Real`: the weight of the connection
"""
struct Connection
    "the ID of the pre-synaptic neuron"
    preSynapticId::String
    "the coordinate of the pre-synaptic neuron"
    preSynaptic::Coordinate
    "the ID of the post-synaptic neuron"
    postSynapticId::String
    "the coordinate of the post-synaptic neuron"
    postSynaptic::Coordinate
    "the weight of the connection"
    weight::Real
end
