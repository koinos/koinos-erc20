#!/usr/bin/env python3

# Quick Python script to figure out a polynomial approximation g(t) to the function f(t) = (1/2)^t

# f(t) = (1/2)^t
# f(0) = 1
# f(1) = 1/2
# f(t) = e^(log(1/2) t) = e^(-log(2) t)
# f'(t) = -log(2) (1/2)^t
# f'(0) = -log(2)
# f'(1) = -log(2)/2

# g(t) = a_0 + a_1 t + a_2 t^2 + a_3 t^3
# g'(t) = a_1 + 2 a_2 t + 3 a_3 t^2
# g(0) = a_0
# g'(0) = a_1
# g(1) = a_0 + a_1 + a_2 + a_3
# g'(1) = a_1 + 2 a_2 + 3 a_3
#
#        [ 1 0 0 0 ]^-1   [ 1  0  0  0 ]
# A^-1 = [ 0 1 0 0 ]    = [ 0  1  0  0 ]
#        [ 1 1 1 1 ]      [-3 -2  3 -1 ]
#        [ 0 1 2 3 ]      [ 2  1 -2  1 ]
#
# A^-1 [1, -log(2), 1/2, -log(2)/2]^T
# = [1                            ]
#   [-log(2)                      ]
#   [-3 + 2log(2) + 3/2 + log(2)/2]
#   [ 2 -  log(2) - 1   - log(2)/2]

from math import log

coeff = [1.0, -log(2.0), -1.5 + 2.5*log(2.0), 1.0 - 1.5*log(2.0)]
print([hex(int(a * 2**32 + 0.5)) for a in coeff])
