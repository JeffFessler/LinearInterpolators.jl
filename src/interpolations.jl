#
# interpolations.jl --
#
# Implement linear interpolation (here "linear" means that the result depends
# linearly on the interpolated data).
#
#------------------------------------------------------------------------------
#
# This file is part of the LinearInterpolators package licensed under the MIT
# "Expat" License.
#
# Copyright (C) 2016-2018, Éric Thiébaut.
#

module Interpolations

export
    SparseInterpolator,
    SparseUnidimensionalInterpolator,
    TabulatedInterpolator,
    limits,
    inferior,
    superior,
    getcoefs

import Base: eltype, length, size, first, last, clamp, convert

using ..Kernels
import ..Kernels: boundaries

using TwoDimensional.AffineTransforms
using TwoDimensional: AffineTransform2D

using LazyAlgebra
import LazyAlgebra: apply, apply!, vcreate, output_size, input_size

"""

`support(A)` yields the size of the support of the interpolation kernel.
Argument can be an interpolation kernel, an interpolation method or an
interpolator.

"""
support(::Kernel{T,S,B}) where {T,S,B} = S

"""

All interpolation limits inherit from the abstract type `Limits` and are the
combination of an extrapolation method and the length the dimension to
interpolate.

"""
abstract type Limits{T<:AbstractFloat} end # FIXME: add parameter S

eltype(::Limits{T}) where {T} = T
length(B::Limits{T}) where {T} = B.len
size(B::Limits{T}) where {T} = (B.len,)
size(B::Limits{T}, i::Integer) where {T} =
    (i == 1 ? B.len : i > 1 ? 1 : throw(BoundsError()))
first(B::Limits{T}) where {T} = 1
last(B::Limits{T}) where {T} = B.len
clamp(i, B::Limits{T}) where {T} = clamp(i, first(B), last(B))


"""
```julia
limits(ker::Kernel, len)
```

yields the concrete type descendant of `Limits` for interpolation with kernel
`ker` along a dimension of length `len` and applying the boundary conditions
embedded in `ker`.

"""
function limits end


"""
```julia
getcoefs(ker, lim, x) -> j1, j2, ..., w1, w2, ...
```

yields the indexes of the neighbors and the corresponding interpolation weights
for interpolating at position `x` by kernel `ker` with the limits implemented
by `lim`.

"""
function getcoefs end

"""
# Linear interpolation

Here *linear* means that the result depends linearly on the interpolated array.
The interpolation functions (or kernels) may be linear or not (*e.g.*, cubic
spline).


## Unidimensional interpolation

Unidimensional interpolation is done by:

```julia
apply(ker, x, src) -> dst
```

which interpolates source array `src` with kernel `ker` at positions `x`, the
result is an array of same dimensions as `x`.  The destination array can be
provided:

```julia
apply!(dst, ker, x, src) -> dst
```

which overwrites `dst` with the result of the interpolatation of source `src`
with kernel `ker` at positions specified by `x`.  If `x` is an array, `dst`
must have the same size as `x`; otherwise, `x` may be a fonction which is
applied to all indices of `dst` (as generated by `eachindex(dst)`) to produce
the coordinates where to interpolate the source.  the destination `dst` is
returned.

The adjoint/direct operation can be applied:

```julia
apply(P, ker, x, src) -> dst
apply!(dst, P, ker, x, src) -> dst
```

where `P` is either `Adjoint` or `Direct`.  If `P` is omitted, `Direct` is
assumed.

To linearly combine the result and the contents of the destination array, the
following syntax is also implemented:

```julia
apply!(α, P, ker, x, src, β, dst) -> dst
```

which overwrites `dst` with `β*dst` plus `α` times the result of the operation
implied by `P` (`Direct` or `Adjoint`) on source `src` with kernel `ker` at
positions specified by `x`.


## Separable multi-dimensional interpolation

Separable multi-dimensional interpolation consists in interpolating each
dimension of the source array with, possibly, different kernels and at given
positions.  For instance:

```julia
apply(ker1, x1, [ker2=ker1,] x2, src) -> dst
```

yields the 2D separable interpolation of `src` with kernel `ker1` at positions
`x1` along the first dimension of `src` and with kernel `ker2` at positions
`x2` along the second dimension of `src`.  Note that, if omitted the second
kernel is assumed to be the same as the first one.  The above example extends
to more dimensions (providing it is implemented).  Positions `x1`, `x2`,
... must be unidimensional arrays their lengths give the size of the result of
the interpolation.

The apply the adjoint and/or linearly combine the result of the interpolation
and the contents of the destination array, the same methods as for
unidimensional interpolation are supported, it is sufficient to replace `ker,x`
by `ker1,x1,[ker2=ker1,]x2`.


## Nonseparable multi-dimensional interpolation

Nonseparable 2D interpolation is implemented where the coordinates to
interpolate are given by an affine transform which converts the indices in the
destination array into fractional coordinates in the source array (for the
direct operation).  The syntax is:

```julia
apply!(dst, [P=Direct,] ker1, [ker2=ker1,] R, src) -> dst
```

where `R` is an `AffineTransform2D` and `P` is `Direct` (the default) or
`Adjoint`.

""" apply

function coefficients end
function rows end
function columns end
function fit end
function regularize end
function regularize! end
function inferior end
function superior end

include("interp/meta.jl")
import .Meta
include("interp/flat.jl")
include("interp/safeflat.jl")
include("interp/tabulated.jl")
using .TabulatedInterpolators
include("interp/sparse.jl")
using .SparseInterpolators
include("interp/unidimensional.jl")
using .UnidimensionalInterpolators
include("interp/separable.jl")
include("interp/nonseparable.jl")

end
