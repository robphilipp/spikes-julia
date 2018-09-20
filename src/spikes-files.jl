using Spikes

"""
loadLogfile(directory::String, filename::String)::Array{String}

Basic function that loads the log-file with the specified name, in
the specified directory.

# Arguments
* `directory::String`: the path to the directory holding the file
* `filename::String`: the name of the log-file to load
"""
function loadLogfile(directory::String, filename::String)::Array{String}
    # concat the filename
    filePath = directory * filename

    # open the file, load all the lines, close the file
    file = open(filePath)
    lines = readlines(file)
    close(file)
    
    lines
end

"""
loadLogfileSeries(
    directory::String, 
    filename::String, 
    runIds::Array{<:Unsigned}
)::Dict{Unsigned, Array{String}}

Loads the log-file series in the specified directory, using the specified
filename template, and loading the specified run IDs. Returns a dictionary
where the keys are the run IDs, and the values are the log-lines for the
associated run.

# Arguments
* `directory::String`: the path to the directory holding the log-files
* `filename::String`: the filename template for constructing the log file
    names. The template parameter for the run ID is "%n".
* `runIds::Array{<:Unsigned}`: an array holding the run number in the series

# Example
A filename `neuron-activity.%n.log` along with run IDs `[1,2,3,4]` will
load the log-files: `neuron-activity.1.log`, `neuron-activity.2.log`, 
`neuron-activity.3.log`, `neuron-activity.4.log`. The log-files are
then added to the dictionary.
```julia-repl

Main> logs = loadLogfileSeries("/Users/rob/code/spikes/test-output/", "neuron-activity.%n.log", [1,2,3])
Loading neuron-activity.1.log...
Loading neuron-activity.2.log...
Loading neuron-activity.3.log...
Dict{Integer,Array{String,N} where N} with 3 entries:
  2 => String["spiked_system-2 - summary; input_neurons: 2; hidden_neurons: 2; output_neurons: 2", "spiked_system-2 - topology; neuron_id: output-1; location:…
  3 => String["spiked_system-3 - summary; input_neurons: 2; hidden_neurons: 2; output_neurons: 2", "spiked_system-3 - topology; neuron_id: output-1; location:…
  1 => String["spiked_system-1 - summary; input_neurons: 2; hidden_neurons: 2; output_neurons: 2", "spiked_system-1 - topology; neuron_id: output-1; location:…

Main> logs[1]
20907-element Array{String,1}:
 "spiked_system-1 - summary; input_neurons: 2; hidden_neurons: 2; output_neurons: 2"
 .
 .
 .
```
"""
function loadLogFileSeries(directory::String, filename::String, runIds::Array{<:Integer})::Dict{Integer, Array{String}}
    logs = Dict()

    for id in runIds
        logFileName = replace(filename, "%n" => id)
        println("Loading $(logFileName)...")
        logLines = loadLogfile(directory, logFileName)
        logs[id] = logLines
    end

    logs
end
