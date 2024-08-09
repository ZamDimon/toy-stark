# Prime field
p = 3*(1<<30) + 1
Fp.<w> = GF(p, modulus='primitive') # Defining a prime field with generator w
