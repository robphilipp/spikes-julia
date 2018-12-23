using Spikes

using RDatasets, DataFrames
using LaTeXStrings

const LEARNING_TYPE = "learning_type"
const SOFT = "stdp_soft" 
const HARD = "stdp_hard" 
const ALPHA = "stdp_alpha"

# hard/soft stdp learning
const INHIBITORY_AMPLITUDE = "inhibitory_amplitude"
const INHIBITORY_PERIOD = "inhibitory_period"
const EXCITATION_AMPLITUDE = "excitation_amplitude"
const EXCITATION_PERIOD = "excitation_period"

# alpha stdp learning
const BASELINE = "baseline"
const LEARNING_RATE = "learning_rate"
const TIME_CONSTANT = "time_constant"

"""
stdpString(networkMetaData::DataFrame)::String

constructs the string describing the STDP function
"""
function stdpString(networkMetaData::DataFrame)::String
    println(networkMetaData[Spikes.LEARNING][LEARNING_TYPE])
    learningType = networkMetaData[Spikes.LEARNING][LEARNING_TYPE]
    learningString = "$(learningType)()"
    if learningType == HARD || learningType == SOFT
        inhibAmpl = networkMetaData[Spikes.LEARNING][INHIBITORY_AMPLITUDE]
        inhibPeriod = networkMetaData[Spikes.LEARNING][INHIBITORY_PERIOD]
        exciteAmpl = networkMetaData[Spikes.LEARNING][EXCITATION_AMPLITUDE]
        excitePeriod = networkMetaData[Spikes.LEARNING][EXCITATION_PERIOD]
        learning = "$(learningType)($(inhibAmpl), $(inhibPeriod), $(exciteAmpl), $(excitePeriod))"
    elseif learningType == ALPHA
        baseline = networkMetaData[Spikes.LEARNING][BASELINE]
        learningRate = networkMetaData[Spikes.LEARNING][LEARNING_RATE]
        timeConstant = networkMetaData[Spikes.LEARNING][TIME_CONSTANT]
        learning = "$(learningType)($(baseline), $(timeConstant), $(learningRate))"
    end
    learning
end
  
"""
    stdpParameters(networkMetaData)

Spike-timing-dependent plasticity function parameters. Returns a Tuple 
holding the learning parameters. The first element in the tuple is always 
the learning type (i.e. hard, soft, alpha), and the remaining elements are 
the parameters describing the learning function.

# Hard/Soft STDP
* `learningType::String`: should be either `stdp_soft` or `stdp_hard`
* `inhibitionAmplitude::Real`: the max value of the inhibition (just after spike)
    contribution to the weight adjustment
* `inhibitionPeriod::Integer`: the decay time-constant (ms) of inhibition
* `excitationAmplitude::Real`: the max value of the excitation (just before the spike)
    contribution to the weight adjustment
* `excitationPeriod::Integer`: the decay time-constant (ms) of the excitation

# Alpha STDP
* `learningType::String`: should be `stdp_alpha`
* `baseline::Real`: the inhibition value (for example, -1)
* `timeConstant::Integer`: the time-constant for ``\alpha-funcion``
* `learningRate::Real`: the learning rate used when adjusting the weights

# Arguments
* `networkMetaData::Dict{Any, Any}`: A dictionary containing the learning parameters
"""
function stdpParameters(networkMetaData::DataFrame)
    stripChars = ['m', 's', ' ', 'µ']
    learningType = networkMetaData[Spikes.LEARNING][LEARNING_TYPE]
    params = (learningType)
    if learningType == HARD || learningType == SOFT
        inhibAmpl = parse(Real, networkMetaData[Spikes.LEARNING][INHIBITORY_AMPLITUDE])
        inhibPeriod = parse(Real, strip(networkMetaData[Spikes.LEARNING][INHIBITORY_PERIOD], stripChars))
        exciteAmpl = parse(Real, networkMetaData[Spikes.LEARNING][EXCITATION_AMPLITUDE])
        excitePeriod = parse(Real, strip(networkMetaData[Spikes.LEARNING][EXCITATION_PERIOD], stripChars))
        params = (learningType, inhibAmpl, inhibPeriod, exciteAmpl, excitePeriod)
    elseif learningType == ALPHA
        baseline = parse(Real, networkMetaData[Spikes.LEARNING][BASELINE])
        learningRate = parse(Real, networkMetaData[Spikes.LEARNING][LEARNING_RATE])
        timeConstant = parse(Real, strip(networkMetaData[Spikes.LEARNING][TIME_CONSTANT], stripChars))
        params = (learningType, baseline, timeConstant, learningRate)
    end
    params
end
  
"""
    stdp(
        timeRange::UnitRange{Integer}, 
        inhibitionAmplitude::Real, 
        inhibitionPeriod::Integer, 
        excitationAmplitude::Real, 
        excitationPeriod::Integer
    )::Array{Real}

The Spike-time-dependent plasticity function used for the hard and soft limits, but not
for the ``\alpha-function`` STDP.

#Arguments
* `t::UnitRange{Integer}`: The range of times starting at some time before the spike (t < 0) until some time after the spike
* `inhibAmpl::Real`: The amplitude of the inhibition (at t=0+)
* `inhibPeriod::Integer`: The time-constant for the inhibition decay
* `excAmpl::Real`: The amplitude of the excitation (at t=0-)
* `excPeriod::Integer`: The time-constant for the excitation decay
"""
function stdp(t::UnitRange{Integer}, inhibAmpl::Real, inhibPeriod::Integer, excAmpl::Real, excPeriod::Integer)
    ifelse(t .> 0, -inhibAmpl * exp.(-t / inhibPeriod), excAmpl * exp.(t / excPeriod))
end
  
"""
    alphaStdp(
        t::Array{<:Integer}, 
        T::Integer, 
        b::Number, 
        r::Number, 
        tau::Integer, 
        w::Number, 
        wMax::Number
    )::Array{Real}

Learning function for STDP that uses an alpha function

# Argument
* `t::Array{<:Integer}`: The range of time since the begining of the time-window (the previous spike) to some time after the current spike
* `T::Integer`: The time-window length
* `b::Real`: The baseline (b ≤ 0)
* `r::Real`: The learning rate (r > 0)
* `tau::Integer`: The time-constant (tau > 0)
* `w::Number`: the current weight
* `wMax::Number`: the maximum allowable value for the weight
"""
function alphaStdp(t::Array{<:Integer}, T::Integer, b::Number, r::Number, tau::Integer, w::Number, wMax::Number)
    delta = zeroOffset(tau, b)
    timeFactor = (delta .- (t .- T)) ./ tau
    r * Spikes.heaviside(wMax - w) .* map(timeFactor) do tf 
        max(b, exp(1) * (1 - b) * tf * exp(-tf) + b)
    end
end

"""
    zeroOffset(tau::Integer, b::Number)::Number

Calculates the first approximation to the time offset required so
that zero of the alpha-function is at t=0

# Arguments
* `tau::Integer`: The time-constant (tau > 0)
* `b::Number`: The baseline (b ≤ 0) that represents the inhibition amount
"""
function zeroOffset(tau::Integer, b::Number)::Number
    gamma::Number = -b * exp(-1) / (1 - b)
    R = (27 * gamma - 7) / 54
    Q = 2.0 / 9
    lambda = sqrt(Q * Q * Q + R * R)
    S = cbrt(R + lambda)
    T = cbrt(R - lambda)
    tau * (S + T + 1.0 / 3)
end
