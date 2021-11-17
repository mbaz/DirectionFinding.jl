# DirectionFinding

Tools for direction of arrival estimation in antenna arrays.

1. Define the array by specifying the distance of each antenna to a reference point.
Only linear arrays are supported at the moment.

`a = LinearArray(-12, -9, -6, -3, 0, 3, 6, 9, 12`)`

2. Define the sources. Each source is located at an angle measured from the line
perpendicular to the array's reference point. The source also specifies a baseband
signal and a signa-to-noise ratio.

`s1 = Source(pi/8, x->ComplexF64(1), 30)`

specifies a source at an angle of pi/8, with lowpass signal equal to 1, and
operating at SNR = 30 dB.

`s2 = Source(-pi/4, x->ComplexF64(1), 30)`

`s3 = Source(pi/2.1, x->ComplexF64(1), 30)`

3. Specify a simulation with one array and a set of sources, operating at a given
carrier frequency.

`S = Simulation(a, 100e6, s1, s2)`

4. Run MUSIC on the simulation with sampling frequency 10 and 100 snapshots.

`ps = MUSIC(S, 10, 100)`

The MUSIC pseudospectrum `ps` is a function of an angle.

5. Plot the pseudospectrum and observe the peaks at the source locations.

```phi = range(-pi/2, pi/2, length=1000)
plot(phi, ps.(phi)
```

6. Find the exact peak locations:

`findpeaks(ps, phi)`

7. Use a classic beamformer to estimate the location of a single source.

```S = Simulation(a, 100e6, s3)
cbf(S, 10, 1000)
```

8. Calculate the array beamwidth:

`beamwidth(S)`

or

`beamwidth(a, f)`
