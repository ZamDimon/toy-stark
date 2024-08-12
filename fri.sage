from __future__ import annotations
from typing import List, Tuple, TypeAlias
import unittest

from field import p, w, Fp, R, X
from merkle_tree import MerkleTree
from channel import Channel

class FRILayer:
    """
    Represents a single FRI layer in the protocol
    """

    def __init__(self, polynomial: PolynomialRing, domain: List[Fp]) -> None:
        """
        Initializes the FRI layer with the given polynomial and domain
        """

        self._polynomial = polynomial
        self._domain = domain
        self._layer = [polynomial(x) for x in domain]

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

        odd_coefficients = polynomial.list()[1::2] # Taking odd coefficients
        even_coefficients = polynomial.list()[::2] # Taking even coefficients
        odd_polynomial = R(odd_coefficients) # Constructing odd polynomial
        even_polynomial = R(even_coefficients) # Constructing even polynomial

        # Applying FRI operator: just a random linear combination
        return even_polynomial + beta * odd_polynomial

    def __self_next_fri_polynomial(self, beta: Fp) -> PolynomialRing:
        """
        Computes the next FRI polynomial for the object
        """

        return FRILayer._next_fri_polynomial(self._polynomial, beta)

    def __self_next_fri_domain(self) -> List[Fp]:
        """
        Computes the next FRI domain for the object
        """

        return FRILayer._next_fri_domain(self._domain)

    def next_layer(self, beta: Fp) -> FRILayer:
        """
        Computes the next FRI layer based on the provided beta
        """

        return FRILayer(
            self.__self_next_fri_polynomial(beta),
            self.__self_next_fri_domain(),
        )

class FRICommitment:
    """
    Represents the FRI commitment
    """

    def __init__(self, 
        composition_polynomial: PolynomialRing, 
        evaluation_domain: List[Fp],
        channel: Channel) -> None:
        """
        Initializes the FRI commitment with the given composition polynomial and evaluation domain
        """

        self._composition_polynomial = composition_polynomial
        self._evaluation_domain = evaluation_domain
        self._channel = channel

    def commit(self) -> None:
        """
        Computes the FRI commitment
        """
        
        composition_polynomial_evaluation = [
            self._composition_polynomial(x) for x in self._evaluation_domain
        ]
        merkle_tree = MerkleTree(composition_polynomial_evaluation)

        # Initializing the FRI polynomials, FRI domains, FRI layers, FRI Merkle Trees
        fri_polynomials = [self._composition_polynomial]
        fri_domains = [self._evaluation_domain]
        fri_layers = [composition_polynomial_evaluation]
        fri_merkles = [merkle_tree]

        while fri_polynomials[-1].degree() > 0:
            beta = self._channel.get_random_scalar() # Getting a random scalar
            new_layer = FRILayer(fri_polynomials[-1], fri_domains[-1]).next_layer(beta) # Getting the next layer
            
            # Below, we simply append the new layer to the lists
            fri_polynomials.append(new_layer._polynomial)
            fri_domains.append(new_layer._domain)
            fri_layers.append(new_layer._layer)
            fri_merkles.append(MerkleTree(new_layer._layer))

            # Sending the data to the channel
            self._channel.send(fri_merkles[-1].get_root())
        
        # Finally, sending the last element
        self._channel.send(str(fri_polynomials[-1](0)))
        return fri_polynomials, fri_domains, fri_layers, fri_merkles

class TestFRILayer(unittest.TestCase):
    """
    Tests for FRI Layer
    """

    def test_next_fri_polynomial(self) -> None:
        """
        Tests the next FRI polynomial
        """

        q = 6*X**4 + 5*X**3 + 3*X**2 + 3*X + 1

        beta = Fp.random_element()
        qq = FRILayer._next_fri_polynomial(q, beta)
        assert qq == (6*X**2 + 3*X + 1) + beta * (5*X + 3), "next FRI polynomial is not correct"

    def test_next_domain(self) -> None:
        """
        Tests the next FRI domain
        """

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

        # Now, applying the FRI operator
        next_domain = FRILayer._next_fri_domain(G)
        assert len(next_domain) == l//2, "Next domain's size is not correct"
        assert len(set(next_domain)) == l//2, "Some duplicates are present in the next domain"
