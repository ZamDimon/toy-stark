from __future__ import annotations
from typing import List, Tuple, TypeAlias
from field import p, w, Fp
from merkle_tree import MerkleTree
from channel import Channel
from fri import FRILayer, FRICommitment

def compute_square_fibonacci_trace(x0: Fp, x1: Fp, k: Integer) -> List[Fp]:
    """
    Based on provided x[0] and x[1], calculates the x[k] which
    is given by the following relation:
    x[k+2] = x[k]**2 - x[k+1]**2
    """

    trace = [x0, x1] # Initialize the trace with x[0] and x[1]
    for i in range(2, k+1):
        trace.append(trace[i-2]**2 + trace[i-1]**2)

    return trace

k = 1022 # Just a constant in the protocol

# Verifying that the trace is correct
test_trace = compute_square_fibonacci_trace(Fp(1), Fp(3141592), k)
assert len(test_trace) == k + 1, "Trace length is not correct"
assert test_trace[0] == Fp(1), "First element of trace is not 1"
assert test_trace[-1] == Fp(2338775057), "Last element of trace is not correct"

print("Fibonacci Trace is correct")

# Verifier wants to convince that he knows such x for which
# the kth Square Fibonacci number is y where x[0] = 1, x[1] = x
def generate_relation() -> Tuple[Fp, List[Fp]]:
    """
    Generates the relation between x[0] and x[1] for the verifier
    to verify. Relation is a pair (x, y) as described above, but 
    instead of y we provide the whole trace
    """

    x0 = Fp(1)
    x1 = Fp.random_element() # Picking a random x
    trace = compute_square_fibonacci_trace(x0, x1, k)
    return x1, trace

#witness, trace = generate_relation()
witness, trace = Fp(3141592), compute_square_fibonacci_trace(Fp(1), Fp(3141592), k)
y = trace[-1] # Claimed kth Square Fibonacci number
print(f"Example verifier's relation is ({witness}, {y})")

# Now, we are going to use the multiplicative
# subgroup of Fp, so we need to verify that 
# our generator is correct

# Defining the multiplicative order
r = w.multiplicative_order()
assert r == p-1, "Order is not correct"
assert w**r == 1, "Generator is not correct"

# Defining a subgroup G[i] := g**i or order 1024
l = 1024 # Order of a subgroup

# Finding g such that g generates a subgroup of order 1024
assert (p - 1) % l == 0, f"There is no g that generates a subgroup of size {l}"
q = (p - 1) // l
g = w**q

# Defining the subgroup
G = [g**i for i in range(l)]

# Now, testing that everything is correct
assert g.multiplicative_order() == l, "g was found incorrectly"

# Defining the polynomial ring
R.<X> = PolynomialRing(Fp)
f = R.lagrange_polynomial([(G[i], trace[i]) for i in range(l-1)])
print(f"Polynomial at X=2 equals {f(2)}")

# Now, we generate a coset D of size L = 8*l by finding w*H where <h> = H
L = 8*l
# Finding h
assert (p - 1) % L == 0, f"There is no h that generates a subgroup of size {L}"
q = (p - 1) // L
h = w**q

# Defining the subgroup H and D
H = [h**i for i in range(L)]
D = [w*h for h in H] 

# Now, testing that everything is correct
assert h.multiplicative_order() == L, "h was found incorrectly"
assert len(D) == L, "D was found incorrectly"
assert len(set(D)) == len(D), "No duplicates are present in D"
assert len(set(H)) == len(H), "No duplicates are present in H"

# Now, computing evaluation
f_D = [f(d) for d in D]
f_commitment = MerkleTree(f_D)
print(f'Commitment to the given polynomial is {f_commitment.get_root()}')

# Now, we want to verift the polynomial constraints. We need to prove that:
# 1. trace[0] = 1, meaning (X - g^0) | (f(X) - 1)
# 2. trace[k] = y, meaning (X - g^k) | (f(X) - y)
# 3. For each u = g^i, i in [1020], we have (X - u) | (f(g^2*X) - f(g*X)^2 - f(X)^2)
# 
# The last condition implies that product (X - g^i) for each i in [1020] should 
# divide the polynomial f(g^2*X) - f(g*X)^2 - f(X)^2

# Bulding polynomial p0(X) = (f(X) - 1) / (X - g^0)
assert (f - 1) % (X - g**0) == 0, "f(1) is not equal to 1"
p0 = (f - 1) / (X - g**0) # Our first constraint

# Building polynomial p1(X) = (f(X) - y) / (X - g^k)
assert (f - y) % (X - g**k) == 0, f"f({g**k}) is not equal to {y}"
p1 = (f - y) / (X - g**k) # Our second constraint

# Building polynomial p2(X) = (f(g^2*X) - f(g*X)^2 - f(X)^2) / (\prod_{i=0}^k of X - g^i)
# Now, the product can be evaluated more effectively. Notice that the product is equal to
# \prod_{g \in G}(X-g) / {\prod_{i=k+1}^{ |G| } (X - g^i)}, where the former product is
# simply X^(|G|) - 1 while the latter is relatively small
p2_denominator = (X**l - 1) / prod([X - g**i for i in range(k-1, l)])
# Now, let us check why this holds
assert p2_denominator == prod([X - g**i for i in range(k-1)]), "Denominator is not correct"

# Now, we can build the polynomial p2(X)
p2 = (f(g**2*X) - f(g*X)**2 - f(X)**2) / p2_denominator

def build_composition_polynomial() -> PolynomialRing:
    """
    Builds the composition polynomial p(X) = alpha_0 * p0(X) + alpha_1 * p1(X) + alpha_2 * p2(X)
    for some random field elements alpha_0, alpha_1, alpha_2
    """

    # Picking random alpha's
    alpha_0 = Fp.random_element()
    alpha_1 = Fp.random_element()
    alpha_2 = Fp.random_element()

    # Building the polynomial
    cp = alpha_0 * p0 + alpha_1 * p1 + alpha_2 * p2
    return R(cp)

def get_composition_polynomial_evaluation(D: List[Fp]) -> List[Fp]:
    """
    Evaluates the composition polynomial at each point of D
    """

    cp = build_composition_polynomial()
    return [cp(d) for d in D]

# Now, we are building the commitment
cp_D = get_composition_polynomial_evaluation(D)
cp_commitment = MerkleTree(cp_D)
print(f'Commitment to the composition polynomial is {cp_commitment.get_root()}')

# Now, let us do the FRI commitment
test_channel = Channel()
cp = build_composition_polynomial()
commitment = FRICommitment(cp, D, test_channel).commit()

fri_polys, fri_domains, fri_layers, fri_merkles = commitment
assert len(fri_layers) == 11, "Number of layers is not correct"
assert len(fri_layers[-1]) == 8, "Last layer is not correct"
assert len(set(fri_layers[-1])) == 1, "All elements in the last layer are identical"