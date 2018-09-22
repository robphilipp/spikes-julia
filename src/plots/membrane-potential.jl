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
