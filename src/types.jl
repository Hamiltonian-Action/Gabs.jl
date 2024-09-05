"""
Defines a Gaussian state for an N-mode bosonic system over a 2N-dimensional phase space.

## Fields

- `mean`: The mean vector of length 2N.
- `covar`: The covariance matrix of size 2N x 2N.

## Mathematical description of a Gaussian state

An ``N``-mode Gaussian state, ``\\hat{\\rho}(\\mathbf{\\bar{x}}, \\mathbf{V})``, is a density
operator characterized by two statistical moments: a mean vector ``\\mathbf{\\bar{x}}`` of
length ``2N`` and covariance matrix ``\\mathbf{V}`` of size ``2N\\times 2N``. By definition,
the Wigner representation of a Gaussian state is a Gaussian function.

## Example

```jldoctest
julia> coherentstate(1.0+im)
GaussianState
mean: 2-element Vector{Float64}:
 1.4142135623730951
 1.4142135623730951
covariance: 2×2 Matrix{Float64}:
 1.0  0.0
 0.0  1.0
```
"""
struct GaussianState{M,V} <: StateVector{M,V}
    mean::M
    covar::V
    function GaussianState(m::M, v::V) where {M,V}
        all(size(v) .== length(m)) || throw(DimensionMismatch(STATE_ERROR))
        return new{M,V}(m, v)
    end
end

Base.:(==)(x::GaussianState, y::GaussianState) = x.mean == y.mean && x.covar == y.covar
function Base.show(io::IO, mime::MIME"text/plain", x::GaussianState)
    modenum = Int(length(x.mean)/2)
    if isone(modenum)
        printstyled(io, nameof(typeof(x)); color=:blue)
        print(" for $(modenum) mode.")
    else
        printstyled(io, nameof(typeof(x)); color=:blue)
        print(" for $(modenum) modes.")
    end
    print(io, "\nmean: ")
    Base.show(io, mime, x.mean)
    print(io, "\ncovariance: ")
    Base.show(io, mime, x.covar)
end

"""
    directsum([Td=Vector{Float64}, Ts=Matrix{Float64},] op1::GaussianState, op2::GaussianState)

Direct sum of Gaussian states, which can also be called with `⊕`.

## Example
```jldoctest
julia> coherentstate(1.0+im) ⊕ thermalstate(2)
GaussianState
mean: 4-element Vector{Float64}:
 1.4142135623730951
 1.4142135623730951
 0.0
 0.0
covariance: 4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  2.5  0.0
 0.0  0.0  0.0  2.5
```
"""
function directsum(::Type{Tm}, ::Type{Tc}, state1::GaussianState, state2::GaussianState) where {Tm,Tc}
    mean1, mean2 = state1.mean, state2.mean
    length1, length2 = length(mean1), length(mean2)
    slengths = length1 + length2
    covar1, covar2 = state1.covar, state2.covar
    mean′ = zeros(length1+length2)
    @inbounds for i in eachindex(mean1)
        mean′[i] = mean1[i]
    end
    @inbounds for i in eachindex(mean2)
        mean′[i+length1] = mean2[i]
    end
    covar′ = zeros(slengths, slengths)
    axes1 = axes(covar1)
    @inbounds for i in axes1[1], j in axes1[2]
        covar′[i,j] = covar1[i,j]
    end
    axes2 = axes(covar2)
    @inbounds for i in axes2[1], j in axes2[2]
        covar′[i+length1,j+length1] = covar2[i,j]
    end
    return GaussianState(Tm(mean′), Tc(covar′))
end
directsum(::Type{T}, state1::GaussianState, state2::GaussianState) where {T} = directsum(T, T, state1, state2)
function directsum(state1::GaussianState, state2::GaussianState)
    mean1, mean2 = state1.mean, state2.mean
    length1, length2 = length(mean1), length(mean2)
    slengths = length1 + length2
    covar1, covar2 = state1.covar, state2.covar
    mean′ = zeros(length1+length2)
    @inbounds for i in eachindex(mean1)
        mean′[i] = mean1[i]
    end
    @inbounds for i in eachindex(mean2)
        mean′[i+length1] = mean2[i]
    end
    covar′ = zeros(slengths, slengths)
    axes1 = axes(covar1)
    @inbounds for i in axes1[1], j in axes1[2]
        covar′[i,j] = covar1[i,j]
    end
    axes2 = axes(covar2)
    @inbounds for i in axes2[1], j in axes2[2]
        covar′[i+length1,j+length1] = covar2[i,j]
    end
    return GaussianState(mean′, covar′)
end

"""
Defines a Gaussian unitary for an N-mode bosonic system over a 2N-dimensional phase space.

## Fields

- `disp`: The displacement vector of length 2N.
- `symplectic`: The symplectic matrix of size 2N x 2N.

## Mathematical description of a Gaussian unitary

An ``N``-mode Gaussian unitary, ``U(\\mathbf{d}, \\mathbf{S})``, is a unitary
operator characterized by a displacement vector ``\\mathbf{d}`` of length ``2N`` and symplectic
matrix ``\\mathbf{S}`` of size ``2N\\times 2N``, such that its action on a Gaussian state
results in a Gaussian state. More specifically, a Gaussian unitary transformation on a
Gaussian state ``\\hat{\\rho}(\\mathbf{\\bar{x}}, \\mathbf{V})`` is described by its maps on
the statistical moments of the Gaussian state:

```math
\\mathbf{\\bar{x}} \\to \\mathbf{S} \\mathbf{\\bar{x}} + \\mathbf{d}, \\quad
\\mathbf{V} \\to \\mathbf{S} \\mathbf{V} \\mathbf{S}^{\\text{T}}.
```

## Example

```jldoctest
julia> displace(1.0+im)
GaussianUnitary
displacement: 2-element Vector{Float64}:
 1.4142135623730951
 1.4142135623730951
symplectic: 2×2 Matrix{Float64}:
 1.0  0.0
 0.0  1.0
```
"""
struct GaussianUnitary{D,S} <: AbstractOperator{D,S}
    disp::D
    symplectic::S
    function GaussianUnitary(d::D, s::S) where {D,S}
        all(length(d) .== size(s)) || throw(DimensionMismatch(UNITARY_ERROR))
        return new{D,S}(d, s)
    end
end

Base.:(==)(x::GaussianUnitary, y::GaussianUnitary) = x.disp == y.disp && x.symplectic == y.symplectic
function Base.show(io::IO, mime::MIME"text/plain", x::GaussianUnitary)
    modenum = Int(length(x.disp)/2)
    if isone(modenum)
        printstyled(io, nameof(typeof(x)); color=:blue)
        print(" for $(modenum) mode.")
    else
        printstyled(io, nameof(typeof(x)); color=:blue)
        print(" for $(modenum) modes.")
    end
    print(io, "\ndisplacement: ")
    Base.show(io, mime, x.disp)
    print(io, "\nsymplectic: ")
    Base.show(io, mime, x.symplectic)
end

function directsum(::Type{Td}, ::Type{Ts}, op1::GaussianUnitary, op2::GaussianUnitary) where {Td,Ts}
    disp1, disp2 = op1.disp, op2.disp
    length1, length2 = length(disp1), length(disp2)
    slengths = length1 + length2
    symp1, symp2 = op1.symplectic, op2.symplectic
    disp′ = zeros(slengths)
    @inbounds for i in eachindex(disp1)
        disp′[i] = disp1[i]
    end
    @inbounds for i in eachindex(disp2)
        disp′[i+length1] = disp2[i]
    end
    symplectic′ = zeros(slengths, slengths)
    axes1 = axes(symp1)
    @inbounds for i in axes1[1], j in axes1[2]
        symplectic′[i,j] = symp1[i,j]
    end
    axes2 = axes(symp2)
    @inbounds for i in axes2[1], j in axes2[2]
        symplectic′[i+length1,j+length1] = symp2[i,j]
    end
    return GaussianUnitary(Td(disp′), Ts(symplectic′))
end
directsum(::Type{T}, op1::GaussianUnitary, op2::GaussianUnitary) where {T} = directsum(T, T, op1, op2)
function directsum(op1::GaussianUnitary, op2::GaussianUnitary)
    disp1, disp2 = op1.disp, op2.disp
    length1, length2 = length(disp1), length(disp2)
    slengths = length1 + length2
    symp1, symp2 = op1.symplectic, op2.symplectic
    disp′ = zeros(slengths)
    @inbounds for i in eachindex(disp1)
        disp′[i] = disp1[i]
    end
    @inbounds for i in eachindex(disp2)
        disp′[i+length1] = disp2[i]
    end
    symplectic′ = zeros(slengths, slengths)
    axes1 = axes(symp1)
    @inbounds for i in axes1[1], j in axes1[2]
        symplectic′[i,j] = symp1[i,j]
    end
    axes2 = axes(symp2)
    @inbounds for i in axes2[1], j in axes2[2]
        symplectic′[i+length1,j+length1] = symp2[i,j]
    end
    return GaussianUnitary(disp′, symplectic′)
end
function apply(state::GaussianState, op::GaussianUnitary)
    d, S, = op.disp, op.symplectic
    length(d) == length(state.mean) || throw(DimensionMismatch(ACTION_ERROR))
    mean′ = S * state.mean .+ d
    covar′ = S * state.covar * transpose(S)
    return GaussianState(mean′, covar′)
end
Base.:(*)(op::GaussianUnitary, state::GaussianState) = apply(state, op)
function apply!(state::GaussianState, op::GaussianUnitary)
    d, S = op.disp, op.symplectic
    length(d) == length(state.mean) || throw(DimensionMismatch(ACTION_ERROR))
    state.mean .= S * state.mean .+ d
    state.covar .= S * state.covar * transpose(S)
    return state
end

"""
Defines a Gaussian channel for an N-mode bosonic system over a 2N-dimensional phase space.

## Fields

- `disp`: The displacement vector of length 2N.
- `transform`: The transformation matrix of size 2N x 2N.
- `noise`: The noise matrix of size 2N x 2N.

## Mathematical description of a Gaussian channel

An ``N``-mode Gaussian channel, ``G(\\mathbf{d}, \\mathbf{T}, \\mathbf{N})``, is an
operator characterized by a displacement vector ``\\mathbf{d}`` of length ``2N``, as well as
a transformation matrix ``\\mathbf{T}`` and noise matrix ``\\mathbf{N}`` of size ``2N\\times 2N``,
such that its action on a Gaussian state results in a Gaussian state. More specifically, a Gaussian
channel action on a Gaussian state ``\\hat{\\rho}(\\mathbf{\\bar{x}}, \\mathbf{V})`` is
described by its maps on the statistical moments of the Gaussian state:

```math
\\mathbf{\\bar{x}} \\to \\mathbf{S} \\mathbf{\\bar{x}} + \\mathbf{d}, \\quad
\\mathbf{V} \\to \\mathbf{T} \\mathbf{V} \\mathbf{T}^{\\text{T}} + \\mathbf{N}.
```

## Example

```jldoctest
julia> noise = [1.0 -3.0; 4.0 2.0];

julia> displace(1.0+im, noise)
GaussianChannel
displacement: 2-element Vector{Float64}:
 1.4142135623730951
 1.4142135623730951
transform: 2×2 Matrix{Float64}:
 1.0  0.0
 0.0  1.0
noise: 2×2 Matrix{Float64}:
 1.0  -3.0
 4.0   2.0
```
"""
struct GaussianChannel{D,T} <: AbstractOperator{D,T}
    disp::D
    transform::T
    noise::T
    function GaussianChannel(d::D, t::T, n::T) where {D,T}
        all(length(d) .== size(t) .== size(n)) || throw(DimensionMismatch(CHANNEL_ERROR))
        return new{D,T}(d, t, n)
    end
end

Base.:(==)(x::GaussianChannel, y::GaussianChannel) = x.disp == y.disp && x.transform == y.transform && x.noise == y.noise
function Base.show(io::IO, mime::MIME"text/plain", x::GaussianChannel)
    modenum = Int(length(x.disp)/2)
    if isone(modenum)
        printstyled(io, nameof(typeof(x)); color=:blue)
        print(" for $(modenum) mode.")
    else
        printstyled(io, nameof(typeof(x)); color=:blue)
        print(" for $(modenum) modes.")
    end
    print(io, "\ndisplacement: ")
    Base.show(io, mime, x.disp)
    print(io, "\ntransform: ")
    Base.show(io, mime, x.transform)
    print(io, "\nnoise: ")
    Base.show(io, mime, x.noise)
end
function Base.summary(io::IO, x::Union{GaussianState,GaussianUnitary,GaussianChannel})
    printstyled(io, typeof(x); color=:blue)
end

function directsum(::Type{Td}, ::Type{Tt}, op1::GaussianChannel, op2::GaussianChannel) where {Td,Tt}
    disp1, disp2 = op1.disp, op2.disp
    length1, length2 = length(disp1), length(disp2)
    slengths = length1 + length2
    trans1, trans2 = op1.transform, op2.transform
    disp′ = zeros(slengths)
    @inbounds for i in eachindex(disp1)
        disp′[i] = disp1[i]
    end
    @inbounds for i in eachindex(disp2)
        disp′[i+length1] = disp2[i]
    end
    transform′ = zeros(slengths, slengths)
    taxes1 = axes(trans1)
    @inbounds for i in taxes1[1], j in taxes1[2]
        transform′[i,j] = trans1[i,j]
    end
    taxes2 = axes(trans2)
    @inbounds for i in taxes2[1], j in taxes2[2]
        transform′[i+length1,j+length1] = trans2[i,j]
    end
    noise1, noise2 = op1.noise, op2.noise
    noise′ = zeros(slengths, slengths)
    naxes1 = axes(noise1)
    @inbounds for i in naxes1[1], j in naxes1[2]
        noise′[i,j] = noise1[i,j]
    end
    naxes2 = axes(noise2)
    @inbounds for i in naxes2[1], j in naxes2[2]
        noise′[i+length1,j+length1] = noise2[i,j]
    end
    return GaussianChannel(Td(disp′), Tt(transform′), Tt(noise′))
end
directsum(::Type{T}, op1::GaussianChannel, op2::GaussianChannel) where {T} = directsum(T, T, op1, op2)
function directsum(op1::GaussianChannel, op2::GaussianChannel)
    disp1, disp2 = op1.disp, op2.disp
    length1, length2 = length(disp1), length(disp2)
    slengths = length1 + length2
    trans1, trans2 = op1.transform, op2.transform
    disp′ = zeros(slengths)
    @inbounds for i in eachindex(disp1)
        disp′[i] = disp1[i]
    end
    @inbounds for i in eachindex(disp2)
        disp′[i+length1] = disp2[i]
    end
    transform′ = zeros(slengths, slengths)
    taxes1 = axes(trans1)
    @inbounds for i in taxes1[1], j in taxes1[2]
        transform′[i,j] = trans1[i,j]
    end
    taxes2 = axes(trans2)
    @inbounds for i in taxes2[1], j in taxes2[2]
        transform′[i+length1,j+length1] = trans2[i,j]
    end
    noise1, noise2 = op1.noise, op2.noise
    noise′ = zeros(slengths, slengths)
    naxes1 = axes(noise1)
    @inbounds for i in naxes1[1], j in naxes1[2]
        noise′[i,j] = noise1[i,j]
    end
    naxes2 = axes(noise2)
    @inbounds for i in naxes2[1], j in naxes2[2]
        noise′[i+length1,j+length1] = noise2[i,j]
    end
    return GaussianChannel(disp′, transform′, noise′)
end
function apply(state::GaussianState, op::GaussianChannel)
    d, T, N = op.disp, op.transform, op.noise
    length(d) == length(state.mean) || throw(DimensionMismatch(ACTION_ERROR))
    mean′ = T * state.mean .+ d
    covar′ = T * state.covar * transpose(T) .+ N
    return GaussianState(mean′, covar′)
end
Base.:(*)(op::GaussianChannel, state::GaussianState) = apply(state, op)
function apply!(state::GaussianState, op::GaussianChannel)
    d, T, N = op.disp, op.transform, op.noise
    length(d) == length(state.mean) || throw(DimensionMismatch(ACTION_ERROR))
    state.mean .= T * state.mean .+ d
    state.covar .= T * state.covar * transpose(T) .+ N
    return state
end