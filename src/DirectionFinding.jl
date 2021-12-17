module DirectionFinding

using LinearAlgebra, UnicodePlots

export Antenna,
       AntennaArray,
       Position, PositionS,
       SignalSource,
       Simulation,
       origin,
       halfsine_train,
       lineararray, circulararray, cornerarray, randomarray,
       cbf,
       MUSIC,
       findpeaks,
       beamwidth

const C = 299.79e6  # speed of light

abstract type AbstractPosition end

struct Position <: AbstractPosition
    x :: Float64
    y :: Float64
    z :: Float64
end

Position() = Position(0, 0, 0)
Position(x, y) = Position(x, y, 0)
origin() = Position()

struct PositionS <: AbstractPosition
    r :: Float64
    θ :: Float64
    ϕ :: Float64
end

function tocartesian(p::PositionS)
    r , θ, ϕ = p.r, p.θ, p.ϕ
    return Position.(r.*cos.(ϕ)*sin.(θ), r.*sin.(ϕ)*sin.(θ), r.*cos.(θ))
end

function tospherical(p::Position)
    x, y, z = p.x, p.y, p.z
    r= sqrt.(x.^2 + y.^2 + z.^2)
    return PositionS.(r, acos.(z/r), atan.(y, x))
end

struct Antenna{R}
    position :: Position
    gain     :: R
end

Antenna(a::Position) = Antenna(a, isotropic)

Antenna(x::T, y::T, gain = isotropic) where {T<:Number} = Antenna(Position(x, y), gain)

function Base.getproperty(a::Antenna, s::Symbol)
    s === :x && return a.position.x
    s === :y && return a.position.y
    s === :z && return a.position.z
    getfield(a, s)
end

isotropic(θ, ϕ) = 1.0

struct AntennaArray
    array    :: Vector{Antenna}
    ref      :: Position
end

AntennaArray(av) = AntennaArray(av, origin())

Base.length(a::AntennaArray) = length(a.array)
Base.getindex(a::AntennaArray, args... ; kwargs...) = getindex(a.array, args..., kwargs...)

""" lineararray(M, d, ref ; gain, σ²) :: AntennaArray

Returns a planar, linear array of `M` antennas spaced `d` meters with reference
point `ref` (defaults to the origin). Each antenna has gain `gain` (defaults to
isotropic). σ² specifies the variance of a (Gaussian) random variation in antenna
position."""
function lineararray(M, d, ref = origin(); gain = isotropic, σ² = 0)
    s() = sqrt(σ²)*randn()
    return AntennaArray([Antenna(0+s(), dd+s(), gain)
                         for dd in range((-d/2)*(M-1), (d/2)*(M-1), length=M)], ref)
end

""" circulararray(M, r, ref ; gain, σ²) ::AntennaArray

Returns a planar, circular array with `M` antennas on a circle of radius `r`, centered
on reference point `ref`."""
function circulararray(M, r, ref = origin(); gain = isotropic, σ² = 0)
    s() = sqrt(σ²)*randn()
    angles = range(0, step = 2π/M, length=M)
    return AntennaArray([Antenna(x+s(), y+s(), gain)
                         for (x,y) = zip(r.*cos.(angles), r.*sin.(angles))], ref)
end

""" cornerarray(d, ref ; gain, σ² = 0)

Returns a planar array made up of four antennas in the corner of a square of side `d`
centered on reference point `ref`. """
function cornerarray(d, ref = origin(); gain = isotropic, σ² = 0)
    return(circulararray(4, d/sqrt(2), ref, gain=gain, σ²=σ²))
end

""" randomarray(M, σ², ref ; gain)

Returns a planar array with `M` antennas on (Gaussian) random positions around reference
point `ref`. The variance of the positions is `σ²`."""
function randomarray(M, σ² = 1, ref = origin() ; gain = isotropic)
    s() = sqrt(σ²)*randn()
    return AntennaArray([Antenna(ref.x+s(), ref.y+s(), gain) for _=1:M])
end

function Base.show(io::IO, a::AntennaArray)
    M = length(a.array)
    xcoord = [ant.x for ant in a.array]
    ycoord = [ant.y for ant in a.array]
    zcoord = [ant.z for ant in a.array]
    println(io, "An antenna array with $M elements.")
    for i in 1:M
        println(io, "   $i: x = $(xcoord[i]), y = $(ycoord[i]), z = $(zcoord[i])")
    end
    println("Reference point: x = $(a.ref.x), y = $(a.ref.y), z = $(a.ref.z)")
    # plot
    plt = scatterplot(xcoord, ycoord, marker = '📡')
    print(io, scatterplot!(plt, [a.ref.x], [a.ref.y], marker = 'R', color=:red))
end

"""Half-sine pulse at rate Rp with random amplitude."""
function halfsine_train(Rp)
    Tp = 1/Rp
    p(t) = sin(π*Rp*mod(t,Tp))
    a() = rand([-1,1])
    t -> Complex(a()*p(t), a()*p(t))
end

abstract type Source end

""" SignalSource(θ, sbb)

Returns a signal source with the following fields:

    `θ   :: Float64`  : Angle between a line orthogonal to the array's
                        reference point and the source.
    `sbb :: Function` : function that returns the transmitted lowpass
                        complex signal evaluated at snapshot instants `t`.  """
struct SignalSource{T, F} <: Source
    θ      :: T
    sbb    :: F
end

""" SignalSource(t)

Return the lowpass complex signal produced by the source `s` at time `t`.  """
(s::SignalSource)(t) = s.sbb(t)

"""Simulation

Fields:
    array :: an AbstractArray
    fc :: simulation carrier frequency
    N₀ :: noise spectral density in each receiver
    sources :: a tuple of the sources in the simulation
    phaseshifts : vector of functions `f[i](θ)` = phase shift of antenna `i`
                  relative to array reference point when source is at angle `θ`.  """
struct Simulation{T, S, M}
    array       :: T
    fc          :: Float64
    N₀          :: Float64
    sources     :: S
    phaseshifts :: Vector{M}  # array manifold
end

function Simulation(a, fc, N₀, s::Source...)
    λ = C/fc
    phaseshifts = [θ -> exp(1im*phaseshift(antenna, a.ref, θ, λ)) for antenna in a.array]
    Simulation(a, fc, N₀, s, phaseshifts)
end

""" projection(a, r, θ)

Returns the projection of antenna `a` on the wavefront of a source
at angle `θ` when it touches reference point `r`."""
function projection(a::Antenna, r::Position, θ)
    ϕ = θ + π/2
    if ϕ ≈ π/2 || ϕ ≈ 3π/2
        proj = Position(a.x, r.y)
    else
        m = tan(ϕ); n = -1.0/m;
    	x = (m*r.x-r.y-n*a.x+a.y)/(m-n)
    	y = m*(x-r.x)+r.y
		proj = Position(x, y)
    end
end

""" phaseshift(a, r, θ, λ)

Returns the phase shift seen by `a` relative to `r` when the
source is at angle `θ` and with wavelength `λ`.  """
function phaseshift(a::Antenna, r::Position, θ, λ)
    θ < 0 && (θ += 2π)
    p = projection(a, r, θ)
    # determine distance between antenna and projection
    d = sqrt((a.x-p.x)^2 + (a.y-p.y)^2)
    ps = d*2π/λ
    # Determine if `a` is in front of or behind `r` relative to the wavefront.
    # If in front, the phase shift is positive.
    if θ ≈ 0
		a.x > r.x && return ps
        return -ps
	elseif θ ≈ π
        a.x < r.x && return ps
        return -ps
	else
		m = tan(θ+π/2);
        th = m*(a.x-r.x)+r.y
		if θ <= π
            a.y < th && return -ps
            return ps
		else
            a.y > th && return -ps
            return ps
		end
	end
end

""" snapshot(sim, t)

Return a snapshot of the signal received by the array in simulation `sim` at time `t`" """
function snapshot(sim::Simulation, t)
    y = zeros(ComplexF64, length(sim.array))  # initialize received array
    for (source, manifold) in zip(sim.sources, sim.phaseshifts)
        v = randn(ComplexF64, length(sim.array))
        # received signal with unit-variance noise
        manifold = [f(source.θ) for f in sim.phaseshifts]
        y .+= source(t).*manifold + sqrt(sim.N₀/2)*randn(ComplexF64, length(manifold))
    end
    y
end

""" cbf(sim, fs, K)

Return the spectral power estimate of simulation `sim` using classical beamforming.
`fs` is the sampling frequency and `K` is the number of snapshots.  """
function cbf(sim::Simulation, fs, K ; ϕ = range(-π/2, π/2, length=100))
    P = length(sim.sources)
    #TODO: support more than one source
    P == 1 || error("Simulation must contain only one source")
    # snapshot instants
    T = range(0, length=K-1, step=1/fs)  # snapshot times
    max = 0.0
    doa = 0.0
    for θ in ϕ
        pbf = 0.0
        manifold = [f(θ) for f in sim.phaseshifts]'
        for t in T
            pbf += abs2(manifold*snapshot(sim, t))
        end
        if pbf > max
            doa = θ
            max = pbf
        end
    end
    doa
end

""" MUSIC(sim, fs, K)

Run the MUSIC algorithm on the simulation `sim`, sampling `K` times
at frequency `fs`.

Returns the MUSIC pseudospectrum of the simulation.  """
function MUSIC(sim::Simulation, fs, K)
    P = length(sim.sources)
    M = length(sim.array)
    # snapshot instants
    T = range(0, length=K-1, step=1/fs)  # snapshot times
    # generate received snapshots and calculate covariance matrix
    Ry = zeros(ComplexF64, M, M)  # initialize matrix
    for t in T
        y = snapshot(sim, t)
        Ry .+= y*y'
    end
    F = svd(Ry, full=true)  # in descending order
    Un = F.U[:,P+1:M]
    θ -> 1.0./sum(abs2.([f(θ) for f in sim.phaseshifts]'*Un))
end

""" findpeaks(mps, r)
Find peaks in function `mps`, defined on the range `r`.  """
function findpeaks(mps, r ; n = 1)
    ps = mps.(r)  # evaluate pseudospectrum
    peaks = [(height = 0.0, angle = 0.0)]  # largest peaks seen
    for i in 2:length(r)-1
        if (ps[i] > ps[i-1]) && (ps[i] > ps[i+1])
            for j in 1:n
                if ps[i] > peaks[j].height
                    x = (height=ps[i], angle=r[i])
                    if length(peaks) < n
                        push!(peaks,x)
                    else
                        peaks[j] = x
                    end
                    break
                end
            end
            sort!(peaks, by = x->x.height)
        end
    end
    return sort([x.angle for x in peaks])
end

""" beamwidth(S::Simulation ; c = 300e6)

Return the beamwidth (in radians) of the array in simulation `S`. As currently
implemented, the calculation is accurate only for linear arrays."""
beamwidth(S::Simulation; c = 300e6) = 0.89*(c/S.fc)/abs(maximum(S.array.d)-minimum(S.array.d))

beamwidth(a::AntennaArray, f ; c = 300e6) = 0.89*(c/f)/abs(maximum(a.d)-minimum(a.d))

end