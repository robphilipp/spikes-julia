using Spikes

"""
    heaviside(x::Number)::Number

The Heaviside function that is 1 if the specified value x is greater than 0,
0.5 if x equals 0, and 0 if x is less than zero

# Arguments
* `x:Number`: the value
"""
function heaviside(x::Number)::Number
    ifelse(x < 0, 0, ifelse(x > 0, 1, 0.5)) 
end

"""
    sigmoid(time::Real, offset::Real, halfLife::Number)::Number

A sigmoidal function that has a zero value at ``t = t_{offset}`` and has
a value of ±1 at ``±``

# Arguments
* `time:Real`: The time
* `offset::Number`: The amount of time the zero value is offset from t=0
* `halfLife::Number`: The steepness of the sigmoid
"""
function sigmoid(time::Real, offset::Real, halfLife::Number)::Number
    2 * (1 / (1 + exp(-(time - offset) / halfLife)) - 0.5)
end
