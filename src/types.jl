struct GaussianState{M,V} <: StateVector{M,V}
    mean::M
    covar::V
    function GaussianState(m::M, v::V) where {M,V}
        all(size(v) .== length(m)) || throw(DimensionMismatch(STATE_ERROR))
        return new{M,V}(m, v)
    end
end

Base.:(==)(x::GaussianState, y::GaussianState) = x.mean == y.mean && x.covar == y.covar
function Base.summary(io::IO, x::GaussianState)
    modenum = Int(length(x.disp)/2)
    if isone(modenum)
        print(io, "$(typeof(x)) for $(modenum) mode \n")
    else
        print(io, "$(typeof(x)) for $(modenum) modes \n")
    end
    print(io, "\n  mean vector: ")
    Base.show(io, x.mean)
    print(io, "\n  covariance matrix: ")
    Base.show(io, x.covar)
end
Base.show(io::IO, x::GaussianState) = Base.summary(io, x)

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
    @inbounds for (i,j) in axes(covar1)
        covar′[i,j] = covar1[i,j]
    end
    @inbounds for (i,j) in axes(covar2)
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
    @inbounds for (i,j) in axes(covar1)
        covar′[i,j] = covar1[i,j]
    end
    @inbounds for (i,j) in axes(covar2)
        covar′[i+length1,j+length1] = covar2[i,j]
    end 
    return GaussianState(mean′, covar′)
end

struct GaussianUnitary{D,S} <: AbstractOperator{D,S}
    disp::D
    symplectic::S
    function GaussianUnitary(d::D, s::S) where {D,S}
        all(length(d) .== size(s)) || throw(DimensionMismatch(UNITARY_ERROR))
        return new{D,S}(d, s)
    end
end

Base.:(==)(x::GaussianUnitary, y::GaussianUnitary) = x.disp == y.disp && x.symplectic == y.symplectic
function Base.summary(io::IO, x::GaussianUnitary)
    modenum = Int(length(x.disp)/2)
    if isone(modenum)
        print(io, "$(typeof(x)) for $(modenum) mode \n")
    else
        print(io, "$(typeof(x)) for $(modenum) modes \n")
    end
    print(io, "  displacement vector: ")
    Base.show(io, x.disp)
    print(io, "  symplectic matrix: ")
    Base.show(io, x.symplectic)
end
Base.show(io::IO, x::GaussianUnitary) = Base.summary(io, x)

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
    @inbounds for (i,j) in axes(symp1)
        symplectic′[i,j] = symp1[i,j]
    end
    @inbounds for (i,j) in axes(symp2)
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
    @inbounds for (i,j) in axes(symp1)
        symplectic′[i,j] = symp1[i,j]
    end
    @inbounds for (i,j) in axes(symp2)
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
function Base.summary(io::IO, x::GaussianChannel)
    modenum = Int(length(x.disp)/2)
    if isone(modenum)
        print(io, "$(typeof(x)) for $(modenum) mode \n")
    else
        print(io, "$(typeof(x)) for $(modenum) modes \n")
    end
    print(io, "  displacement vector: ")
    Base.show(io, x.disp)
    print(io, "  transform matrix: ")
    Base.show(io, x.transform)
    print(io, "  noise matrix: ")
    Base.show(io, x.noise)
end
Base.show(io::IO, x::GaussianChannel) = Base.summary(io, x)

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
    @inbounds for (i,j) in axes(trans1)
        transform′[i,j] = trans1[i,j]
    end
    @inbounds for (i,j) in axes(trans2)
        transform′[i+length1,j+length1] = trans2[i,j]
    end
    noise1, noise2 = op1.noise, op2.noise
    noise′ = zeros(slengths, slengths)
    @inbounds for (i,j) in axes(noise1)
        noise′[i,j] = noise1[i,j]
    end
    @inbounds for (i,j) in axes(noise2)
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
    @inbounds for (i,j) in axes(trans1)
        transform′[i,j] = trans1[i,j]
    end
    @inbounds for (i,j) in axes(trans2)
        transform′[i+length1,j+length1] = trans2[i,j]
    end
    noise1, noise2 = op1.noise, op2.noise
    noise′ = zeros(slengths, slengths)
    @inbounds for (i,j) in axes(noise1)
        noise′[i,j] = noise1[i,j]
    end
    @inbounds for (i,j) in axes(noise2)
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