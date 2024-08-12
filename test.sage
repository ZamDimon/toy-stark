p = 3*2^(30) + 1
Fp = GF(p)
E = EllipticCurve(Fp, [0, 1])

A = E.random_point()
B = E.random_point()

print(100000000000 * A)