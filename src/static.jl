#TODO: Document interface to support static size
# Define maybestaticsize, maybestaticlength, and maybestaticfirstindex



@eval struct Static{N} <: Number
    (f::Type{<:Static})() = $(Expr(:new,:f))
end
Base.@pure Static(N) = Static{N}()
const Zero = Static{0}
const One = Static{1}
@inline Static(::Val{N}) where {N} = Static{N}()
@inline Static(::Nothing) = nothing
@inline Base.Val(::Static{N}) where {N} = Val{N}()
@generated function static_sizeof(::Type{T}) where {T}
    Expr(:block, Expr(:meta, :inline), Expr(:call, Expr(:curly, :Static, sizeof(T))))
end

@inline Base.CartesianIndex(I::Tuple{Vararg{Union{Integer,CartesianIndex,CartesianVIndex,Static}}}) = CartesianVIndex(I)

Base.promote_rule(::Type{<:Static}, ::Type{T}) where {T <: NativeTypes} = T
Base.convert(::Type{T}, ::Static{N}) where {T <: Number, N} = convert(T, N)


@inline Base.:(:)(::Static{L}, ::Static{U}) where {L,U} = ArrayInterface.OptionallyStaticUnitRange{T}(Val{L}(), Val{U}())
@inline Base.:(:)(::Static{L}, U::Int) where {L} = ArrayInterface.OptionallyStaticUnitRange{T}(Val{L}(), U)
@inline Base.:(:)(L::Int, ::Static{U}) where {U} = ArrayInterface.OptionallyStaticUnitRange{T}(L, Val{U}())
@inline unwrap(x) = x
@inline unwrap(::Val{N}) where {N} = N
@inline unwrap(::Type{Val{N}}) where {N} = N
@inline unwrap(::Static{N}) where {N} = N
@inline unwrap(::Type{Static{N}}) where {N} = N

@inline static_last(::Type{T}) where {T} = Static(known_last(T))
@inline static_first(::Type{T}) where {T} = Static(known_first(T))
@inline static_length(::Type{T}) where {T} = Static(known_length(T))

@inline _maybestaticfirst(a, ::Nothing) = first(a)
@inline _maybestaticfirst(::Any, ::Static{L}) where {L} = Static{L}()
@inline maybestaticfirst(a::T) where {T} = _maybestaticfirst(a, known_first(T))

@inline _maybestaticlast(a, ::Nothing) = last(a)
@inline _maybestaticlast(::Any, ::Static{L}) where {L} = Static{L}()
@inline maybestaticlast(a::T) where {T} = _maybestaticlast(a, known_last(T))

@inline _maybestaticsize(a, ::Nothing) = length(a)
@inline _maybestaticsize(::Any, ::Static{L}) where {L} = Static{L}()
@inline maybestaticlength(a::T) where {T} = _maybestaticsize(a, known_length(T))
@inline maybestaticsize(A, ::Val{I}) where {I} = size(A, I)
@inline maybestaticsize(A, ::Val{I}) where {I} = maybestaticlength(axes(A, I))
# @inline maybestaticsize(A::AbstractArray{<:Any,0}, ::Val{1:2}) = (1, 1)
# @inline maybestaticsize(A::AbstractVector, ::Val{1:2}) = (length(A), 1)
# @inline maybestaticsize(A::AbstractMatrix, ::Val{1:2}) = size(A)
# @inline maybestaticsize(A::AbstractArray, ::Val{1:2}) = (size(A,1),size(A,2))
# Former is not type stable
# @inline maybestaticsize(A::AbstractArray{<:Any,N}) where {N} = ntuple(n -> maybestaticsize(A, Val{n}()), Val{N}())
@generated function maybestaticsize(A::AbstractArray{<:Any,N}) where {N}
    out = Expr(:tuple)
    foreach(n -> push!(out.args, :(maybestaticsize(A, Val{$n}()))), 1:N)
    out
end
@inline maybestaticlength(A) = length(A)

# @inline maybestaticfirstindex(A::AbstractArray, ::Val{I}) where {I} = firstindex(A, I)
# @inline maybestaticfirstindex(A::Array, ::Val{I}) where {I} = One()
                  

# @inline maybestaticeachindex(A::AbstractArray) = maybestaticrange(eachindex(A))

@inline maybestaticrange(r::Base.OneTo{T}) where {T} = ArrayInterface.OptionallyStaticUnitRange{T}(Val{1}(), last(r))
@inline maybestaticrange(r::UnitRange) = r
@inline maybestaticrange(r::AbstractStaticUnitRange) = r
@inline maybestaticrange(r) = maybestaticfirst(r):maybestaticlast(r)
# @inline maybestaticaxis(A::AbstractArray, ::Val{I}) where {I} = maybestaticfirstindex(A, Val{I}()):maybestaticsize(A, Val{I}())

@inline maybestaticsize(::NTuple{N}, ::Val{1}) where {N} = Static{N}() # should we assert that i == 1?
@inline maybestaticlength(::NTuple{N}) where {N} = Static{N}()
@inline maybestaticsize(::Adjoint{T,V}, ::Val{1}) where {T,V<:AbstractVector{T}} = One()
@inline maybestaticsize(::Transpose{T,V}, ::Val{1}) where {T,V<:AbstractVector{T}} = One()
@inline maybestaticlength(B::Adjoint) = maybestaticlength(parent(B))
@inline maybestaticlength(B::Transpose) = maybestaticlength(parent(B))
@inline maybestaticsize(B::Adjoint{T,A}, ::Val{1}) where {T,A<:AbstractMatrix{T}} = maybestaticsize(parent(B), Val{2}())
@inline maybestaticsize(B::Adjoint{T,A}, ::Val{2}) where {T,A<:AbstractMatrix{T}} = maybestaticsize(parent(B), Val{1}())
@inline maybestaticsize(B::Transpose{T,A}, ::Val{1}) where {T,A<:AbstractMatrix{T}} = maybestaticsize(parent(B), Val{2}())
@inline maybestaticsize(B::Transpose{T,A}, ::Val{2}) where {T,A<:AbstractMatrix{T}} = maybestaticsize(parent(B), Val{1}())

@inline Base.iszero(::Zero) = true
@inline Base.iszero(::Static) = false
@generated function Base.divrem(N::Integer, ::Static{L}) where {L}
    if ispow2(L)
        quote
            $(Expr(:meta,:inline))
            d = N >>> $(intlog2(L))
            r = N & $(L-1)
            d, r
        end
    else
        quote
            $(Expr(:meta,:inline))
            vdivrem(N, $L)
        end
    end
end


@generated Base.divrem(::Static{N}, ::Static{D}) where {N,D} = divrem(N, D)

# These have versions that may allow for more optimizations, so we override base methods with a single `Static` argument.
for (f,ff) ∈ [(:(Base.:+),:vadd), (:(Base.:-),:vsub), (:(Base.:*),:vmul), (:(Base.:<<)), (:(Base.:÷),:vdiv), (:(Base.:%), :vrem), (:(Base.:>>>),:vashr)]
    @eval begin
        @inline $f(::Static{M}, ::Static{N}) where {M, N} = Static{$f(M, N)}()
    # If `M` and `N` are known at compile time, there's no need to add nsw/nuw flags.
        @inline $ff(::Static{M}, ::Static{N}) where {M, N} = Static{$f(M, N)}()
        @inline $f(::Static{M}, x) = $ff(M, x)
        @inline $ff(::Static{M}, x) = $ff(M, x)
        @inline $f(x, ::Static{M}) = $ff(x, M)
        @inline $ff(x, ::Static{M}) = $ff(x, M)
    end
end
for (f,ff) [(:(Base.:&),:vand), (:(Base.:|),:vor), (:(Base.:⊻),:vxor)]
    @eval @inline $f(::Static{M}, ::Static{N}) where {M, N} = Static{$f(M, N)}()
    @eval @inline $ff(::Static{M}, ::Static{N}) where {M, N} = Static{$f(M, N)}()
end

for f ∈ [:(Base.:(&)), :(Base.:(>)), :(Base.:(<)), :(Base.:(≥)), :(Base.:(≤)), :(Base.div), :(Base.cld), :vadd, :vsub, :vmul]
    @eval @inline $f(::Static{M}, n::Number) where {M} = $f(M, n)
    @eval @inline $f(m::Number, ::Static{N}) where {N} = $f(m, N)
    @eval @inline $f(::Static{M}, ::Static{N}) where {M, N} = Static{$f(M, N)}()
end
for f ∈ [:(Base.:(>>)), :(Base.:(>>>))]
    @eval @inline $f(::Static{M}, n::Number) where {M} = shr(M, n)
    @eval @inline $f(m::Number, ::Static{N}) where {N} = shr(m, N)
    @eval @inline $f(::Static{M}, ::Static{N}) where {M, N} = Static{$f(M, N)}()
end

@inline vsub(::Static{N}, ::Zero) where {N} = Static{N}()
@inline Base.:(-)(::Static{N}, ::Zero) where {N} = Static{N}()
@inline vsub(::Zero, ::Zero) = Zero()
@inline Base.:(-)(::Zero, ::Zero) = Zero()
@inline vsub(a, ::Zero) = a
@inline Base.:(-)(a, ::Zero) = a

@inline vadd(::Static{N}, ::Zero) where {N} = Static{N}()
@inline Base.:(+)(::Static{N}, ::Zero) where {N} = Static{N}()
@inline vadd(::Zero, ::Static{N}) where {N} = Static{N}()
@inline Base.:(+)(::Zero, ::Static{N}) where {N} = Static{N}()
@inline vadd(::Zero, ::Zero) = Zero()
@inline Base.:(+)(::Zero, ::Zero) = Zero()
@inline vadd(a::Number, ::Zero) = a
@inline Base.:(+)(a::Number, ::Zero) = a
@inline vadd(::Zero, a::Number) = a
@inline Base.:(+)(::Zero, a::Number) = a

@inline vmul(::Static{N}, ::Zero) where {N} = Zero()
@inline Base.:(*)(::Static{N}, ::Zero) where {N} = Zero()
@inline vmul(::Zero, ::Static{N}) where {N} = Zero()
@inline Base.:(*)(::Zero, ::Static{N}) where {N} = Zero()
@inline vmul(::Zero, ::Zero) = Zero()
@inline Base.:(*)(::Zero, ::Zero) = Zero()
@inline vmul(::Static{N}, ::One) where {N} = Static{N}()
@inline Base.:(*)(::Static{N}, ::One) where {N} = Static{N}()
@inline vmul(::One, ::Static{N}) where {N} = Static{N}()
@inline Base.:(*)(::One, ::Static{N}) where {N} = Static{N}()
@inline vmul(::One, ::One) = One()
@inline Base.:(*)(::One, ::One) = One()
@inline vmul(a::Number, ::One) = a
@inline Base.:(*)(a::Number, ::One) = a
@inline vmul(::One, a::Number) = a
@inline Base.:(*)(::One, a::Number) = a
@inline vmul(::Zero, ::One) = Zero()
@inline Base.:(*)(::Zero, ::One) = Zero()
@inline vmul(::One, ::Zero) = Zero()
@inline Base.:(*)(::One, ::Zero) = Zero()

@inline Base.:<<(::Static{N}, i) where {N} = shl(N, i)
@inline Base.:<<(i, ::Static{N}) where {N} = shl(i, N)
@inline Base.:<<(::Static{M}, ::Static{N}) where {M,N} = Static{M << N}()
@inline Base.:(%)(::Static{M}, ::Type{I}) where {M,I<:Integer} = M % I

@inline Base.:(==)(::Static{M}, i) where {M} = M == i
@inline Base.:(==)(i, ::Static{M}) where {M} = M == i
@inline Base.:(==)(::Static{M}, ::Static{N}) where {M,N} = false
@inline Base.:(==)(::Static{M}, ::Static{M}) where {M} = true

# @inline vadd(::Tuple{}, ::Tuple{}) = tuple()
# @inline vadd(a::Tuple{I1,Vararg}, b::Tuple{}) where {I1} = a
# @inline vadd(a::Tuple{}, b::Tuple{I2,Vararg}) where {I2} = b
# @inline vadd(a::Tuple{I1}, b::Tuple{I2}) where {I1,I2} = (vadd(a[1],b[1]),)
# @inline vadd(a::Tuple{I1,I3}, b::Tuple{I2,I4}) where {I1,I2,I3,I4} = (vadd(a[1],b[1]),vadd(a[2],b[2]),)
# @inline vadd(a::Tuple{I1,Vararg}, b::Tuple{I2,Vararg}) where {I1,I2} = (vadd(a[1],b[1]),vadd(Base.tail(a),Base.tail(b))...)

# function static_promote(i, j)
#     i == j || throw("$i ≠ $j")
#     i
# end
# function static_promote(::Static{M}, i) where {M}
#     M == i || throw("$M ≠ $i")
#     Static{M}()
# end
# function static_promote(i, ::Static{M}) where {M}
#     M == i || throw("$M ≠ $i")
#     Static{M}()
# end
# static_promote(::Static{M}, ::Static{N}) where {M, N} = throw("$M ≠ $N")
# static_promote(::Static{M}, ::Static{M}) where {M} = Static{M}()

@generated staticp1(::Static{N}) where {N} = Static{N+1}()
@inline staticp1(N) = vadd(N, one(N))
@inline staticp1(i::Tuple{}) = tuple()
@inline staticp1(i::Tuple{I}) where {I} = @inbounds (staticp1(i[1]),)
@inline staticp1(i::Tuple{I1,I2}) where {I1,I2} = @inbounds (staticp1(i[1]), staticp1(i[2]))
@inline staticp1(i::Tuple{I1,I2,I3,Vararg}) where {I1,I2,I3} = @inbounds (staticp1(i[1]), staticp1(Base.tail(i))...)
@generated staticm1(::Static{N}) where {N} = Static{N-1}()
@inline staticm1(N) = vsub(N, one(N))
@inline staticm1(i::Tuple{}) = tuple()
@inline staticm1(i::Tuple{I}) where {I} = @inbounds (staticm1(i[1]),)
@inline staticm1(i::Tuple{I1,I2}) where {I1,I2} = @inbounds (staticm1(i[1]), staticm1(i[2]))
@inline staticm1(i::Tuple{I1,I2,I3,Vararg}) where {I1,I2,I3} = @inbounds (staticm1(i[1]), staticm1(Base.tail(i))...)
@generated staticmul(::Type{T}, ::Static{N}) where {T,N} = sizeof(T) * N
@generated staticmul(::Type{T}, ::Val{N}) where {T,N} = sizeof(T) * N
@inline staticmul(::Type{T}, N) where {T} = vmul(N, sizeof(T))
@inline staticmul(::Type{T}, i::Tuple{}) where {T} = tuple()
@inline staticmul(::Type{T}, i::Tuple{I}) where {T,I} = @inbounds (vmul(i[1], sizeof(T)),)
@inline staticmul(::Type{T}, i::Tuple{I1,I2}) where {T,I1,I2} = @inbounds (vmul(sizeof(T), i[1]), vmul(sizeof(T), i[2]))
@inline staticmul(::Type{T}, i::Tuple{I1,I2,I3,Vararg}) where {T,I1,I2,I3} = @inbounds (vmul(sizeof(T), i[1]), staticmul(T, Base.tail(i))...)
@generated function Base.ntuple(f::F, ::Static{N}) where {F,N}
    t = Expr(:tuple)
    foreach(n -> push!(t.args, Expr(:call, :f, n)), 1:N)
    Expr(:block, Expr(:meta, :inline), t)
end


@inline _maybestaticfirst(A::Tuple{}) = tuple()
@inline _maybestaticfirst(A::Tuple{I}) where {I} = (maybestaticfirst(@inbounds(A[1])),)
@inline _maybestaticfirst(A::Tuple{I1,I2}) where {I1,I2} = @inbounds (maybestaticfirst(A[1]), maybestaticfirst(A[2]))
@inline _maybestaticfirst(A::Tuple{I1,I2,I3,Vararg}) where {I1,I2,I3} = (maybestaticfirst(@inbounds A[1]), _maybestaticfirst(Base.tail(A))...)
@inline maybestaticfirst(A::CartesianIndices) = CartesianVIndex(_maybestaticfirst(A.indices))

@inline _maybestaticlast(A::Tuple{}) = tuple()
@inline _maybestaticlast(A::Tuple{I}) where {I} = (maybestaticlast(@inbounds(A[1])),)
@inline _maybestaticlast(A::Tuple{I1,I2}) where {I1,I2} = @inbounds (maybestaticlast(A[1]), maybestaticlast(A[2]))
@inline _maybestaticlast(A::Tuple{I1,I2,I3,Vararg}) where {I1,I2,I3} = (maybestaticlast(@inbounds A[1]), _maybestaticlast(Base.tail(A))...)
@inline maybestaticlast(A::CartesianIndices) = CartesianVIndex(_maybestaticlast(A.indices))


# # Static 0
# @inline vsub(::Zero, i) = vsub(i)
# @inline vsub(i, ::Zero) = i
# @inline vsub(::Zero, i::Number) = vsub(i)
# @inline vsub(i::Number, ::Zero) = i
# @inline vsub(::Zero, ::Zero) = Zero()
# @inline vadd(::Zero, ::Zero) = Zero()
# @inline vadd(::Zero, a) = a
# @inline vadd(a, ::Zero) = a
# @inline vadd(::Zero, a::Number) = a
# @inline vadd(a::Number, ::Zero) = a
# @inline vmul(::Zero, ::Any) = Zero()
# @inline vmul(::Any, ::Zero) = Zero()
# @inline vmul(::Zero, ::Number) = Zero()
# @inline vmul(::Number, ::Zero) = Zero()
# @inline vmul(::Zero, i::Vec{<:Any,<:Integer}) = Zero()
# @inline vmul(i::Vec{<:Any,<:Integer}, ::Zero) = Zero()
# # for T ∈ [:Int,:Vec]
#     @eval @inline vadd(::Zero, a::$T) = a
#     @eval @inline vadd(a::$T, ::Zero) = a
#     @eval @inline vsub(::Zero, a::$T) = vsub(a)
#     @eval @inline vsub(a::$T, ::Zero) = a
#     @eval @inline vmul(::Zero, ::$T) = Zero()
#     @eval @inline vmul(::$T, ::Zero) = Zero()
# end
# @inline vadd(::Zero, a::MM) = a
# @inline vadd(a::MM, ::Zero) = a
# @inline vload(ptr::Ptr, ::Zero) = vload(ptr)
# @inline vload(ptr::Ptr, ::MM{W,Zero}) where {W} = vload(Val{W}(), ptr)
# @inline vload(ptr::Ptr, ::MM{W,Zero}, m::Mask) where {W} = vload(Val{W}(), ptr, m.u)
# @inline vstore!(ptr::Ptr{T}, v::T, ::Zero) where {T} = vstore!(ptr, v)
# @inline vnoaliasstore!(ptr::Ptr{T}, v::T, ::Zero) where {T} = vnoaliasstore!(ptr, v)
# @inline vstore!(ptr::Ptr{T}, v, ::Zero) where {T} = vstore!(ptr, convert(T,v))
# @inline vnoaliasstore!(ptr::Ptr{T}, v, ::Zero) where {T} = vnoaliasstore!(ptr, convert(T,v))
# @inline vstore!(ptr::Ptr{T}, v::Integer, ::Zero) where {T <: Integer} = vstore!(ptr, v % T)
# @inline vnoaliasstore!(ptr::Ptr{T}, v::Integer, ::Zero) where {T <: Integer} = vnoaliasstore!(ptr, v % T)
# # @inline vstore!(ptr::Ptr{T}, v::T, ::Zero, m::Mask) where {T} = vstore!(ptr, v, m.u)
# # @inline vnoaliasstore!(ptr::Ptr{T}, v::T, ::Zero, m::Mask) where {T} = vnoaliasstore!(ptr, v, m.u)
# for V ∈ [:(NTuple{W,Core.VecElement{T}}), :(Vec{W,T})]
#     @eval @inline vstore!(ptr::Ptr{T}, v::$V, ::Zero) where {W,T} = vstore!(ptr, v)
#     @eval @inline vstore!(ptr::Ptr{T}, v::$V, ::MM{W,Zero}) where {W,T} = vstore!(ptr, v)
#     @eval @inline vnoaliasstore!(ptr::Ptr{T}, v::$V, ::Zero) where {W,T} = vnoaliasstore!(ptr, v)
#     @eval @inline vnoaliasstore!(ptr::Ptr{T}, v::$V, ::MM{W,Zero}) where {W,T} = vnoaliasstore!(ptr, v)
#     for M ∈ [:(Mask{W}), :Unsigned]
#         @eval @inline vstore!(ptr::Ptr{T}, v::$V, ::Zero, m::$M) where {W,T} = vstore!(ptr, v, m)
#         @eval @inline vstore!(ptr::Ptr{T}, v::$V, ::MM{W,Zero}, m::$M) where {W,T} = vstore!(ptr, v, m)
#         @eval @inline vnoaliasstore!(ptr::Ptr{T}, v::$V, ::Zero, m::$M) where {W,T} = vnoaliasstore!(ptr, v, m)
#         @eval @inline vnoaliasstore!(ptr::Ptr{T}, v::$V, ::MM{W,Zero}, m::$M) where {W,T} = vnoaliasstore!(ptr, v, m)
#     end
# end

# @inline vmul(::One, a) = a
# @inline vmul(a, ::One) = a
# @inline vmul(::One, a::Number) = a
# @inline vmul(a::Number, ::One) = a
# @inline vmul(::One, ::One) = One()
# @inline vmul(::One, ::Zero) = Zero()
# @inline vmul(::Zero, ::One) = Zero()
# @inline vmul(::One, i::Vec{<:Any,<:Integer}) = i
# @inline vmul(i::Vec{<:Any,<:Integer}, ::One) = i

# for T ∈ [:Int,:Vec]
#     @eval @inline vmul(::One, a::$T) = a
#     @eval @inline vmul(a::$T, ::One) = a
# end

# abstract type AbstractLazyMul end
struct LazyMul{N,T} <: Number
    data::T
end
@inline LazyMul{N}(data::T) where {N,T} = LazyMul{N,T}(data)
@inline data(lm::LazyMul) = lm.data

# struct LazyMulAdd{N,M,T} <: AbstractLazyMul
    # data::T
# end
# @inline LazyMulAdd{N,M}(data::T) where {N,M,T} = LazyMulAdd{N,M,T}(data)


@inline lazymul(a, b) = vmul(a, b)
@inline lazymul(::Static{N}, b) where {N} = LazyMul{N}(b)
@inline lazymul(a, ::Static{N}) where {N} = LazyMul{N}(a)
@inline lazymul(::Static{N}, b::MM) where {N} = LazyMul{N}(Vec(b))
@inline lazymul(a::MM, ::Static{N}) where {N} = LazyMul{N}(Vec(a))
@inline lazymul(::Static{M}, ::Static{N}) where {M, N} = Static{M*N}()

@inline lazymul(a::LazyMul{M}, ::Static{N}) where {M,N} = LazyMul{M*N}(data(a))
@inline lazymul(::Static{M}, b::LazyMul{N}) where {M,N} = LazyMul{M*N}(data(b))
@inline lazymul(a::LazyMul{M,<:MM}, ::Static{N}) where {M,N} = LazyMul{M*N}(Vec(data(a)))
@inline lazymul(::Static{M}, b::LazyMul{N,<:MM}) where {M,N} = LazyMul{M*N}(Vec(data(b)))
@inline lazymul(a::LazyMul{M}, b::LazyMul{N}) where {M,N} = LazyMul{M*N}(vmul(data(a), data(b)))

@inline lazymul_no_prmote(a, b) = vmul_no_promote(a, b)
@inline lazymul_no_prmote(::Static{N}, b) where {N} = LazyMul{N}(b)
@inline lazymul_no_prmote(a, ::Static{N}) where {N} = LazyMul{N}(a)
@inline lazymul_no_prmote(::Static{M}, ::Static{N}) where {M, N} = Static{M*N}()

@inline lazymul_no_prmote(a::LazyMul{M}, ::Static{N}) where {M,N} = LazyMul{M*N}(data(a))
@inline lazymul_no_prmote(::Static{M}, b::LazyMul{N}) where {M,N} = LazyMul{M*N}(data(b))
@inline lazymul_no_prmote(a::LazyMul{M}, b::LazyMul{N}) where {M,N} = LazyMul{M*N}(vmul(data(a), data(b)))




