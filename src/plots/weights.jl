include("plots.jl")

"""
plotWeights(dataFrame, series, xLabel, yaxis)

A scatter plot of the connection weights as a function of 
time for all the connections in the network.

# Arguments
* `dataFrame::DataFrame`: The data-frame holding the log weight-update events
* `series::Int`: (Optional) The series number
* `xLabel::String`: (Optional) The id for the x-axis
* `yaxis::String`: (Optional) The id for the y-axis
* `title::String`: (Optional) The title for the plot

# Returns
A `Plots.plot`
"""
function plotWeights(
    dataFrame::DataFrame;
    series::Int=-1, 
    xLabel::String="t (ms)", 
    yLabel::String="w(t)", 
    title::String="weights",
    args...
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

    # create the base plot
    seriesPlot = plot(
        title=title,
        titlefont=font(8),
        titleloc=series > 0 ? :right : :center,
        xlabel=xLabel,
        ylabel=yLabel
    );

    # add each of the traces (time series) to the plot
    i = 1
    for series in weightSeries
        seriesPlot = addSeriesToPlot(
            series[:signal_time], 
            series[:new_weight], 
            seriesPlot, 
            label=series[:connection][i]
        )
        i += 1
    end
    seriesPlot
end
