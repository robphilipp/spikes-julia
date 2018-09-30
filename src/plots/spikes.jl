include("plots.jl")

"""
plotSpikes(dataFrame, series=-1, xLabel="t(ms)", yLabel="neuron", title="spikes", args)

Creates a scatter plot for spike events (times) as a raster plot. Shows the spike-times
as a function of the neuron. Each neuron has a series of vertical lines that represent
the times at which they spiked.

# Arguments
* `dataFrame::DataFrame`: The data-frame holding the logged spike events
* `series::Int`: (Optional) The series number
* `xLabel::String`: (Optional) The id for the x-axis
* `yaxis::String`: (Optional) The id for the y-axis
* `title::String`: (Optional) The title for the plot

# Returns
A `Plots.plot`
"""
function plotSpikes(
    dataFrame::DataFrame;
    series::Int=-1, 
    xLabel::String="t (ms)", 
    yLabel::String="neuron", 
    title::String="spikes",
    args...
)::Plots.Plot
    if size(dataFrame)[1] == 0
        return "No update data available to plot; please ensure that you are logging update data"
    end

    # make a copy of the data frame
    spikes = DataFrame(dataFrame)

    # group by the connections to get an array of dataframes, each holding the time-series
    # of data
    spikeSeries = groupby(spikes, [:neuron_id], sort = true)

    # now plot each one
    seriesPlot = scatter(
        title=title,
        titlefont=font(8),
        titleloc=series > 0 ? :right : :center,
        xlabel=xLabel,
        ylabel=yLabel
    );

    height = seriesPlot[:size][2]
    margin = xLabel == "" ? 50 : 10
    markerSize = max(2, floor((args[:size][2] - margin)/length(spikeSeries)/4))
    println(markerSize)

    i = 1
    for series in spikeSeries
        # create the y-values of the series that all have the same value
        # and are aligned with the neuron id
        y = ones(length(spikeSeries[i][:signal_time])) .* i

        seriesPlot = addSeriesToScatter(
            series[:signal_time], 
            y, 
            seriesPlot, 
            label=series[:neuron_id][i],
            markersize=markerSize;
            args...
        )
        i += 1
    end
    seriesPlot
end

# """
#   plotSpikes( spikes, neurons, titleString )

# Plots the time-series of spike events from the `spikes` data-frame for
# neuron IDs that are listed in the `neurons` array. Each `neuron` in the array
# will generate a line in the plot for the spike times of that neuron.

#   # Argurments
#   * `spikes:DataFrame`: holds the spike data (potentials, update times, etc)
#   * `neurons:Array{String}`: An array of neuron IDs
#   * `titleString:String`: a string that should be added to the title
# """
# function plotSpikes( spikes, neurons, titleString, markerSize = 2 )
#   spikeSeries=[]
#   minTimes=[]
#   data=[]
#   inputIds=[]
#   for neuron in neurons
#     series = spikes[spikes[:neuron_id].==neuron,:]
#     if length(series[:signal_time]) > 0
#       push!(minTimes,series[:signal_time][1])
#       push!(inputIds, "$(neuron)" )
#       push!(data,series)
#     end
#   end
#   for input in 1:length(data)
#       # subtract t0 (the minimum time in any series) from all the times
#       # push!(spikeSeries,scatter(;x=data[input][:signal_time]-minimum(minTimes), y=ones(length(data[input][:signal_time])).*input, mode="markers", name="f: $(inputIds[input])", marker_size=4, line_width=1))
#       push!(spikeSeries,scatter(;x=data[input][:signal_time], y=ones(length(data[input][:signal_time])).*input, mode="markers", name="f: $(inputIds[input])", marker_symbol="line-ns-open", marker_size=markerSize, line_width=1))
#   end
#   plot([spikeSeries...],Layout(title="spikes; $titleString", xaxis_title="t (ms)", yaxis_title="neuron", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end

# """
#   plotSpikeTimes(spikes, neurons, titleStrign)

# Plots the spike times of the neurons in each pair.

#   # Arguments
#   * `spikes`: holds the spike data (potentials, update times, etc)
#   * `neurons`: holds [x, y] pairs of neuron names that are plotted against each other. The x-times should be the reference times against which to plot the y-times.
#   * `titleString:String`: a string that should be added to the title
# """
# function plotSpikeTimes(spikes, neurons, titleString)
#   spikeSeries=[]
#   minTimes=[]
#   data=[]
#   inputIds=[]
#   for neuron in neurons
#     xNeuron = neuron[1]
#     yNeuron = neuron[2]
#     xTimes = spikes[spikes[:neuron_id] .== xNeuron, :][:signal_time]
#     yTimes = spikes[spikes[:neuron_id] .== yNeuron, :][:signal_time]

#     numPoints = min(length(xTimes), length(yTimes))

#     # push!(data, series)
#     push!(spikeSeries, scatter(;x=xTimes, y=yTimes, mode="markers", name="f: $(xNeuron):$(yNeuron)", marker_size=2))
#   end

#   plot([spikeSeries...], Layout(title=titleString, xaxis_title="t (ms)", yaxis_title="t (ms)", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end

# """
#   plotSpikeIntervals( spikes, neurons, titleString )

# Plots the time-series of time between spike events from the `spikes` data-frame for
# neuron IDs that are listed in the `neurons` array. Each `neuron` in the array
# will generate a line in the plot for the time between successive spikes of that neuron.

#   # Argurments
#   * `spikes:DataFrame`: holds the spike data (potentials, update times, etc)
#   * `neurons:Array{String}`: An array of neuron IDs
#   * `titleString:String`: a string that should be added to the title
# """
# function plotSpikeIntervals( spikes, neurons, titleString )
#   spikeSeries=[]
#   minTimes=[]
#   data=[]
#   inputIds=[]
#   for neuron in neurons
#     series = spikes[spikes[:neuron_id].==neuron,:]
#     if length(series[:signal_time]) > 0
#       push!(minTimes,series[:signal_time][1])
#       push!(inputIds, "$(neuron)" )
#       push!(data,series)
#     end
#   end
#   for input in 1:length(data)
#       # subtract t0 (the minimum time in any series) from all the times
#       push!(spikeSeries,scatter(;x=data[input][:signal_time]-minimum(minTimes), y=data[input][:signal_time] - data[input][:last_fire], mode="markers+lines", name="f: $(inputIds[input])", marker_size=4, line_width=1))
#   end
#   plot([spikeSeries...],Layout(title="spike intervals; $titleString", xaxis_title="t (ms)", yaxis_title="∆t (ms)", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end

# function plotSpikeDeltas( spikes, neurons, titleString )
#   spikeSeries=[]
#   minTimes=[]
#   data=[]
#   inputIds=[]
#   for neuron in neurons
#     series = spikes[spikes[:neuron_id].==neuron,:]
#     if length(series[:signal_time]) > 0
#       push!(minTimes,series[:signal_time][1])
#       push!(inputIds, "$(neuron)" )
#       push!(data,series)
#     end
#   end
#   for input in 1:length(data)
#       # subtract t0 (the minimum time in any series) from all the times
#       push!(spikeSeries,scatter(;x=ones(length(data[input][:signal_time])), y=data[input][:signal_time] - data[input][:last_fire], mode="markers", name="f: $(inputIds[input])", marker_size=4, line_width=1))
#   end
#   plot([spikeSeries...],Layout(title="spike intervals; $titleString", xaxis_title="t (ms)", yaxis_title="∆t (ms)", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end

# """
#   plotDeltas( values, titleString )

# Plots the difference between successive values of the specified time-series

#   # Argurments
#   * `values:Array{Float16}`: holds the spike data (potentials, update times, etc)
#   * `titleString:String`: a string that should be added to the title
# """
# function plotDeltas( values, titleString )
#   deltas = [values[i]-values[i-1] for i in 2:length(values)]
#   t=[values[i] for i in 2:length(values)]
#   lfp = scatter(;x=t, y=deltas, mode="lines")
#   plot(lfp,Layout(title="$titleString", xaxis_title="t (ms)", yaxis_title="∆t (ms)", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end

# """
#   plotSpikeIntervals( spikes, neurons, titleString )

# Calculates the intervals bewteen successive spikes, `∆(t) = S(t) - S(t-1)`, and
# then plots `∆(t+1)` against `∆(t)`.

#   # Argurments
#   * `spikes:DataFrame`: holds the spike data (potentials, update times, etc)
#   * `neurons:Array{String}`: An array of neuron IDs
#   * `minTime:Int64`: The lower bound on the time in seconds (settle time)
#   * `maxTime:Int64`: The upper bound on the time in seconds; if 0, then uses all the data
#   * `delta:Int16`: The difference (i.e. plot x(t) versus y(t+n), delta = n)
#   * `titleString:String`: a string that should be added to the title
# """
# function plotSuccessiveSpikeIntervals( spikes, neurons, minTime, maxTime, delta, titleString )
#   series=[]
#   for neuron in neurons
#     values = spikes[spikes[:neuron_id].==neuron,:signal_time]
#     # values = values[values.>minTime && (maxTime==0 || values.<maxTime)]
#     values = filter(t -> t >= minTime && (maxTime == 0 || t <= maxTime ), Vector(values) )
#     deltas = [values[i]-values[i-delta] for i in (1+delta):length(values)]
#     x = [deltas[i] for i in 1:length(deltas)-delta]
#     y = [deltas[i] for i in (1+delta):length(deltas)]
#     push!(series, scatter(;x=x, y=y, mode="lines+markers", marker_size=4, opacity=0.5, line_width=1, name="$neuron"))
#   end
#   plot([series...], Layout(title="\n$titleString", xaxis_title="∆t (ms)", yaxis_title="∆(t+1) (ms)", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end

# function plotConjugateVariables( spikes, neurons, minTime, maxTime, delta, titleString )
#   series=[]
#   for neuron in neurons
#     values = spikes[spikes[:neuron_id].==neuron,:signal_time]
#     # values = values[values.>minTime && (maxTime==0 || values.<maxTime)]
#     values = filter(t -> t >= minTime && (maxTime == 0 || t <= maxTime ), Vector(values) )
#     deltas = [values[i]-values[i-delta] for i in (1+delta):length(values)]
#     deltaDeltas = [deltas[i]-deltas[i-delta] for i in (1+delta):length(deltas)]
#     x = [deltas[i] for i in 1:length(deltas)-delta]
#     y = [deltaDeltas[i] for i in 1:length(deltaDeltas)-delta]
#     z = [values[i] for i in 1:length(deltaDeltas)-delta]
#     push!(series, scatter3d(;x=x, y=y, z=z, mode="lines+markers", marker_size=4, opacity=0.5, line_width=1, name="$neuron"))
#   end
#   plot([series...], Layout(title="$titleString", xaxis_title="∆t (ms)", yaxis_title="∆(t+1)", margin_t=50, margin_b=70, margin_l=70, margin_r=50))
# end
