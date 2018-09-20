using Spikes
using DataFrames
using Plots: plot, scatter
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
plotWeights(learnDataFrame, connections:Array{String}, titleString:String )

Plots the time-series of weights from the `learnDataFrame` that are listed in the
`connections` array. Each tuple in the array will generate a line in the plot,
for the time-dependent weight for the connection from to the pre-synaptic neuron
to the post-synaptic neuron.

# Argurments
* `dataFrame::DataFrame`: holds the learning data (weights, update times, etc)
* `connections::Array{Tuple{String,String}}`: An array of tuples holding the pre-synaptic ID
    and the post-synaptic ID as the first and second elements of the tuple, respectively
* `titleString:String`: a string that should be added to the title
"""
function plotWeights(dataFrame::DataFrame, series::Int=-1)
    weightScatter(dataFrame, series, "t (ms)", "w(t)", "$(series >= 0 ? "($series)" : "Weights")")
end

"""
weightScatter(dataFrame, series, xaxis, yaxis)

Generates an array of traces that represent one subplot. The method is used by
the `plotWeightSeries(...)` function.

# Arguments
* `dataFrame::DataFrame`: The data-frame holding the log weight-update events
* `series::Int`: (Optional) The series number
* `xaxis::String`: (Optional) The id for the x-axis
* `yaxis::String`:(Optional) The id for the y-axis

# Returns
A `Plots.plot`
"""
function weightScatter(
    dataFrame::DataFrame;
    series::Int=-1, 
    xaxis::String="t (ms)", 
    yaxis::String="w(t)", 
    title::String="weights"
)::Plots.Plot
    if size(dataFrame)[1] == 0
        return "No learning data available to plot; please ensure that you are logging learning data"
    end

    # make a copy of the data frame
    weights = DataFrame(dataFrame)

    # add the connection column (i.e. pre-synaptic -> post-synaptic)
    weights[:connection] = map((pre, post) -> "$(pre), $(post)", weights[:pre_synaptic], weights[:post_synaptic])

    # group by the connections to get an array of dataframes, each holding the time-series
    # of data
    weightSeries = groupby(weights, [:connection], sort = true)

    # now plot each one
    seriesPlot = plot(
        title=title,
        titlefont=font(8),
        titleloc=series > 0 ? :right : :center,
        xlabel=xaxis,
        ylabel=yaxis
    );
    i = 1
    for series in weightSeries
        seriesPlot = addSeriesToPlot(
            series[:signal_time], 
            series[:new_weight], 
            seriesPlot, 
            name=series[:connection][1]
        )
        i += 1
    end
    seriesPlot
end

"""
plotWeightSeries(dataFrames, colors, numCols)

Creates a page of connection-weight time-series subplots, one for each run (series).
Provides a convenient way to compare the weight time-series from a series of runs.

# Arguments
* `dataFrames::Dict{Integer, DataFrame}`: A dictionary holding the series-number -> DataFrame
* `colors::Array{String}`: (Optional) An array of colors to cycle through when assigning the traces.
    For optimal result, ensure that you have one color for each of the trace that appear in an
    individual subplot.
* `numCols::Int`: (Optional) The number of columns for the plot page
"""
function plotWeightSeries(
    dataFrames::Dict{Integer, DataFrame};
    numCols::Int = 2
)

    numRows::Int = ceil(length(dataFrames) / numCols)

    # function to update the name of the series by prepending the series number
    updateName = (scat, seriesNumber::Int) -> begin
        scat[:name] = "s$(seriesNumber): $(scat[:name])"
        scat
    end

    numTracesPerPlot::Int = 1
    plots = []
    for entry in sort(collect(dataFrames), by = key -> key[1])
        index = entry[1]
        dataFrame = entry[2]

        # create the axis identifiers. The first plot gets the largest y-axis id
        # so that the first dataframe in the series is the first plot at the top
        # left-hand side of the page
        scatters = weightScatter(
            dataFrame,
            series = index,
            xaxis = index > length(dataFrames) - numCols ? "t (ms)" : "", 
            yaxis = index % numCols == 1 ? "w(t)" : "",
            title = "$(index >= 0 ? "($index)" : "Weights")"
        )

        # keep track of the number of traces per subplot for selecting col
        numTracesPerPlot = max(numTracesPerPlot, length(scatters))

        # add the traces from the scatter plot
        push!(plots, scatters)
    end

    # create and return the plot
    # plot(vcat(plots...), style=style)
    plot(
        plots...,
        layout=(numRows, numCols),
        #layout=length(dataFrames),
        legend=false,
        size=(600 * numCols, 300 * numRows)
    )
end

"""
plotMembranePotential(dataFrame::DataFrame, series::Int)

Plots the membrane potential for the optionally specified series

# Arguments
* `dataFrame::DataFrame`: The data frame holding the membrane potential events
* `series::Int = 1`: The optional series number
"""
function plotMembranePotential(dataFrame::DataFrame, series::Int=-1)
    lines = scatter(dataFrame, group=:neuron_id, x=:signal_time, y=:potential)
    plot(lines,
        Layout(title="Membrane Potential$(series >= 0 ? " - series: $series" : "")",
            xaxis=attr(title="t (ms)", showgrid=true),
            yaxis=attr(title="U (mV)", showgrid=true)
        )
    )
end


function plotSeriesFrom(series::Dict{Integer, DataFrame}, plotFunction::Function)
    [plotFunction(entry[2], entry[1]) for entry in series]
end
