using Spikes
using DataFrames
using Plots
using StatPlots
using RDatasets
using Query
using Formatting

"""
hoverLabels(x::Number, y::Number)

Generates a vector of strings for the hover labels for when the user hovers over the chart

# Arguments
* `x::Array{Float64,1}`: The x-values in the plot
* `y::Array{Float64,1}`: The y-values in the plot
* `name::String`: The (optional) name of the series

# Return
An `Array{String}` holding label strings for the series
"""
function hoverLabels(x::Array{Float64,1}, y::Array{Float64,1}, name::String = "")
    map(p -> "($(sprintf1("%'d", p[1])) ms, $(sprintf1("%5.3f", p[2]))) [$(name)]", zip(x, y))
end


"""
plotSeries(x::Array{Float64,1}, y::Array{Float64,1}, p::Plots.Plot; name = "")

Adds the (x, y)-pair series to the plot and returns the updated plot

# Arguments
* `x::Array{Float64,1}`: The x-values in the plot
* `y::Array{Float64,1}`: The y-values in the plot
* `p::Plots.Plot`: The plot to which to add the series
* `name::String`: The (optional) name of the series

# Returns
A `Plots.Plot`
"""
function addSeriesToPlot(x::Array{Float64,1}, y::Array{Float64,1}, p::Plots.Plot; name = "")
    plot!(p, x, y, label=name, hover=hoverLabels(x, y, name))
end

# """
# plotMembranePotential(dataFrame::DataFrame, series::Int)

# Plots the membrane potential for the optionally specified series

# # Arguments
# * `dataFrame::DataFrame`: The data frame holding the membrane potential events
# * `series::Int = 1`: The optional series number
# """
# function plotMembranePotential(dataFrame::DataFrame, series::Int=-1)
#     lines = scatter(dataFrame, group=:neuron_id, x=:signal_time, y=:potential)
#     plot(lines,
#         Layout(title="Membrane Potential$(series >= 0 ? " - series: $series" : "")",
#             xaxis=attr(title="t (ms)", showgrid=true),
#             yaxis=attr(title="U (mV)", showgrid=true)
#         )
#     )
# end


function plotSeriesFrom(series::Dict{Integer, DataFrame}, plotFunction::Function)
    [plotFunction(entry[2], entry[1]) for entry in series]
end
