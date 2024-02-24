### A Pluto.jl notebook ###
# v0.19.39

using Markdown
using InteractiveUtils

# ╔═╡ d057fdb3-b4a8-4488-8b67-2472d4ccd8b1
begin
	using PlutoUI, Markdown
	TableOfContents()
end

# ╔═╡ 58603967-54e1-4904-9f8e-6ad2113dbc04
md"""
# Blog Post Notes

## Results and Approach Summary
- Benchmark test of 30 problems with AlphaGeometry solving 25
- Equal performance to the average human gold medalist
- Previous state of the art AI solution could only solve 10

![Results Image](https://lh3.googleusercontent.com/y7r-p8VmkqSLE0ZcwidAO0osQ1Sz1y4FBhwQNkv7t1M5bajHTvCu1vTYxDmVJZ2WuknpHeQB2E6RkPUEu-fAVoAxgh8thMPR6bcK4NFyGFuQ4mo5=w1232-rw)
"""

# ╔═╡ 9c0f18f3-aae9-4881-ade0-ef165c41f2da
md"""
- Neuro-symbolic approach used to solve problems
- Symbolic engine deduces statements about the diagram until every true statement has been exhuasted
- Language model proposes adding new constructs to image which the symbolic engine evaluates
- Loop continues until a solution is found
![](https://lh3.googleusercontent.com/CXoZ8QVYA7wKFPt3RurU7Z0SDyp32YQS9gJaEwE-U1AtjAQ-eXEaGxnOSTUH01oyN7YOxz-BILe390w2wHVEFF7XPmCOzqr0QMBroKc4J5kPFyqYVqU=w1232-rw)
"""

# ╔═╡ 31dff0ab-cabf-44d9-aac8-bc3c7bdf9da9
md"""
- Example solving problem 3 of the 2015 olympiad
- Blue elements are added constructs

![Solution found by AlphaGeometry to 2015 IMO problem 3](https://lh3.googleusercontent.com/XEyvy2yOfpwazku1bh2mgN48QquA21bUXscAAYOSp34kN-qb1E6glno62gNSqSth921OVJ5nBBT8GNFiVg1nwv3U2jd3vo6YCFENsn3qBD9yQZsD=w1232-rw)
"""

# ╔═╡ 07c3d82e-0fbe-4261-9bb6-6c695289250a
md"""
## Training Strategy

- Generated one billion random geometric diagrams and exhaustively derived every relationship in them
- Found all proofs in these example diagrams and worked backwards to find out what additional constructs were needed for the proofs
- Process called "symbolic deduction and traceback"
![Synthetic data examples](https://lh3.googleusercontent.com/I2xcIu8Js4iZP89NPUe2Cr_43To5aamQNzzXDsDD_PamVRJQFZQ7SUdu6zJVlXAJ2Gq6fnINeHzsQeY5ugdSFzdnAaSrIuYcLsgSfJLDjJalifcD=w1232-rw)

- Similar examples were excluded resulting in a final training dataset of 100 million unique examples, nine million of which require adding constructs
- Only two of the six IMO problems are typically focused on geometry so on the full IMO this would reach the bronze medal threshold.
"""

# ╔═╡ 0868bb96-4c1a-4889-8725-486c58167bbc
md"""
# Paper Notes

## Abstract
- Applying machine learning to geometry is difficult due to the difficulty of translating diagrams into a format suitable for algorithms
- AlphaGeometry is trained on a large-scale synthetic dataset and produces human-readable proofs

## Main
- Current approaches to geometry rely upon symbolic methods with human designed search heuristics
- Alternative approach sidesteps the need to translate human-provided proof examples by using synthetic data based on Euclidean plane geometry
- Existing symbolic engines can be used to generate proofs with over 200 steps
- Also produce proofs that require adding additional constructs to the problem which is more complex than using pure deductive reasoning on the provided diagram
- Language model is pretrained on all generated synthetic data and then fine-tuned on auxiliary construction with all deduction proof steps delegated to the specialized symbolic engines

![Architecture overview with proof example](https://media.springernature.com/full/springer-static/image/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Fig1_HTML.png?as=webp)

- In step b, the symbolic deduction engine exhaustively deduces new statements from the theorem premises until the theorem is proven or new statements are exhausted
- In step c, the language model constructs one auxiliary point, growing the proof state before the symbolic engine retries
- In step d, the loop terminates after the first auxiliary construction which is "D as the midpoint of BC".  The proof consists of two other steps, both of which make use of teh midpoint properties: "BD=DC" and "B, D, C are collinear" highlighted in blue
"""

# ╔═╡ 5ca581ff-9070-47d1-b70c-556f449d700c
md"""
## Synthetic theorems and proofs generation

![AlphaGeometry synthetic-data-generation process](https://media.springernature.com/full/springer-static/image/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Fig3_HTML.png?as=webp)

- Synthetic generation process
    1. Sample a large set of random theorem premises
    2. Use symbolic deduction engine to obtain an acyclic graph of statements and perform a traceback to find the minimal set of necessary promise and dependency deductions (e.g. the rightmost node $\text{HA} \perp \text{BC}$ traceback returns the green subgraph)
    3. The minimal premise and the corresponding subgraph constitute a synthetic problem and its solution.  In the bottom example, points E and D took part in the proof despite being irrelevant to the construction of HA and BC; therefore, they are learned by the language model as auxiliary constructions
- Each example consists of a set of (premises, conclusion, proof) = $(P, N, G(N))$
- The deduction engine is a deductive database that follows deduction rules in the form of definite Horn clauses $Q(x) \leftarrow P_1(x), \dots, P_k(x)$ in which $x$ are points objects, whereas $P_1, \dots, P_k$ and $Q$ are predicates such as 'equal segments' or 'collinear'
- Algebraic rules are added to the symbolic engine which is necessary to perform angle, ratio, and distance chasing as often is required in olympiad proofs

## Generating proofs beyond symbolic deduction
- In any example, there are some statements in $P$ that $N$ is independent of.  We move these statements from $P$ into the proof so that a generative model can learn to construct them
- Deduction engines are not designed to add these constructs as these would introduce infinite branching in the search tree
- Previous attempts to generate these auxiliary constructs rely on hand-crafted templates and domain-specific heuristics
- AlphaGeometry learns to make these constructions without any human demonstrations

## Training a language model on synthetic data
- Each example $$(P, N, G(N))$$ is serialized into a text string with the structure '<premises><conclusion><proof>'
- Language model learns to generate the proof, conditioning on the theorem premises and conclusion

## Combining language modelling and symbolic engines
- The language model is seeded with the problem statement string and generates one extra sentence at each turn, conditioning on the problem statement and past construction
- Each time the language model generates a new construct such as "construct point X so that ABCX is a parallelogram", the symbolic engine is provided with new inputs and could potentially reach a new conclusion
- Beam search is used to explore the top $k$ constructions generated by the language model
"""

# ╔═╡ 7a48a6a9-dcca-414e-be16-f820214df5c3
md"""
## Empirical evaluation
- Adapted geometry problems from the IMO competitions since 2000 to a narrower specialized environment for classical geometry
- Among all non-combinatorial geometry-related problems, 75% can be represented, resulting in a test set of 30 classical geometry problems
- Dataset is called IMO-AG-30

## Geometry theorem prover baselines
- Category 1: Computer algebra methods
    - Geometry statements are treated as polynomial equations of its point coordinates
    - Specialized transformations of large polynomials are used
    - Large time and memory complexity of these solutions means success is assigned based on deciding a problem within 48 hours
- Category 2: Search/axiomatic or synthetic methods
    - Perform a step-by-step search using geometry axioms
    - Proofs are often interpretable by human readers
    - Often combine symbolic engines with human-designed heuristics (e.g. If $\text{OA} \perp \text{OB}$ and $\text{OA}=\text{OB}$, construct C on the opposite ray of OA such that OC=OA)
    - Language models such as GPT-4 could be considered for generating statements in this category but GPT-4 has a success rate of 0% on the proofs in IMO-AG-30 often making syntactic and semantic errors
    - Search methods like this have no theoretical guarantee in their proving performance
### Synthetic data generation rediscovers known theorems and beyond
![Analyzing synthetic data](https://media.springernature.com/full/springer-static/image/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Fig4_HTML.png?as=webp)
- Only 9% of generated proofs have auxiliary constructions
- Only 0.05% of synthetic training proofs are longer than the average AlphaGeometry proof for the test-set problems
- Most complex synthetic proof has a length of 247 with two auxiliary constructions and most proofs don't have human biases towards symmetry
- Language model was pretrained on all 100 million synthetic proofs and then fine-tuned on the 9% that required auxiliary constructions
## Proving results on IMO-AG-30

### Main results on IMO-AG-30 test benchmark
See [Supplementary Information](https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_MOESM1_ESM.pdf) for how GPT-4 was prompted for both full proofs and auxiliary constructions.  AlphaGeometry achieves the best result with 25 problems solved in total

|Method Category|Method|Problems solved (out of 30)|
|:--|:--|:--|
|Computer algebra| Wu's method (previous state of the art)|10|
|Computer algebra| Gröbner basis|4|
|Search (human-like)|GPT-4|0|
|Search (human-like)|Full-angle method|2|
|Search (human-like)|Deductive database (DD)|7|
|Search (human-like)|DD + human-designed heuristics|9|
|Search (human-like)|DD+AR (ours)|14|
|Search (human-like)|DD+AR+GPT-4 auxiliary constructions|15|
|Search (human-like)|DD+AR+human-designed heuristics|18|
|Search (human-like)|AlphaGeometry|25|
|Search (human-like)|• Without pretraining|21|
|Search (human-like)|• Without fine-tuning|23|

- The strongest baseline is (DD+AR+human-designed heuristics) which solved 18 problems
- To match the test time compute of AlphaGeometry, this strongest baseline makes use of 250 parallel workers running fro 1.5h, each attempting different sets of auxiliary constructions suggested by human-designed heuristics in parallel, until success or timeout
- From the base symbolic deduction engine (DD), adding algebraic deduction added sevel solved problems for a total of 14, whereas the language model's auxiliary construction added another 11 solved problems resulting in a total of 25
- Using only 20% of the training data, AlphaGeometry still achieves state-of-the-art results with 21 solved problems
- On a larger set of 231 geometry problems, The performance rankings remain unchanged with AlphaGeometry solving almost all problems (98.7%) whereas the strongest baseline only solves 92.2%

![Extended results table](https://media.springernature.com/full/springer-static/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Fig12_ESM.jpg?as=webp)

![AlphaGeometry discovers a more general theorem than the translated IMO 2004P1](https://media.springernature.com/full/springer-static/image/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Fig5_HTML.png?as=webp)
"""

# ╔═╡ 876380f2-48c7-4e0d-875b-1e2deff32fa9
md"""
![List of actions to construct random premises](https://media.springernature.com/lw620/springer-static/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Tab1_ESM.jpg)

![Three examples of algebraic reasoning (AR) in geometry theorem proving](https://media.springernature.com/lw1015/springer-static/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Tab2_ESM.jpg)

![Examples of auxiliary constructions in four different domains](https://media.springernature.com/lw554/springer-static/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Tab3_ESM.jpg)

![Comparison between a geometry proof and an IMO inequality proof through the lens of the AlphaGeometry framework](https://media.springernature.com/lw498/springer-static/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_Tab4_ESM.jpg)
"""

# ╔═╡ fc87781f-124d-4c9c-9db1-eb95724466b4
md"""
# References

[DeepMind Blog Post](https://deepmind.google/discover/blog/alphageometry-an-olympiad-level-ai-system-for-geometry/)

[IMO 2022 Shortlisted Problems](https://www.imo-official.org/problems/IMO2022SL.pdf)

[Nature Publication: Solving olympiad geometry without human demonstrations](https://www.nature.com/articles/s41586-023-06747-5)

[AlphaGeometry Github Repository](https://github.com/google-deepmind/alphageometry)

[Supplementary Information](https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-023-06747-5/MediaObjects/41586_2023_6747_MOESM1_ESM.pdf)

[Meliad Transformer Library](https://github.com/google-research/meliad)
"""

# ╔═╡ a0522ca4-d350-11ee-0394-97e03aa1457e
md"""
# Dependencies
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.58"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0-rc2"
manifest_format = "2.0"
project_hash = "777ef5837957fd94e74be8a798964fa184633015"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "c278dfab760520b8bb7e9511b968bf4ba38b7acc"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "8b72179abc660bfab5e28472e019392b97d0985c"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.4"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+2"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "71a22244e352aa8c5f0f2adde4150f62368a3f2e"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.58"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─58603967-54e1-4904-9f8e-6ad2113dbc04
# ╟─9c0f18f3-aae9-4881-ade0-ef165c41f2da
# ╟─31dff0ab-cabf-44d9-aac8-bc3c7bdf9da9
# ╟─07c3d82e-0fbe-4261-9bb6-6c695289250a
# ╟─0868bb96-4c1a-4889-8725-486c58167bbc
# ╟─5ca581ff-9070-47d1-b70c-556f449d700c
# ╟─7a48a6a9-dcca-414e-be16-f820214df5c3
# ╟─876380f2-48c7-4e0d-875b-1e2deff32fa9
# ╟─fc87781f-124d-4c9c-9db1-eb95724466b4
# ╟─a0522ca4-d350-11ee-0394-97e03aa1457e
# ╠═d057fdb3-b4a8-4488-8b67-2472d4ccd8b1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
