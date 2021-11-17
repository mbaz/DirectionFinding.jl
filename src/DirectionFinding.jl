module DirectionFinding

using LinearAlgebra

export LinearArray,
       Source,
       Simulation,
       cbf,
       MUSIC,
       findpeaks,
       beamwidth

abstract type AntennaArray end

""" LinearArray(M, d)

Define a uniform linear array with the following fields:

    `M::Int` : number of elements in the array.

    `d::Vector{Float64}` : distance from each array element
                           to the array's reference point.
"""
struct LinearArray <: AntennaArray
    M  :: Int
    d  :: Vector{Float64}
end

LinearArray(d...) = LinearArray(length(d), [x for x in d])

""" distances((LA::LinearArray)

Return the vector of distances from each element of linear array `LA`
to the array's reference point.
"""
distances(LA::LinearArray) = LA.d

Base.length(LA::LinearArray) = LA.M

""" Source(Θ, sbb, fc)

Return a signal source with the following fields:

    `Θ   :: Float64`  : Angle between a line orthogonal to the array's
                        reference point and the source.
    `sbb :: Function` : function that returns the transmitted lowpass
                        complex signal evaluated at snapshot instants `t`.
    `snr :: Float64   : The source's SNR
"""
struct Source
    Θ      :: Float64
    sbb    :: Function
    snr    :: Float64

    Source(Θ, sbb, snr_db) = new(Θ, sbb, 10.0^(snr_db/10.0))
end


""" Source(t)

Return the lowpass complex signal produced by the source `s` at time `t`.
"""
(s::Source)(t) = s.sbb(t)

struct Simulation{T, S}
    array   :: T
    sources :: S
    fc      :: Float64
    precam  :: Vector{Vector{ComplexF64}}  # precalculated array manifolds
end

function Simulation(a, fc, s::Vararg{Source,N}) where {N}
    am = Vector{Vector{ComplexF64}}()
    for source in s
        push!(am, arraymanifold(a, source.Θ, fc))
    end
    Simulation(a, s, fc, am)
end

""" arraymanifold
Return the array manifold of an array for a given angle
"""
function arraymanifold(a::LinearArray, Θ, fc ; c = 300e6)
    λ = c/fc
    X = 1im*2π*sin(Θ).*distances(a)./λ
    exp.(X)
end

""" snapshot()
Return a snapshot of the signal received by the array at time `t`"
"""
function snapshot(sim::Simulation, t ; c = 300e6)
    y = zeros(ComplexF64, sim.array.M)  # initialize received array
    for (source, manifold) in zip(sim.sources, sim.precam)
        # calculate noise
        v = randn(ComplexF64, length(sim.array))
        # received signal with unit-variance noise
        snr = source.snr
        y .+= sqrt(snr)*source(t).*manifold .+ v
    end
    y
end

""" cbf(S, fs, K)
Return the spectral power estimate of simulation `S` using classical beamforming.
`fs` is the sampling frequency and `K` is the number of snapshots.
"""
function cbf(sim::Simulation, fs, K ; ϕ = range(-π/2, π/2, length=100))
    P = length(sim.sources)
    P == 1 || error("Simulation must contain only one source")
    M = length(sim.array)
    # snapshot instants
    T = range(0, length=K-1, step=1/fs)  # snapshot times
    max = 0.0
    doa = 0.0
    for Θ in ϕ
        pbf = 0.0
        a = arraymanifold(sim.array, Θ, sim.fc)'
        for t in T
            pbf += abs2(a*snapshot(sim, t))
        end
        if pbf > max
            doa = Θ
            max = pbf
        end
    end
    doa
end

""" MUSIC(S)
Run the MUSIC algorithm on the simulation specified by `S`, sampling `K` times
at frequency `fs`.

Returns the MUSIC pseudospectrum of the simulation `S`.
"""
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
    mps = Θ -> 1.0./sum(abs2.(arraymanifold(sim.array, Θ, sim.fc)'*Un))
end

""" findpeaks(mps, r)
Return the peaks in function `mps`, defined on the range `r`.
"""
function findpeaks(mps, r; threshold = 5)
    ps = mps.(r)  # evaluate pseudospectrum
    m = minimum(ps)*threshold
    peaks = Float64[]
    for i in 2:length(r)-1
        if (ps[i] > m) && (ps[i] > ps[i-1]) && (ps[i] > ps[i+1])
            push!(peaks, r[i])
        end
    end
    return peaks
end

""" beamwidth(S::Simulation ; c = 300e6)

Return the beamwidth (in radians) of the array in simulation `S`.

beamwidth(a::LinearArray, f ; c = 300e6)

Return the beamwidth of array `a` at frequency `f`.

"""
beamwidth(S::Simulation; c = 300e6) = 0.89*(c/S.fc)/abs(maximum(S.array.d)-minimum(S.array.d))

beamwidth(a::LinearArray, f ; c = 300e6) = 0.89*(c/f)/abs(maximum(a.d)-minimum(a.d))


end
