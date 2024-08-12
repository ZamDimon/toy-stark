from __future__ import annotations
from typing import List, Tuple, TypeAlias

from field import p, w, Fp

class FRILayer:
    """
    Represents a single FRI layer in the protocol
    """

    def __init__(self, polynomial: PolynomialRing, domain: List[Fp]):
        """
        Initializes the FRI layer with the given polynomial and domain
        """
        self._polynomial = polynomial
        self._domain = domain

    @staticmethod
    def _next_fri_domain(fri_domain: List[Fp]) -> List[Fp]:
        """
        Given a FRI domain, returns the next domain
        """

        return [x**2 for x in fri_domain[:len(fri_domain)//2]]
    
    @staticmethod
    def _next_fri_polynomial(polynomial: PolynomialRing, beta: Fp) -> PolynomialRing:
        """
        Given a polynomial, returns the next polynomial using FRI operator
        """

        odd_coefficients = polynomial.list()[1::2]
        even_coefficients = polynomial.list()[::2]
        odd = R(odd_coefficients)
        even = R(even_coefficients)

        return even + beta*odd

    def next_layer(self) -> FRILayer:
        """
        Computes the next FRI layer
        """

        return FRILayer(
            FRILayer._next_fri_polynomial(self.polynomial, self.beta), 
            FRILayer._next_fri_domain(self.domain), 
            Fp.random_element()
        )

# Let us test the next FRI function
R.<X> = PolynomialRing(Fp)
q = 6*X^4 + 5*X^3 + 3*X^2 + 3*X + 1
qq = FRILayer._next_fri_polynomial(q, Fp(2))
assert qq == (6*X^2 + 3*X + 1) + 2*(5*X + 3), "Next FRI polynomial is not correct"