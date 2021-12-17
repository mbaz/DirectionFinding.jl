# simulate MUSIC with a random array
using DirectionFinding

begin
    fc = 1e9
    λ = 299.79e6/fc
    a1 = 0.95; a2 = 6; 
    N₀ = 0.01
    ra = randomarray(5, 1)
    s1 = SignalSource(a1, halfsine_train(1e6))
    s2 = SignalSource(a2, halfsine_train(1e6))
    sim = Simulation(ra, fc, N₀, s1, s2)
    mps = MUSIC(sim, 2.00001e6, 1000)
    ϕ = 0:0.01:2π-0.01
    peaks = findpeaks(mps, ϕ, n=2)
    println("Angles: $a1 -- $a2")
    println("Found: $(peaks[1]) -- $(peaks[2])")
    plot(ϕ, mps.(ϕ))
end