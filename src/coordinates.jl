using Spikes

"Represents a 3-dimensional coordinate ``C(x_1, x_2, x_3)``"
struct Coordinate
    "First dimension"
    x1::Real
    "Seconed dimension"
    x2::Real
    "Third dimesnion"
    x3::Real
end

"""
    coordinateForm(values::Array{Float})::Coordinate

Converts an array of length three into a Coordinate. The 
first element of the array is the first dimension of the 
Coordinate, the second element of the array is the second 
dimension, and the third element of the array is the 
third dimension. [x1, x1, x3] -> Coordinate(x1, x2, x3)

# Arguments
* `values::Array{Real}: array holding the coordinates`
"""
function coordinateFrom(values::Array{<:Real})::Coordinate
    Coordinate(values[1], values[2], values[3])
end

"""
    coordianteFrom(stringRep)::Coordinate

Converts the string-representation of the Spikes coordinate to a Coordinate

#Arguments
* `stringRep::String`: string of the form `(x=x1 µm, y=x2 µm, z=x3 µm), norm=d µm`
"""
function coordinateFrom(stringRep::String)::Coordinate
    # split the coordinate from the norm
    coordinate = split(stringRep, ", norm")[1]

    # split them into an array of x µm, y µm, z µm
    coords = split(coordinate[2:length(coordinate) - 1], ",")

    # and remove the units
    coordinateFrom([ parse(Float64, split(split(coords[i], "=")[2])[1]) for i = 1:length(coords) ])
end
