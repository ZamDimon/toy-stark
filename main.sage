from typing import List, Tuple
from field import p, w, Fp
from merkle_tree import MerkleTree

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
print(f"Example verifier's relation is ({witness}, {trace[-1]})")

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
k = (p - 1) // l
g = w**k

# Defining the subgroup
G = [g**i for i in range(l)]

# Now, testing that everything is correct
assert g.multiplicative_order() == l, "g was found incorrectly"

# Defining the polynomial ring
R = Fp['X']
f = R.lagrange_polynomial([(G[i], trace[i]) for i in range(l-1)])
print(f"Polynomial at X=2 equals {f(2)}")

# Now, we generate a coset D of size L = 8*l by finding w*H where <h> = H
L = 8*l
# Finding h
assert (p - 1) % L == 0, f"There is no h that generates a subgroup of size {L}"
k = (p - 1) // L
h = w**k

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