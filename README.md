# DirectionFinding

Tools for direction of arrival estimation in antenna arrays. Examples using classic beamforming and MUSIC on several array topologies are found in the `simulations` directory.

Example:

1. Specify carrier frequency and wavelength

```fc = 1e9
λ = 299.79e6/fc
```

2. Define the antenna array. For example, a circular array with 11 antennas centered on the
origin (which is the array's reference point), with radius `2λ`, is specified as:

`ca = circulararray(11, 2λ, σ²=0.0001)`

The parameter `σ²=0.0001` introduces a random, Gaussian variation of variance `σ²` in the antenna positions.

2. Define the signal sources. Each source is located at an angle measured from a horizontal line that extends from the array's reference point towards +infinity.

```
a1 = 0.95; a2 = 6;
s1 = SignalSource(a1, halfsine_train(1e6))
s2 = SignalSource(a2, halfsine_train(1e6))
```

Each source is specified by its angle, and by the baseband signal it generates (here, a train of half-sine pulses at rate 1 MBd.)

2. Specify the noise power density at each receiver.

`N₀ = 0.1`

3. Specify a simulation with one array, carrier frequency, noise density, and a set of sources:

`sim = Simulation(ca, fc, N₀, s1, s2)`

4. Run MUSIC on the simulation with sampling frequency `2.00001e6` and 1000 snapshots.

`mps = MUSIC(sim, 2.00001e6, 1000)`

The MUSIC pseudospectrum `mps` is a function of an angle.

5. Plot the pseudospectrum and observe the peaks at the source locations.

```phi = range(-pi/2, pi/2, length=1000)
plot(phi, mps.(phi)
```

6. Find the exact peak locations. This function returns the `n` largest peaks:

`findpeaks(mps, phi, n=2)`

7. Alternatively use a classic beamformer to estimate the location of a single source.

```
sim = Simulation(a, 2.00001e6, s1)
cbf(sim, 2.000013e6, 1000)
```

8. Calculate the array beamwidth (only accurate for linear arrays):

`beamwidth(sim)`

or

`beamwidth(a, f)`