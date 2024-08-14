import unittest
from typing import List

from src.math.field import p, w, Fp

def _find_generator(p: Integer, l: Integer) -> Fp:
    """
    Finds a generator of a subgroup of order l in the field Fp

    Args:
        - p (Integer): Prime number
        - l (Integer): Order of the subgroup

    Returns:
        - Integer: Generator of the subgroup
    """

    # Finding g such that g generates a subgroup of order 1024
    assert (p - 1) % l == 0, f"There is no g that generates a subgroup of size {l}"
    q = (p - 1) // l
    g = w**q
    return g

# Constants
BLOWUP_FACTOR = 8 # 1/rho parameter in the FRI protocol
assert BLOWUP_FACTOR >= 4, "BLOWUP_FACTOR should be at least 4"

# Domain sizes
TRACE_DOMAIN_SIZE = 1024
FRI_DOMAIN_SIZE = BLOWUP_FACTOR * TRACE_DOMAIN_SIZE

# Domain generators
TRACE_DOMAIN_GENERATOR = _find_generator(p, TRACE_DOMAIN_SIZE)
FRI_DOMAIN_GENERATOR = _find_generator(p, FRI_DOMAIN_SIZE)

def get_trace_domain() -> List[Fp]:
    """
    Returns the base domain for the FRI protocol
    """

    g = TRACE_DOMAIN_GENERATOR # Just for notation purposes
    return [g**i for i in range(TRACE_DOMAIN_SIZE)]

def get_fri_domain() -> List[Fp]:
    """
    Returns the FRI evaluation domain for the FRI protocol
    """

    # We need to return a coset w*H where H is of order of evaluation domain
    h = FRI_DOMAIN_GENERATOR # Just for notation purposes
    H = [h**i for i in range(FRI_DOMAIN_SIZE)]

    # We are picking the coset to have trace domain disjoint from evaluation domain
    return [w*h for h in H]

class TestDomains(unittest.TestCase):
    """
    Tests for the domain generation
    """

    def test_domains_order(self) -> None:
        """
        Tests the domains generation correctness
        """

        assert _TRACE_DOMAIN_GENERATOR.multiplicative_order() == TRACE_DOMAIN_SIZE, "trace domain generator is not correct"
        D = get_trace_domain()
        assert len(D) == TRACE_DOMAIN_SIZE, "D was found incorrectly"
        assert len(set(D)) == len(D), "No duplicates are present in D"

        H = get_fri_domain()
        assert len(H) == FRI_DOMAIN_SIZE, "H was found incorrectly"
        assert len(set(H)) == len(H), "No duplicates are present in H"
