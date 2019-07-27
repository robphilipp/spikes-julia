# File holds functions for parsing logs, and series of logs,
# in data-frames and dictionaries of data-frames.
# using Spikes

# DataArrays is broken with version 0.7 and above; filterNames(...) doesn't seem to be used elsewhere
using RDatasets, DataFrames #, DataArrays
using LaTeXStrings

const LEARNING = "learning"
const NETWORK_INFO = "neurons.NetworkSetupEvent"
const SUMMARY = "summary"

const TOPOLOGY = "topology"
const NEURON_ID = "neuron_id"
const LOCATION = "location"

const CONNECTION = "networkConnected"
const PRE_SYNAPTIC_ID = "pre_synaptic"
const POST_SYNAPTIC_ID = "post_synaptic"
const PRE_SYNAPTIC_LOCATION = "pre_synaptic_location"
const POST_SYNAPTIC_LOCATION = "post_synaptic_location"
const INITIAL_WEIGHT = "initial_weight"

"""
parseIntoDict(logLine::String)::Tuple{String, Dict{Any, Any}}

Parses a log line into a dictionary and returns a tuple 
that has the name of the log-line as the first element and 
the dictionary as the second element. A log-line should
hold the meta-data about the network, and be something like:
* topology; topology; neuron_id: output-1; location: (x=-300 µm, y=0 µm, z=0 µm)
* learning; learning_type: stdp_soft; inhibitory_amplitude: 0.06; inhibitory_period: 15.0 ms; excitation_amplitude: 0.02; excitation_period: 10.0 ms

Returns a tuple whose the first element is the log-line's name and the second element is the
dictionary holding the values from the log line

 # Arguments
 * `logLine::Array{String}`: a line containing a command and then key value pairs, each
    pair separated from another pair by a "; "
"""
function parseIntoDict(logLine::String)::Tuple{String,Dict{Any,Any}}
    networkInfo = replace(split(logLine, " - ")[2], r"\n" => "")
    commands = split(networkInfo, "; ")

    dictionary = Dict()
    for i in 2:length(commands)
        parts = split(commands[i], ": ")
        dictionary["$(parts[1])"] = parts[2]
    end
    (commands[1], dictionary)
end

# """
#   filterNames(prefix::String, connectionNames::DataArray)::Array{String,1}

# Returns a sorted list of names that have the specified prefix.

# # Arguments
# * `prefix::String`: the prefix for which to filter
# * `connectionNames::DataArray`: the data-array holding the neuron names

# # Example
# ```julia-repl
# inputNeurons = SpikeAnalyses.connectionList("input-", learn[:pre_synaptic])
# ```
# """
# filterNames(prefix::String, connectionNames::DataArray)::Array{String} =
#   sort(union(connectionNames[Bool[occursin(Regex("$(prefix)([0-9]+)(.[0-9]+)*"), post) for post in connectionNames],:]))

"""
networkInfo(logLine::Array{String})::Dict{String, Any}

Pulls the network information from the top of the logs. 
Typically there are 3 types of lines at the top of the 
file, each line starts with (after the log preamble)
`NetworkSetupEvent\$ - `. This method returns a dictionary 
with the command as the key and a dictionary with the elements
 of the line as the value. For exemple,
* summary; input_neurons: 2; hidden_neurons: 2; output_neurons: 2
* topology; neuron_id: inhib-2; location: (x=290 µm, y=0 µm, z=0 µm)
* learning; learning_type: stdp_soft; inhibitory_amplitude: 0.06; inhibitory_period: 15.0 ms; excitation_amplitude: 0.02; excitation_period: 10.0 ms
the above log lines will result in a dictionary with keys `summary`, `topology`, `learning`.

# Arguments
* `logLines::Array{String}`: An array of log lines from the Spikes output
"""
function networkInfo(logLines::Array{String})::Dict{String,Dict{String,String}}
    networkInfo = Dict()
    for line in logLines
        if contains(line, SUMMARY) || contains(line, TOPOLOGY) || contains(line, LEARNING)
            info = parseIntoDict(line)
            networkInfo[ info[1] ] = info[2]
        end
    end
    networkInfo
end
  
"""
networkTopology(logLines:Array{String})::Array{(String, Spikes.Coordinate)}

Parses the log lines into an data-frame with the following keys
* `neuron_id`: the ID of the neuron
* `x1`: the first coordinate of the neuron
* `x2`: the second coordinate of the neuron
* `x3`: the third coordinate of the neuron
The coordinates are generally Cartesian coordinates when loaded from the
log files.

# Arguments
* `logLines::Array{String}`: an array holding the Spikes log lines

# Example of log-lines for WTA network
```text
... - topology; neuron_id: output-1; location: (x=-300 µm, y=0 µm, z=0 µm)
... - topology; neuron_id: input-1; location: (x=-300 µm, y=0 µm, z=100 µm)
... - topology; neuron_id: input-2; location: (x=300 µm, y=0 µm, z=100 µm)
... - topology; neuron_id: inhib-1; location: (x=-290 µm, y=0 µm, z=0 µm)
... - topology; neuron_id: output-2; location: (x=300 µm, y=0 µm, z=0 µm)
... - topology; neuron_id: inhib-2; location: (x=290 µm, y=0 µm, z=0 µm)
```
"""
function networkTopology(logLines::Array{String})::DataFrame
    neuronId = Array{String,1}()
    x1 = Array{Float64,1}()
    x2 = Array{Float64,1}()
    x3 = Array{Float64,1}()
    for line in logLines
        if occursin(r" - topology; neuron_id: [a-z]+-[0-9]+;", line)
            # create the dictionary that holds the values of the line
            dict = parseIntoDict(line)
            push!(neuronId, dict[2][NEURON_ID])

            coord = coordinateFrom(String(dict[2][LOCATION]))
            push!(x1, coord.x1)
            push!(x2, coord.x2)
            push!(x3, coord.x3)
        end
    end
    dataFrame = DataFrame(neuron_id=neuronId,
        x1=x1,
        x2=x2,
        x3=x3)
end
  
"""
    connectionTopology(logLines::Array{String})::Array{Spikes.Connection}

Parses the log-lines into a data-frame with the following keys
* `pre_synaptic_id`: The ID of the pre-synaptic neuron
* `post_synaptic_id`: The ID of the post-synaptic neuron
* `initial_weight`: The initial connection weight at construction
* `pre_x1`: The first coordinate of the pre-synaptic neuron
* `pre_x2`: The second coordinate of the pre-synaptic neuron
* `pre_x3`: The third coordinate of the pre-synaptic neuron
* `post_x1`: The first coordinate of the post-synaptic neuron
* `post_x2`: The second coordinate of the post-synaptic neuron
* `post_x3`: The third coordinate of the post-synaptic neuron

# Arguments
* `logLines::Array{String}`: an array holding the Spikes log lines

# Example of the log-lines
```text
... - networkConnected; pre_synaptic: input-1; post_synaptic: output-1; initial_weight: 0.5; equilibrium_weight: 0.5; pre_synaptic_location: (x=-300 µm, y=0 µm, z=100 µm); post_synaptic_location: (x=-300 µm, y=0 µm, z=0 µm); distance: 100.00 µm
... - networkConnected; pre_synaptic: input-1; post_synaptic: output-2; initial_weight: 0.5; equilibrium_weight: 0.5; pre_synaptic_location: (x=-300 µm, y=0 µm, z=100 µm); post_synaptic_location: (x=300 µm, y=0 µm, z=0 µm); distance: 608.28 µm
... - networkConnected; pre_synaptic: input-2; post_synaptic: output-1; initial_weight: 0.5; equilibrium_weight: 0.5; pre_synaptic_location: (x=300 µm, y=0 µm, z=100 µm); post_synaptic_location: (x=-300 µm, y=0 µm, z=0 µm); distance: 608.28 µm
... - networkConnected; pre_synaptic: input-2; post_synaptic: output-2; initial_weight: 0.5; equilibrium_weight: 0.5; pre_synaptic_location: (x=300 µm, y=0 µm, z=100 µm); post_synaptic_location: (x=300 µm, y=0 µm, z=0 µm); distance: 100.00 µm
... - networkConnected; pre_synaptic: output-1; post_synaptic: inhib-1; initial_weight: 1.0; equilibrium_weight: 1.0; pre_synaptic_location: (x=-300 µm, y=0 µm, z=0 µm); post_synaptic_location: (x=-290 µm, y=0 µm, z=0 µm); distance: 10.00 µm
... - networkConnected; pre_synaptic: output-2; post_synaptic: inhib-2; initial_weight: 1.0; equilibrium_weight: 1.0; pre_synaptic_location: (x=300 µm, y=0 µm, z=0 µm); post_synaptic_location: (x=290 µm, y=0 µm, z=0 µm); distance: 10.00 µm
```
"""
function connectionTopology(logLines::Array{String})::DataFrame
    preSynaptic = Array{String,1}()
    preX1 = Array{Float64,1}()
    preX2 = Array{Float64,1}()
    preX3 = Array{Float64,1}()
    postSynaptic = Array{String,1}()
    postX1 = Array{Float64,1}()
    postX2 = Array{Float64,1}()
    postX3 = Array{Float64,1}()
    initialWeight = Array{Float64,1}()
    for line in logLines
        if occursin(r" - networkConnected; pre_synaptic: [a-z]+-[0-9]+; post_synaptic: [a-z]+-[0-9]+;", line)
            # create the dictionary that holds the values of the line
            dict = parseIntoDict(line)
    
            # grab the coordinates from the pre-synaptic and post-synaptic neurons
            push!(preSynaptic, dict[2][PRE_SYNAPTIC_ID])
            preSynapticCoord = coordinateFrom(String(dict[2][PRE_SYNAPTIC_LOCATION]))
            push!(preX1, preSynapticCoord.x1)
            push!(preX2, preSynapticCoord.x2)
            push!(preX3, preSynapticCoord.x3)

            push!(postSynaptic, dict[2][POST_SYNAPTIC_ID])
            postSynapticCoord = coordinateFrom(String(dict[2][POST_SYNAPTIC_LOCATION]))
            push!(postX1, postSynapticCoord.x1)
            push!(postX2, postSynapticCoord.x2)
            push!(postX3, postSynapticCoord.x3)

            push!(initialWeight, parse(Float64, dict[2][INITIAL_WEIGHT]))
        end
    end
    dataFrame = DataFrame(pre_synaptic_id=preSynaptic,
        post_synaptic_id=postSynaptic,
        initial_weight=initialWeight,
        pre_x1=preX1,
        pre_x2=preX2,
        pre_x3=preX3,
        post_x1=postX1,
        post_x2=postX2,
        post_x3=postX3)
end

"""
signalEvents(logLines::Array{String}::DataFrame)

Parses the log-lines into a DataFrame holding all the signal events. The 
data frame has the following keys
* `pre_synaptic`: the ID of the pre-synaptic neuron (i.e. the source)
* `post_synaptic`: the ID of the post-synaptic neuron (i.e. the neuron
    receiving the signal)
* `signal_time`: the time (simulation, ms) when the signal arrives at the
    post-synaptic neuron
* `last_event`: the time (simulation, ms) when the last signal was received
    by the post-synaptic neuron
* `last_fire`: the time (simulation, ms) when the post-synaptic neuron
    last spiked
* `signal_intensity`: the signal strength (mV) of the signal arriving at
    the post-synaptic neuron

# Arguments
* `logLines::Array{String}`: the lines from the log file

# Example log lines
```text
... - receive; id: output-2; source: input-2; timestamp: 121.0 ms; last_event: 90.0 ms; last_fire: 71.0 ms; signal_intensity: 1.1 mV
```
"""
function signalEvents(logLines::Array{String})::DataFrame
    preSynapticId = Array{String,1}()
    postSynapticId = Array{String, 1}()
    signalTime = Array{Float64, 1}()
    previousSignalTime = Array{Float64, 1}()
    previousSpikeTime = Array{Float64, 1}()
    signal = Array{Float64, 1}()

    for line in logLines
        if occursin(r" - receive; id: [a-z]+-[0-9]+(.[0-9]+)*; source: [a-z]+-[0-9]+;", line)
            dict = parseIntoDict(line)

            push!(preSynapticId, string(dict[2]["source"]))
            push!(postSynapticId, string(dict[2]["id"]))
            push!(signalTime, parse(Float64, split(dict[2]["timestamp"], " ")[1]))
            push!(previousSignalTime, parse(Float64, split(dict[2]["last_event"], " ")[1]))
            push!(previousSpikeTime, parse(Float64, split(dict[2]["last_fire"], " ")[1]))
            push!(signal, parse(Float64, split(dict[2]["signal_intensity"], " ")[1]))
        end
    end
    dataFrame = DataFrame(
        pre_synaptic = preSynapticId,
        post_synaptic = postSynapticId,
        signal_time = signalTime,
        last_event = previousSignalTime,
        last_fire = previousSpikeTime,
        signal_intensity = signal
    )
end

"""
intrinsicPlasticityEvents(logLines::Array{String})::DataFrame

Parses the intrinsic-plasticity update events (i.e. the neuron bias) into
a data frame with the following keys
* `neuron_id`: the ID of the neuron whose plasticity (bias) was updated
* `timestamp`: the time (simulation, ms) of the update event
* `intrinsicPlasticity`: the updated value of the intrinsic plasticity
    (i.e. the bias) 

# Arguments
* `logLines::Array{String}`: the lines from the log file

# Example log lines
```text
... - intrinsicPlasticity; id: inhib-2; timestamp: 173.0 ms; intrinsicPlasticity: 0.0 mV
```
"""
function intrinsicPlasticityEvents(logLines::Array{String})::DataFrame
    neuronIds = Array{String, 1}()
    timestamp = Array{Float64, 1}()
    intrinsicPlasticity = Array{Float64, 1}()

    for line in logLines
        if occursin(r" - intrinsicPlasticity; id: [a-z]+-[0-9]+(.[0-9]+)*;", line)
            dict = parseIntoDict(line)

            push!(neuronIds, string(dict[2]["id"]))
            push!(timestamp, parse(Float64, split(dict[2]["timestamp"], " ")[1]))
            push!(intrinsicPlasticity, parse(Float64, split(dict[2]["intrinsicPlasticity"], " ")[1]))
        end
    end
    dataFrame = DataFrame(
        neuron_id = neuronIds,
        timestamp = timestamp,
        intrinsicPlasticity = intrinsicPlasticity
    )
end

"""
    learningEvents(logLines::Array{String})::DataFrames.DataFrame

Parses the log-lines into a DataFrame holding the all the learning event data.
The data-frame has the following keys
* `pre_synaptic`: the pre-synaptic neuron ID (also called the source)
* `post_synaptic`: the post-synaptic neuron ID
* `signal_time`: time (in simulation ms) at which the signal *arrived* at 
    the post-synaptic neuron
* `previous_weight`: the value of the weight *before* the learning update
* `new_weight`: the value of the weight *after* the learning update
* `adjustment`: the amoun to the weight adjustment
* `time_window`: the time (ms) between the most recent spike and the previous spike
* `stdp_time`: the time of the event within the time window

# Arguments
* `logLines::Array{String}`: an array holding the Spikes log lines

# Example log lines
```text
... - learn; id: inhib-2; source: output-2; previous_weight: 1.0; new_weight: 1.0; adjustment: 0.0; time_window: 72.0 ms; stdp_time: 72.0 ms; signal_time: 72.0 ms
... - learn; id: output-2; source: input-2; previous_weight: 0.5; new_weight: 0.5028562602959841; adjustment: 0.0028562602959840613; time_window: 71.0 ms; stdp_time: 71.0 ms; signal_time: 71.0 ms
... - learn; id: output-2; source: input-1; previous_weight: 0.5; new_weight: 0.5133204981127273; adjustment: 0.013320498112727326; time_window: 71.0 ms; stdp_time: 71.0 ms; signal_time: 71.0 ms
```
"""
function learningEvents(logLines::Array{String})::DataFrame
    # the columns of the data frame
    preSynapticId = Array{String,1}()
    postSynapticId = Array{String,1}()
    signalTime = Array{Float64,1}()
    previousWeight = Array{Float64,1}()
    newWeight = Array{Float64,1}()
    adjustment = Array{Float64,1}()
    timeWindow = Array{Float64,1}()
    stdpTime = Array{Float64,1}()
  
    for line in logLines
        # grab all messages that start with "learn" and have a pre- and post-synaptic neuron
        if occursin(r" - learn; id: [a-z]+-[0-9]+(.[0-9]+)*; source: [a-z]+-[0-9]+;", line)
              # create a dictionary holding the values of the line
            dict = parseIntoDict(line)
  
            push!(preSynapticId, string(dict[2]["source"]))
            push!(postSynapticId, string(dict[2]["id"]))
            push!(signalTime, parse(Float64, split(dict[2]["signal_time"], " ")[1]))
            push!(previousWeight, parse(Float64, dict[2]["previous_weight"]))
            push!(newWeight, parse(Float64, dict[2]["new_weight"]))
            push!(adjustment, parse(Float64, dict[2]["adjustment"]))
            push!(timeWindow, parse(Float64, split(dict[2]["time_window"], " ")[1]))
            push!(stdpTime, parse(Float64, split(dict[2]["stdp_time"], " ")[1]))
        end
    end
    dataFrame = DataFrame(pre_synaptic=preSynapticId, 
        post_synaptic=postSynapticId, 
        signal_time=signalTime, 
        previous_weight=previousWeight, 
        new_weight=newWeight, 
        adjustment=adjustment, 
        time_window=timeWindow, 
        stdp_time=stdpTime)
end

"""
membranePotentialUpdateEvents(logLines::Array{String})::DataFrame

Parses the log-lines into a data-frame holding all the membrane
potential updates. The data-frame has the following keys:
* `neuron_id`: the ID of the neuron whose membrane potential was updated
* `signal_time`: the time (ms, simulation time) when the signal arrived
    at the neuron
* `last_event`: the time (ms, simulation time) of the previous update
* `last_fire`: the time (ms, simulation time) when this neuron last spiked
* `potential`: the membrane potential after the update

# Arguments
* `logLines::Array{String}`: an array holding the Spikes log lines

# Example log lines
```text
... - update; id: output-2; signal_timestamp: 38.0 ms; last_event: 0.0 ms; last_fire: 0.0 ms; potential: 0.5444444444444445 mV
```
"""
function membranePotentialEvents(logLines::Array{String})::DataFrame
    # the columns of the data frame
    neuronId = Array{String,1}()
    signalTime = Array{Float64,1}()
    lastEvent = Array{Float64,1}()
    lastFire = Array{Float64,1}()
    potential = Array{Float64,1}()
  
    for line in logLines
      # grab all the messages that start with "update"
        if occursin(r" - update; id: [a-z]+-[0-9]+;", line)
        # create a dictionary holding the values of the line
            dict = parseIntoDict(line)
  
            push!(neuronId, dict[2]["id"])
            push!(signalTime, parse(Float64, split(dict[2]["signal_timestamp"], " ")[1]))
            push!(lastEvent, parse(Float64, split(dict[2]["last_event"], " ")[1]))
            push!(lastFire, parse(Float64, split(dict[2]["last_fire"], " ")[1]))
            push!(potential, parse(Float64, split(dict[2]["potential"], " ")[1]))
        end
    end
    dataFrame = DataFrame(
        neuron_id=neuronId, 
        signal_time=signalTime, 
        last_event=lastEvent, 
        last_fire=lastFire, 
        potential=potential
    )
end

"""
spikeEvents(logLines::Array{String})::DataFrame

Parses the log-lines into a data-frame containing the neuron's spike events.
The data-frame has the following keys
* `neuron_id`: the ID of the neuron that spiked (fired)
* `signal_time`: the time at which the neuron spiked
* `signal_intensity`: the magnitude of the spike (mV)
* `last_fire`: the time of the neuron's previous spike

# Arguments
* `logLines::Array{String}`: an array holding the Spikes log lines

# Example log lines
```text
... - fire; id: inhib-2; timestamp: 74.00705218617772 ms; signal_intensity: -0.5 mV; last_fire: 0.0 ms
```
"""
function spikeEvents(logLines::Array{String})::DataFrame
    # columns for the data frame
    neuronId = Array{String,1}()
    signalTime = Array{Float64,1}()
    intensity = Array{Float64,1}()
    lastFire = Array{Float64,1}()
  
    for line in logLines
        if occursin(r" - fire; id: [a-z]+-[0-9]+;", line)
            # create a dictionary holding the values of the line
            dict = parseIntoDict(line)
  
            push!(neuronId, dict[2]["id"])
            push!(signalTime, parse(Float64, split(dict[2]["timestamp"], " ")[1]))
            push!(intensity, parse(Float64, split(dict[2]["signal_intensity"], " ")[1]))
            push!(lastFire, parse(Float64, split(dict[2]["last_fire"], " ")[1]))
        end
    end
    dataFrame = DataFrame(
        neuron_id=neuronId, 
        signal_time=signalTime, 
        signal_intensity=intensity, 
        last_fire=lastFire
    )
end

"""
eventSeriesFrom(
    logLines::Dict{Integer, Array{String}}, 
    logToDataFrame::Function
)::Dict{Integer, DataFrame}

Convenience function that accepts a dictionary of the 
series_id -> log-lines and converts them to a dictionary
of series_id -> data-frame mappings. The specified 
`logToDataFrame` function converts each individual set
of log-lines into a data-frame.

# Arguments
* `logLines::Dict{Integer, Array{String}}`: the dictionary
    mapping the series ID to the log-lines from the neuron
    activity file.
* `logToDataFrame::Function`: A function that accepts an
    `Array{String}` and converts it to a `DataFrame`

# Example
eventSeriesFrom(logs, membranePotentialEvents)

where the `membranePotentialEvents` is a function that
accepts an `Array{String}` and returns a `DataFrame`.
"""
function eventSeriesFrom(logLines::Dict{Integer, Array{String}}, logToDataFrame::Function)::Dict{Integer, DataFrame}
    return Dict([(series[1], logToDataFrame(series[2])) for series in logLines])
end
