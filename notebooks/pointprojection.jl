### A Pluto.jl notebook ###
# v0.17.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 83b65e34-e6d8-44da-947b-fb66ddee5872
begin
	using Revise
	using Gaston
	using PlutoUI
	include("../src/DirectionFinding.jl")
end

# ╔═╡ 9adcf5e6-751a-43e1-b2df-41f9419cd0a5
println("Gaston version: $(Gaston.GASTON_VERSION)")

# ╔═╡ 1bfb7099-2545-4be7-9c6f-af382905abe4
println("Gaston version: $(Gaston.GASTON_VERSION)")

# ╔═╡ 3d9ebfcf-2016-473b-a21a-fc10686de6e2
md"""
Rx = $(@bind Rx Slider(-10:10, show_value=true))

Ry = $(@bind Ry Slider(-10:10, show_value=true))

Ax = $(@bind Ax Slider(-10:10, show_value=true))

Ay = $(@bind Ay Slider(-10:10, show_value=true))

θ = $(@bind θ Slider(0:0.05:2pi, show_value=true))
"""

# ╔═╡ 27b94bd0-6f8a-48d5-a57b-e4531e7e4d3f
a = DirectionFinding.Antenna(DirectionFinding.Position(Ax, Ay), x->1)

# ╔═╡ fd4935cb-c229-44df-8591-356b57ca4b34
r = DirectionFinding.Position(Rx, Ry)

# ╔═╡ 773086fe-6650-40ff-9983-fedf1595d150
P = DirectionFinding.projection(a, r, θ)

# ╔═╡ 33401b43-c0e0-4d9f-977e-9e7cc93326dd
DirectionFinding.phaseshift(a, r, θ, 300e6/2e9)

# ╔═╡ 50623d25-faab-497c-9425-00576a524584
begin
	rx = r.x; ry = r.y # reference position
	ax = a.position.x; ay = a.position.y #antenna position
	# plot source direction
	m = tan(θ); y(x) = m*(x-rx)+ry;
	plot(-10:0.1:10, y.(-10:0.1:10), w="lines lc 'black'",
	     Axes(xrange=(-11,11), yrange=(-11,11), grid=:on))
	plot!([10cos(θ)],[10sin(θ)],w="points pt 'S'")
	# plot wavefront
	mw = tan(θ+π/2); yw(x) = mw*(x-rx)+ry;
	plot!(-10:0.1:10, yw.(-10:0.1:10), w="lines lc 'red' dt 3")
	# plot array reference position
	plot!([rx], [ry], w="points pt 'R'")
	# plot antenna position
	ps = DirectionFinding.phaseshift(a, r, θ, 300e6/2e9)
	if ps > 0
		plot!([ax], [ay], w="points pt 'A' lc 'blue'")
	else
		plot!([ax], [ay], w="points pt 'A' lc 'green'")
	end
	# plot projection
	px = P.x; py = P.y;
	plot!([px], [py], w="points pt 'P'")
	# plot line from source to reference position
	plot!([ax, px], [ay, py], w="lines")
end

# ╔═╡ b324892f-9c39-4dd3-994e-e393d7d3ba64
begin
	if θ ≈ 0
		if Ax > Rx
			"in front"
		else
			"behind"
		end
	elseif θ ≈ π
		if Ax < Rx
			"in front"
		else
			"behind"
		end
	else
		mm = tan(θ+π/2);
		yy(x) = mm*(x-rx)+ry
		th = yy(ax)
		if θ <= π
			if ay < th
				(ay, th, "behind")
			else
				(ay, th, "in front")
			end
		else
			if ay > th
				(ay, th, "behind")
			else
				(ay, th, "in front")
			end
		end
	end
end

# ╔═╡ a266135f-0767-47b8-951f-cc8f785ed5fd
# check orthogonality (the plot may be deceiving)
(rx-px)*(ax-px)+(ry-py)*(ay-py)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Gaston = "4b11ee91-296f-5714-9832-002c20994614"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Revise = "295af30f-e4ad-537b-8983-00126c2a3abe"

[compat]
Gaston = "~1.0.4"
PlutoUI = "~0.7.22"
Revise = "~3.2.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.0"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "abb72771fd8895a7ebd83d5632dc4b989b022b5b"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "a851fec56cb73cfdf43762999ec72eff5b86882a"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.15.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Gaston]]
deps = ["ColorSchemes", "DelimitedFiles", "Random"]
git-tree-sha1 = "ef62952980d19c98d00bd44d2266a98f8e9c7178"
uuid = "4b11ee91-296f-5714-9832-002c20994614"
version = "1.0.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "e273807f38074f033d94207a201e6e827d8417db"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.8.21"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "491a883c4fef1103077a7f648961adbf9c8dd933"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.1.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "565564f615ba8c4e4f40f5d29784aa50a8f7bbaf"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.22"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "6f2bc8f1a444f93c52163e6f82270877224632d0"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.2.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═83b65e34-e6d8-44da-947b-fb66ddee5872
# ╠═9adcf5e6-751a-43e1-b2df-41f9419cd0a5
# ╟─1bfb7099-2545-4be7-9c6f-af382905abe4
# ╟─3d9ebfcf-2016-473b-a21a-fc10686de6e2
# ╟─27b94bd0-6f8a-48d5-a57b-e4531e7e4d3f
# ╟─fd4935cb-c229-44df-8591-356b57ca4b34
# ╟─773086fe-6650-40ff-9983-fedf1595d150
# ╠═33401b43-c0e0-4d9f-977e-9e7cc93326dd
# ╠═b324892f-9c39-4dd3-994e-e393d7d3ba64
# ╠═50623d25-faab-497c-9425-00576a524584
# ╠═a266135f-0767-47b8-951f-cc8f785ed5fd
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
