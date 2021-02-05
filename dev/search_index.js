var documenterSearchIndex = {"docs":
[{"location":"#VectorizationBase.jl","page":"Home","title":"VectorizationBase.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [VectorizationBase]","category":"page"},{"location":"#VectorizationBase.AbstractStridedPointer","page":"Home","title":"VectorizationBase.AbstractStridedPointer","text":"abstract type AbstractStridedPointer{T,N,C,B,R,X,O} end\n\nT: element type N: dimensionality C: contiguous dim B: batch size R: rank of strides X: strides O: offsets\n\n\n\n\n\n","category":"type"},{"location":"#VectorizationBase.GroupedStridedPointers","page":"Home","title":"VectorizationBase.GroupedStridedPointers","text":"P are the pointers I contains indexes into strides (dynamic) and X (static) X static strides\n\n\n\n\n\n","category":"type"},{"location":"#VectorizationBase.MM","page":"Home","title":"VectorizationBase.MM","text":"The name MM type refers to MM registers such as XMM, YMM, and ZMM. MMX from the original MMX SIMD instruction set is a [meaningless initialism](https://en.wikipedia.org/wiki/MMX(instruction_set)#Naming).\n\nThe MM{W,X} type is used to represent SIMD indexes of width W with stride X.\n\n\n\n\n\n","category":"type"},{"location":"#VectorizationBase.Unroll","page":"Home","title":"VectorizationBase.Unroll","text":"Unroll{AU,F,N,AV,W,M}(i::I)\n\nAU: Unrolled axis\nF: Factor, step size per unroll. If AU == AV, F == W means successive loads. 1 would mean offset by 1, e.g. x{1:8], x[2:9], and x[3:10].\nN: How many times is it unrolled\nAV: Vectorized axis # 0 means not vectorized, some sort of reduction\nW: vector width\nX: stride between loads of vectors along axis AV.\nM: bitmask indicating whether each factor is masked\ni::I - index\n\n\n\n\n\n","category":"type"},{"location":"#VectorizationBase._vrangeincr-Union{Tuple{SIRS}, Tuple{F}, Tuple{O}, Tuple{I}, Tuple{W}, Tuple{Val{W}, I, Val{O}, Val{F}, StaticInt{SIRS}}} where {W, I<:Integer, O, F, SIRS}","page":"Home","title":"VectorizationBase._vrangeincr","text":"vrange(::Val{W}, i::I, ::Val{O}, ::Val{F})\n\nW - Vector width i::I - dynamic offset O - static offset F - static multiplicative factor\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.align","page":"Home","title":"VectorizationBase.align","text":"align(x::Union{Int,Ptr}, [n])\n\nReturn aligned memory address with minimum increment. align assumes n is a power of 2.\n\n\n\n\n\n","category":"function"},{"location":"#VectorizationBase.bitselect-Tuple{Any, Any, Any}","page":"Home","title":"VectorizationBase.bitselect","text":"bitselect(m::Unsigned, x::Unsigned, y::Unsigned)\n\nIf you have AVX512, setbits of vector-arguments will select bits according to mask m, selecting from x if 0 and from y if 1. For scalar arguments, or vector arguments without AVX512, setbits requires the additional restrictions on y that all bits for which m is 1, y must be 0. That is for scalar arguments or vector arguments without AVX512, it requires the restriction that ((y ⊻ m) & m) == m\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.grouped_strided_pointer-Union{Tuple{G}, Tuple{N}, Tuple{Tuple{Vararg{AbstractArray, N}}, Val{G}}} where {N, G}","page":"Home","title":"VectorizationBase.grouped_strided_pointer","text":"G is a tuple(tuple((Aind,A's dim),(Aind,A's dim)), ()) it gives the groups.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.ifmahi-Tuple{Any, Any, Any}","page":"Home","title":"VectorizationBase.ifmahi","text":"ifmalo(v1, v2, v3)\n\nMultiply unsigned integers v1 and v2, adding the upper 52 bits to v3.\n\nRequires has_feature(Val(:x86_64_avx512ifma)) to be fast.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.ifmalo-Tuple{Any, Any, Any}","page":"Home","title":"VectorizationBase.ifmalo","text":"ifmalo(v1, v2, v3)\n\nMultiply unsigned integers v1 and v2, adding the lower 52 bits to v3.\n\nRequires has_feature(Val(:x86_64_avx512ifma)) to be fast.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.inv_approx-Tuple{Any}","page":"Home","title":"VectorizationBase.inv_approx","text":"Fast approximate reciprocal.\n\nGuaranteed accurate to at least 2^-14 ≈ 6.103515625e-5.\n\nUseful for special funcion implementations.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.lazymul-Union{Tuple{N}, Tuple{I}, Tuple{StaticInt{I}, Any, Tuple{Vararg{Any, N}}}} where {I, N}","page":"Home","title":"VectorizationBase.lazymul","text":"Basically:\n\nif I ∈ [3,5,7,9]     c[(I - 1) >> 1] else     b * I end\n\nbecause\n\nc = b .* [3, 5, 7, 9]\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.offset_ptr-Union{Tuple{T}, Tuple{Type{T}, Symbol, Char, Int64, Int64, Int64, Int64, Int64, Bool, Int64}} where T","page":"Home","title":"VectorizationBase.offset_ptr","text":"An omnibus offset constructor.\n\nThe general motivation for generating the memory addresses as LLVM IR rather than combining multiple lllvmcall Julia functions is that we want to minimize the inttoptr and ptrtoint calculations as we go back and fourth. These can get in the way of some optimizations, such as memory address calculations. It is particulary import for gather and scatters, as these functions take a Vec{W,Ptr{T}} argument to load/store a Vec{W,T} to/from. If sizeof(T) < sizeof(Int), converting the <W x $(typ)* vectors of pointers in LLVM to integer vectors as they're represented in Julia will likely make them too large to fit in a single register, splitting the operation into multiple operations, forcing a corresponding split of the Vec{W,T} vector as well. This would all be avoided by not promoting/widenting the <W x $(typ)> into a vector of Ints.\n\nFor this last issue, an alternate workaround would be to wrap a Vec of 32-bit integers with a type that defines it as a pointer for use with internal llvmcall functions, but I haven't really explored this optimization.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.pause-Tuple{}","page":"Home","title":"VectorizationBase.pause","text":"pause()\n\nFor use in spin-and-wait loops, like spinlocks.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.preserve_buffer-Tuple{AbstractArray}","page":"Home","title":"VectorizationBase.preserve_buffer","text":"For structs wrapping arrays, using GC.@preserve can trigger heap allocations. preserve_buffer attempts to extract the heap-allocated part. Isolating it by itself will often allow the heap allocations to be elided. For example:\n\njulia> using StaticArrays, BenchmarkTools\n\njulia> # Needed until a release is made featuring https://github.com/JuliaArrays/StaticArrays.jl/commit/a0179213b741c0feebd2fc6a1101a7358a90caed\n       Base.elsize(::Type{<:MArray{S,T}}) where {S,T} = sizeof(T)\n\njulia> @noinline foo(A) = unsafe_load(A,1)\nfoo (generic function with 1 method)\n\njulia> function alloc_test_1()\n           A = view(MMatrix{8,8,Float64}(undef), 2:5, 3:7)\n           A[begin] = 4\n           GC.@preserve A foo(pointer(A))\n       end\nalloc_test_1 (generic function with 1 method)\n\njulia> function alloc_test_2()\n           A = view(MMatrix{8,8,Float64}(undef), 2:5, 3:7)\n           A[begin] = 4\n           pb = parent(A) # or `LoopVectorization.preserve_buffer(A)`; `perserve_buffer(::SubArray)` calls `parent`\n           GC.@preserve pb foo(pointer(A))\n       end\nalloc_test_2 (generic function with 1 method)\n\njulia> @benchmark alloc_test_1()\nBenchmarkTools.Trial:\n  memory estimate:  544 bytes\n  allocs estimate:  1\n  --------------\n  minimum time:     17.227 ns (0.00% GC)\n  median time:      21.352 ns (0.00% GC)\n  mean time:        26.151 ns (13.33% GC)\n  maximum time:     571.130 ns (78.53% GC)\n  --------------\n  samples:          10000\n  evals/sample:     998\n\njulia> @benchmark alloc_test_2()\nBenchmarkTools.Trial:\n  memory estimate:  0 bytes\n  allocs estimate:  0\n  --------------\n  minimum time:     3.275 ns (0.00% GC)\n  median time:      3.493 ns (0.00% GC)\n  mean time:        3.491 ns (0.00% GC)\n  maximum time:     4.998 ns (0.00% GC)\n  --------------\n  samples:          10000\n  evals/sample:     1000\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.promote_div-Tuple{Union{Integer, Union{VectorizationBase.AbstractSIMDVector{var\"#s2\", var\"#s1\"}, VectorizationBase.VecUnroll{var\"#s3\", var\"#s2\", var\"#s1\", V} where {var\"#s3\", V<:VectorizationBase.AbstractSIMDVector{var\"#s2\", var\"#s1\"}}} where {var\"#s2\", var\"#s1\"<:Integer}}, Union{Integer, Union{VectorizationBase.AbstractSIMDVector{var\"#s138\", var\"#s139\"}, VectorizationBase.VecUnroll{var\"#s3\", var\"#s138\", var\"#s139\", V} where {var\"#s3\", V<:VectorizationBase.AbstractSIMDVector{var\"#s138\", var\"#s139\"}}} where {var\"#s138\", var\"#s139\"<:Integer}}}","page":"Home","title":"VectorizationBase.promote_div","text":"Promote, favoring <:Signed or <:Unsigned of first arg.\n\n\n\n\n\n","category":"method"},{"location":"#VectorizationBase.unrolled_indicies-NTuple{6, Int64}","page":"Home","title":"VectorizationBase.unrolled_indicies","text":"Returns a vector of expressions for a set of unrolled indices.\n\n\n\n\n\n","category":"method"}]
}
