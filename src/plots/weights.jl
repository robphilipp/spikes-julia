include("plots.jl")

"""
plotWeights(dataFrame, series, xaxis, yaxis)

A scatter plot of the connection weights as a function of 
time for all the connections in the network.

# Arguments
* `dataFrame::DataFrame`: The data-frame holding the log weight-update events
* `series::Int`: (Optional) The series number
* `xaxis::String`: (Optional) The id for the x-axis
* `yaxis::String`:(Optional) The id for the y-axis

# Returns
A `Plots.plot`
"""
function plotWeights(
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
            name=series[:connection][i]
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
        scatters = plotWeights(
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
        legend=false,
        size=(600 * numCols, 300 * numRows)
    )
end
