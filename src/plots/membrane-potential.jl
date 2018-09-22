include("plots.jl")

"""
plotMembranePotential(dataFrame, series, xaxis, yaxis)

A scatter plot of the neuron's membrane potential as a function of time. The
plot has a trace for each neuron in the network.

# Arguments
* `dataFrame::DataFrame`: The data-frame holding the log weight-update events
* `series::Int`: (Optional) The series number
* `xaxis::String`: (Optional) The id for the x-axis
* `yaxis::String`:(Optional) The id for the y-axis

# Returns
A `Plots.plot`
"""
function plotMembranePotential(
    dataFrame::DataFrame;
    series::Int=-1, 
    xaxis::String="t (ms)", 
    yaxis::String="u(t) (mV)", 
    title::String="membrane potential"
)::Plots.Plot
    if size(dataFrame)[1] == 0
        return "No update data available to plot; please ensure that you are logging update data"
    end

    # make a copy of the data frame
    potentials = DataFrame(dataFrame)

    # group by the connections to get an array of dataframes, each holding the time-series
    # of data
    potentialSeries = groupby(potentials, [:neuron_id], sort = true)

    # now plot each one
    seriesPlot = plot(
        title=title,
        titlefont=font(8),
        titleloc=series > 0 ? :right : :center,
        xlabel=xaxis,
        ylabel=yaxis
    );
    i = 1
    for series in potentialSeries
        seriesPlot = addSeriesToPlot(
            series[:signal_time], 
            series[:potential], 
            seriesPlot, 
            name=series[:neuron_id][i]
        )
        i += 1
    end
    seriesPlot
end

"""
plotMembranePotentialSeries(dataFrames, colors, numCols)

Creates a page of connection-weight time-series subplots, one for each run (series).
Provides a convenient way to compare the weight time-series from a series of runs.

# Arguments
* `dataFrames::Dict{Integer, DataFrame}`: A dictionary holding the series-number -> DataFrame
* `colors::Array{String}`: (Optional) An array of colors to cycle through when assigning the traces.
    For optimal result, ensure that you have one color for each of the trace that appear in an
    individual subplot.
* `numCols::Int`: (Optional) The number of columns for the plot page
"""
function plotMembranePotentialSeries(
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
        scatters = plotMembranePotential(
            dataFrame,
            series = index,
            xaxis = index > length(dataFrames) - numCols ? "t (ms)" : "", 
            yaxis = index % numCols == 1 ? "u(t) (mV)" : "",
            title = "$(index >= 0 ? "($index)" : "Membrane Potential")"
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
