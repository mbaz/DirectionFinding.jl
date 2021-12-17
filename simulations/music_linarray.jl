# Simulate MUSIC with a linear array

# before running:
#  include("../src/DirectionFinding.jl")
#  using <favorite plotting program>

using DirectionFinding

begin
    fc = 1e9
    λ = 299.79e6/fc
    N₀ = 0.01
    a1 = 5; a2 = 1.5;
    la = lineararray(11, 2λ, σ²=0.001)
    s1 = SignalSource(a1, halfsine_train(1e6))
    s2 = SignalSource(a2, halfsine_train(1e6))
    sim = Simulation(la, fc, N₀, s1, s2)
    mps = MUSIC(sim, 2.00001e6, 1000)
    ϕ = -π/2:0.01:π/2
    peaks = [p<0 ? p+2π : p for p in findpeaks(mps, ϕ, n=2)]
    println("Angles: $a1 -- $a2")
    println("Found: $(peaks[1]) -- $(peaks[2])")
    plot(ϕ, mps.(ϕ))
end