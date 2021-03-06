export Term, Polynomial, MatPolynomial, SOSDecomposition, TermType, getmat, monomials, removemonomials

abstract TermType{C, T} <: PolyType{C}
eltype{C, T}(::Type{TermType{C, T}}) = T
eltype{C, T}(p::TermType{C, T}) = T
zero{C, T}(t::TermType{C, T}) = Polynomial(T[], MonomialVector{C}(vars(t), Vector{Vector{Int}}()))
#zero{T<:TermType}(::Type{T}) = Polynomial(eltype(T)[], MonomialVector{iscomm(T)}())
one{C, T}(t::TermType{C, T}) = Polynomial([one(T)], MonomialVector{C}(vars(t), [zeros(Int, length(vars(t)))]))
#one{T<:TermType}(::Type{T}) = Polynomial([one(eltype(T))], MonomialVector{iscomm(T)}(PolyVar[], [Int[]]))

abstract TermContainer{C, T} <: TermType{C, T}
eltype{C, T}(::Type{TermContainer{C, T}}) = T
zero{C, T}(::Type{TermContainer{C, T}}) = zero(Polynomial{C, T})
one{C, T}(::Type{TermContainer{C, T}}) = one(Polynomial{C, T})

type Term{C, T} <: TermContainer{C, T}
    α::T
    x::Monomial{C}
end
iscomm{C, T}(::Type{Term{C, T}}) = C
Term(t::Term) = t
(::Type{Term{C}}){C}(x::Monomial{C}) = Term{C, Int}(x)
(::Type{Term{C}}){C}(x::PolyVar{C}) = Term{C}(Monomial{C}(x))
Term{C}(x::Monomial{C}) = Term{C}(x)
Term{C}(x::PolyVar{C}) = Term{C}(x)
(::Type{TermContainer{C}}){C}(x::PolyVar{C}) = Term(x)
(::Type{TermContainer{C}}){C}(x::Monomial{C}) = Term(x)
(::Type{TermContainer{C}}){C}(t::TermContainer{C}) = t
TermContainer(x::PolyVar) = Term(x)
TermContainer(x::Monomial) = Term(x)
TermContainer(t::TermContainer) = t
(::Type{Term{C}}){C, T}(α::T) = Term{C, T}(α, Monomial{C}())
Base.convert{C, T}(::Type{Term{C, T}}, t::Term{C, T}) = t
Base.convert{C, T}(::Type{Term{C, T}}, t::Term{C}) = Term{C, T}(T(t.α), t.x)
Base.convert{C, T}(::Type{Term{C, T}}, x::Monomial{C}) = Term{C, T}(one(T), x)
Base.convert{C, T}(::Type{Term{C, T}}, x::PolyVar{C}) = Term{C, T}(Monomial{C}(x))
Base.convert{C, T}(::Type{Term{C, T}}, α) = Term{C}(T(α))

Base.convert{C, T}(::Type{TermContainer{C, T}}, x::Union{Monomial{C},PolyVar{C}}) = Term{C, T}(x)
Base.convert{C, T}(::Type{TermContainer{C, T}}, α::T) = Term{C, T}(α, Monomial{C}())
Base.convert{C, S, T}(::Type{TermContainer{C, T}}, α::S) = TermContainer{C, T}(T(α))
(::Type{TermContainer{C}}){C, T}(α::T) = TermContainer{C, T}(α)

Base.convert{C, T}(::Type{TermContainer{C, T}}, t::Term{C}) = Term{C, T}(t)

zero{C, T}(t::Term{C, T}) = Term{C, T}(zero(T), t.x)
zero{C, T}(::Type{Term{C, T}}) = Term{C, T}(zero(T), Monomial{C}())
one{C, T}(t::Term{C, T}) = Term{C, T}(one(T), Monomial{C}(t.x.vars, zeros(Int, length(t.x.vars))))
one{C, T}(::Type{Term{C, T}}) = Term{C, T}(one(T), Monomial{C}())

Base.convert(::Type{Any}, t::Term) = t
Base.copy{T<:Term}(t::T) = T(copy(t.α), copy(t.x))

vars(t::Term) = vars(t.x)

eltype{C, T}(::Type{Term{C, T}}) = T
length(::Term) = 1
isempty(::Term) = false
start(::Term) = false
done(::Term, state) = state
next(t::Term, state) = (t, true)
getindex(t::Term, I::Int) = t

# Invariant:
# a and x might be empty: meaning it is the zero polynomial
# a does not contain any zeros
# x is increasing in the monomial order (i.e. grlex)
type Polynomial{C, T} <: TermContainer{C, T}
    a::Vector{T}
    x::MonomialVector{C}

    function Polynomial(a::Vector{T}, x::MonomialVector{C})
        if length(a) != length(x)
            throw(ArgumentError("There should be as many coefficient than monomials"))
        end
        zeroidx = Int[]
        for (i,α) in enumerate(a)
            if iszero(α)
                push!(zeroidx, i)
            end
        end
        if !isempty(zeroidx)
            isnz = ones(Bool, length(a))
            isnz[zeroidx] = false
            nzidx = find(isnz)
            a = a[nzidx]
            x = x[nzidx]
        end
        new(a, x)
    end
end
iscomm{C, T}(::Type{Polynomial{C, T}}) = C

Base.copy{C, T}(p::Polynomial{C, T}) = Polynomial{C, T}(copy(p.a), copy(p.x))
zero{C, T}(::Type{Polynomial{C, T}}) = Polynomial(T[], MonomialVector{C}())
one{C, T}(::Type{Polynomial{C, T}}) = Polynomial([one(T)], MonomialVector{C}(PolyVar{C}[], [Int[]]))

(::Type{Polynomial{C, T}}){C, T}(a::Vector, x::MonomialVector) = Polynomial{C, T}(Vector{T}(a), x)

function (::Type{Polynomial{C, T}}){C, T}(a::Vector, x::Vector)
    if length(a) != length(x)
        throw(ArgumentError("There should be as many coefficient than monomials"))
    end
    σ, X = sortmonovec(x)
    Polynomial{C, T}(a[σ], X)
end
(::Type{Polynomial{C}}){C, T}(a::Vector{T}, x) = Polynomial{C, T}(a, x)

Polynomial{C}(af::Union{Function, Vector}, x::MonomialVector{C}) = Polynomial{C}(af, x)
Polynomial{T<:VectorOfPolyType{false}}(af::Union{Function, Vector}, x::Vector{T}) = Polynomial{false}(af, x)
Polynomial{T<:VectorOfPolyType{true}}(af::Union{Function, Vector}, x::Vector{T}) = Polynomial{true}(af, x)

(::Type{Polynomial{C}}){C}(α) = Polynomial(Term{C}(α))
Polynomial{C}(x::PolyType{C}) = Polynomial{C}(x)
Polynomial(p::Polynomial) = p
Polynomial{C, T}(t::Term{C, T}) = Polynomial{C, T}([t.α], [t.x])
Base.convert{C, T}(::Type{Polynomial{C, T}}, x) = Polynomial(Term{C, T}(x))
Base.convert{C, T}(::Type{Polynomial{C, T}}, t::Term{C}) = Polynomial{C, T}([T(t.α)], [t.x])
Base.convert{C, T}(::Type{Polynomial{C, T}}, p::Polynomial{C, T}) = p
Base.convert{C, S, T}(::Type{Polynomial{C, T}}, p::Polynomial{C, S}) = Polynomial{C}(Vector{T}(p.a), p.x)

Base.convert{C, T}(::Type{TermContainer{C, T}}, p::Polynomial{C}) = Polynomial{C, T}(p)

function (::Type{Polynomial{C, T}}){C, T}(f::Function, x::MonomialVector{C})
    a = T[f(i) for i in 1:length(x)]
    Polynomial{C, T}(a, x)
end
function (::Type{Polynomial{C, T}}){C, T}(f::Function, x::Vector)
    σ, X = sortmonovec(PolyVar{C}, x)
    a = T[f(i) for i in σ]
    Polynomial{C, T}(a, X)
end
(::Type{Polynomial{C}}){C}(f::Function, x) = Polynomial{C, Base.promote_op(f, Int)}(f, x)

# FIXME why did I need it ?
Base.convert(::Type{Any}, p::Polynomial) = p

Base.convert{C}(::Type{PolyType{C}}, p::TermContainer{C}) = p
function Base.convert{S}(::Type{S}, p::TermContainer)
    s = zero(S)
    for t in p
        if sum(abs.(t.x.z)) > 0
            # The polynomial is not constant
            throw(InexactError())
        end
        s += S(t.α)
    end
    s
end

vars(p::Polynomial) = vars(p.x)

length(p::Polynomial) = length(p.a)
isempty(p::Polynomial) = isempty(p.a)
start(::Polynomial) = 1
done(p::Polynomial, state) = length(p) < state
next(p::Polynomial, state) = (p[state], state+1)

extdeg(p::Polynomial) = extdeg(p.x)
mindeg(p::Polynomial) = mindeg(p.x)
maxdeg(p::Polynomial) = maxdeg(p.x)

monomials(p::Polynomial) = p.x

function removemonomials(p::Polynomial, x::MonomialVector)
    # use the fact that monomials are sorted to do this O(n) instead of O(n^2)
    j = 1
    I = Int[]
    for (i,t) in enumerate(p)
        while j <= length(x) && x[j] > t.x
            j += 1
        end
        if j > length(x) || x[j] != t.x
            push!(I, i)
        end
    end
    Polynomial(p.a[I], p.x[I])
end
removemonomials(p::Polynomial, x::Vector) = removemonomials(p, MonomialVector(x))

function removedups{T}(adup::Vector{T}, Zdup::Vector{Vector{Int}})
    σ = sortperm(Zdup, rev=true)
    Z = Vector{Vector{Int}}()
    a = Vector{T}()
    i = 0
    j = 1
    while j <= length(adup)
        k = σ[j]
        if j == 1 || Zdup[k] != Zdup[σ[j-1]]
            push!(Z, Zdup[k])
            push!(a, adup[k])
            i += 1
        else
            a[i] += adup[k]
        end
        j += 1
    end
    a, Z
end
function vecpolynomialclean{C, T}(vars::Vector{PolyVar{C}}, adup::Vector{T}, Zdup::Vector{Vector{Int}})
    a, Z = removedups(adup, Zdup)
    Polynomial{C, T}(a, MonomialVector{C}(vars, Z))
end

eltype{C, T}(::Type{Polynomial{C, T}}) = T
getindex(p::Polynomial, I::Int) = Term(p.a[I[1]], p.x[I[1]])

type MatPolynomial{C, T} <: TermType{C, T}
    Q::Vector{T}
    x::MonomialVector{C}
end

# i < j
function trimap(i, j, n)
    div(n*(n+1), 2) - div((n-i+1)*(n-i+2), 2) + j-i+1
end

function getindex(p::MatPolynomial, I::NTuple{2,Int})
    n = length(p.x)
    p.Q[trimap(minimum(I), maximum(I), n)]
end
# MatPolynomial is not a subtype of AbstractArray so I need to define this too
getindex(p::MatPolynomial, i, j) = getindex(p, (i, j))

function getmat{C, T}(p::MatPolynomial{C, T})
    n = length(p.x)
    A = Matrix{T}(n, n)
    for i in 1:n, j in i:n
        A[j,i] = A[i,j] = p.Q[trimap(i,j,n)]
    end
    A
end

function trimat{T}(::Type{T}, f, n, σ)
    Q = Vector{T}(trimap(n, n, n))
    for i in 1:n
        for j in i:n
            Q[trimap(i, j, n)] = f(σ[i], σ[j])
        end
    end
    Q
end
function (::Type{MatPolynomial{C, T}}){C, T}(f::Function, x::MonomialVector{C}, σ=1:length(x))
    MatPolynomial{C, T}(trimat(T, f, length(x), σ), x)
end
function (::Type{MatPolynomial{C, T}}){C, T}(f::Function, x::Vector)
    σ, X = sortmonovec(x)
    MatPolynomial{C, T}(f, X, σ)
end
(::Type{MatPolynomial{C}}){C}(f::Function, x) = MatPolynomial{C, Base.promote_op(f, Int, Int)}(f, x)
MatPolynomial{T<:VectorOfPolyType{false}}(f::Function, x::Vector{T}) = MatPolynomial{false}(f, x)
MatPolynomial{T<:VectorOfPolyType{true}}(f::Function, x::Vector{T}) = MatPolynomial{true}(f, x)
MatPolynomial{C}(f::Function, x::MonomialVector{C}) = MatPolynomial{C}(f, x)

function MatPolynomial{C, T}(Q::Matrix{T}, x::MonomialVector{C})
    MatPolynomial{C, T}((i,j) -> Q[i, j], x)
end
function matpolyperm{C, T}(Q::Matrix{T}, x::MonomialVector{C}, σ)
    MatPolynomial{C, T}((i,j) -> Q[σ[i], σ[j]], x)
end
function MatPolynomial{T}(Q::Matrix{T}, x::Vector)
    σ, X = sortmonovec(x)
    matpolyperm(Q, X, σ)
end

function Base.convert{C, T}(::Type{Polynomial{C, T}}, p::MatPolynomial{C, T})
    if isempty(p.Q)
        zero(Polynomial{C, T})
    else
        n = length(p.x)
        U = typeof(2*p.Q[1] + p.Q[1])
        if C
            N = trimap(n, n, n)
            Z = Vector{Vector{Int}}(N)
            a = Vector{U}(N)
            for i in 1:n
                for j in i:n
                    k = trimap(i, j, n)
                    Z[k] = p.x.Z[i] + p.x.Z[j]
                    if i == j
                        a[k] = p.Q[k]
                    else
                        a[k] = 2*p.Q[k]
                    end
                end
            end
            v = p.x.vars
        else
            N = n^2
            x = Vector{Monomial}(N)
            a = Vector{U}(N)
            offset = 0
            for i in 1:n
                # for j in 1:n wouldn't be cache friendly for p.Q
                for j in i:n
                    k = trimap(i, j, n)
                    q = p.Q[k]
                    x[offset+k] = p.x[i] * p.x[j]
                    a[offset+k] = q
                    if i != j
                        offset += 1
                        x[offset+k] = p.x[j] * p.x[i]
                        a[offset+k] = q
                    end
                end
            end
            σ, X = sortmonovec(PolyVar{false}, x)
            a = a[σ]
            v = X.vars
            Z = X.Z
        end
        vecpolynomialclean(v, a, Z)
    end
end
Polynomial{C, T}(p::MatPolynomial{C, T}) = convert(Polynomial{C, T}, p)
TermContainer(p::MatPolynomial) = Polynomial(p)

type SOSDecomposition{C, T} <: TermType{C, T}
    ps::Vector{Polynomial{C, T}}
    function SOSDecomposition(ps::Vector{Polynomial{C, T}})
        new(ps)
    end
end
function (::Type{SOSDecomposition{C, T}}){C, T}(ps::Vector)
    SOSDecomposition(Vector{Polynomial{C, T}}(ps))
end
function (::Type{SOSDecomposition{C}}){C}(ps::Vector)
    T = reduce(promote_type, Int, map(eltype, ps))
    SOSDecomposition{C, T}(ps)
end
SOSDecomposition{T<:VectorOfPolyType{false}}(ps::Vector{T}) = SOSDecomposition{false}(ps)
SOSDecomposition{T<:VectorOfPolyType{true}}(ps::Vector{T}) = SOSDecomposition{true}(ps)

function Base.convert{C, T}(::Type{MatPolynomial{C, T}}, p::SOSDecomposition)
    X = mergemonovec(map(p -> p.x, p))
    m = length(p)
    n = length(X)
    Q = zeros(T, m, n)
    for i in 1:m
        q = p[i]
        k = 1
        for j in 1:n
            if k <= length(q) && X[j] == q.x[k]
                Q[i, j] = q.a[k]
                k += 1
            end
        end
    end
    MatPolynomial(Q' * Q, X)
end
MatPolynomial{C, T}(p::SOSDecomposition{C, T}) = MatPolynomial{C, T}(p)

function Base.convert{C, T}(::Type{SOSDecomposition{C, T}}, p::MatPolynomial)
    n = length(p.x)
    # TODO LDL^T factorization for SDP is missing in Julia
    # it would be nice to have though
    A = getmat(p)
    Q = chol(A)
    m = size(Q, 1)
    ps = [Polynomial{C, T}(Q[i,:], p.x) for i in 1:m]
    SOSDecomposition(ps)
end
# Without LDL^T, we need to do float(T)
SOSDecomposition{C, T}(p::MatPolynomial{C, T}) = SOSDecomposition{C, float(T)}(p)

length(p::SOSDecomposition) = length(p.ps)
isempty(p::SOSDecomposition) = isempty(p.ps)
start(p::SOSDecomposition) = start(p.ps)
done(p::SOSDecomposition, state) = done(p.ps, state)
next(p::SOSDecomposition, state) = next(p.ps, state)
getindex(p::SOSDecomposition, i::Int) = p.ps[i]
