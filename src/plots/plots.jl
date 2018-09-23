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

"""
plotSeries(
    dataFrames::Dict{Integer, DataFrame}, 
    plotFunction::Function;
    numCols::Int = 2,
    xAxisLabel::String = "t (ms)",
    yAxisLabel::String = "",
    title::String = ""
)

Creates a page of time-series subplots, one for each run (series), created by calling 
the specified plot function. Provides a convenient way to compare the weight time-series 
from a series of runs.

# Arguments
* `dataFrames::Dict{Integer, DataFrame}`: A dictionary holding the series-number -> DataFrame
* `plotFunction::Function`: A function that accepts a DataFrame, the series index, the
        label for the x-axis, the label for the y-axis, and the plot title
* `numCols::Int`: Optional name parameter the specifies the number of subplot columns. The
        default value is 2 columns.
* `functionArgs`: The optional arguments that need to passed to the function
"""
function plotSeries(
    dataFrames::Dict{Integer, DataFrame},
    plotFunction::Function;
    numCols::Int = 2,
    functionArgs...
)

    numRows::Int = ceil(length(dataFrames) / numCols)

    # function to update the name of the series by prepending the series number
    updateName = (scat, seriesNumber::Int) -> begin
        scat[:name] = "s$(seriesNumber): $(scat[:name])"
        scat
    end

    # grab the number of subplots (i.e. the number of runs in the simulation series)
    numSeries::Int = length(dataFrames)
    
    numTracesPerPlot::Int = 1
    plots = []
    for entry in sort(collect(dataFrames), by = key -> key[1])
        index = entry[1]
        dataFrame = entry[2]

        # pull out the arguments that are defined
        args = xLabel(functionArgs, index, numSeries, numCols)
        args = yLabel(args, index, numCols)
        args = title(args, index)

        # create the axis identifiers. The first plot gets the largest y-axis id
        # so that the first dataframe in the series is the first plot at the top
        # left-hand side of the page
        scatters = plotFunction(dataFrame, series = index; args...)

        # keep track of the number of traces per subplot for selecting col
        numTracesPerPlot = max(numTracesPerPlot, length(scatters))

        # add the traces from the scatter plot
        push!(plots, scatters)
    end

    # create and return the plot
    plot(
        plots...,
        layout=(numRows, numCols),
        legend=false,
        size=(600 * numCols, 300 * numRows)
    )
end


"""
xLabel(args, index, numSeries, numCols)

Private method for creating the x-axis label based on the subplot number
and whether or not the xLabel was passed into the plotSeries(...) function.

# Arguments
* `args::Union{Base.Iterators.Pairs{}, NamedTuple{}}`: The function arguments 
    passed into the plotSeries(...) function
* `index::Int`: The current subplot number
* `numSeries::Int`: The number of simulations (series) in the plot
* `numCols::Int`: The number of columns in the plot figure

# Returns
The enriched function arguments passed to the plotSeries(...) function
"""
function xLabel(
    args::Union{Base.Iterators.Pairs{}, NamedTuple{}}, 
    index::Int, numSeries::Int, 
    numCols::Int
    )
    if haskey(args, :xLabel)
        label = index > numSeries - numCols ? args[:xLabel] : ""
        return (args..., xLabel=label)
    end
    return index > numSeries - numCols ? args : (args..., xLabel="")
end

"""
yLabel(args, index, numCols)

Private method for creating the y-axis label based on the subplot number
and whether or not the yLabel was passed into the plotSeries(...) function.

# Arguments
* `args::Union{Base.Iterators.Pairs{}, NamedTuple{}}`: The function arguments
     passed into the plotSeries(...) function
* `index::Int`: The current subplot number
* `numCols::Int`: The number of columns in the plot figure

# Returns
The enriched function arguments passed to the plotSeries(...) function
"""
function yLabel(
    args::Union{Base.Iterators.Pairs{}, NamedTuple{}}, 
    index::Int, 
    numCols::Int
    )
    if haskey(args, :yLabel)
        label = index % numCols == 1 ? args[:yLabel] : ""
        return (args..., yLabel=label)
    end
    return index % numCols == 1 ? args : (args..., yLabel="")
end

"""
title(args, index)

Private method for creating the subplot title based on the subplot number
and whether or not the title was passed into the plotSeries(...) function.

# Arguments
* `args::Union{Base.Iterators.Pairs{}, NamedTuple{}}`: The function arguments 
    passed into the plotSeries(...) function
* `index::Int`: The current subplot number

# Returns
The enriched function arguments passed to the plotSeries(...) function
"""
function title(
    args::Union{Base.Iterators.Pairs{}, NamedTuple{}}, 
    index::Int
    )
    if haskey(args, :title)
        title = index >= 0 ? "($index)   " : args[:title]
        return (args..., title=title)
    end
    return index >= 0 ? (args..., title="($index)   ") : args
end