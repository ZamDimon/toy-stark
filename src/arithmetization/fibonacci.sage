from __future__ import annotations
import unittest
from typing import List

from src.math.field import Fp, R, X
from src.math.domain import get_trace_domain, get_fri_domain, TRACE_DOMAIN_SIZE, FRI_DOMAIN_SIZE, TRACE_DOMAIN_GENERATOR
from src.utils.channel import Channel

class FibonacciArithmetization:
    """
    Arithmetization of Square Fibonacci Sequence.
    """

    def __init__(self, witness: Fp, trace_length: Integer, verbose: bool = True) -> None:
        """
        Initializes the arithmetization with the provided witness (being
        the element x[1] in the sequence) and the number of element 
        to compute in the sequence.
        """

        self._witness = witness
        self._verbose = verbose

        x0 = Fp(1)
        x1 = witness

        if self._verbose:
            print(f"Arithmetization of Fibonacci sequence with x[0] = {x0} and x[1] = {x1}...")

        self._trace = self._compute_trace(x0, x1, trace_length)
        self._trace_length = trace_length
        self._statement = self._trace[-1] # The statement is the last element of the trace
        if self._verbose:
            print(f"Trace computed successfully!")
            print(f"Statement we are proving: I know such witness, producing as the {trace_length}th element of the square fibonacci sequence the value {self._statement}")


    @property
    def witness(self) -> Fp:
        """
        Returns the witness of the arithmetization.
        """

        return self._witness


    @property
    def trace(self) -> List[Fp]:
        """
        Returns the trace of the arithmetization.
        """

        return self._trace


    @staticmethod
    def init_with_random_witness(trace_length: Integer, verbose: bool = True) -> FibonacciArithmetization:
        """
        Generates the relation between x[0] and x[1] for the verifier
        to verify. Relation is a pair (x, y) as described above, but 
        instead of y we provide the whole trace
        """

        witness = Fp.random_element()
        if verbose:
            print(f"Generated random witness: {witness}")

        return FibonacciArithmetization(witness, trace_length, verbose=verbose)


    @staticmethod    
    def _compute_trace(x0: Fp, x1: Fp, k: Integer) -> List[Fp]:
        """
        Based on provided x[0] and x[1], calculates the x[k] which
        is given by the following relation:
        x[k+2] = x[k]**2 + x[k+1]**2 (mod p)
        """

        trace = [x0, x1] # Initialize the trace with x[0] and x[1]
        for i in range(2, k+1):
            trace.append(trace[i-2]**2 + trace[i-1]**2)

        return trace


    def _get_trace_polynomial(self) -> List[Fp]:
        """
        Takes the trace and encodes it into a codeword. In other words, it interpolates
        the trace into the trace domain space and returns the evaluation at FRI domain space
        """

        G = get_trace_domain()
        return R.lagrange_polynomial([(G[i], self._trace[i]) for i in range(self._trace_length+1)])
        

    def get_constraint_polynomials(self) -> List[PolynomialRing]:
        """
        Computes the constraint polynomials for the Fibonacci sequence
        """

        # Initializing some helper variables
        if self._verbose:
            print("Computing the trace polynomial by interpolation over the trace domain...")

        trace_polynomial = self._get_trace_polynomial()
        G = get_trace_domain()
        
        # Here, we want to verift the polynomial constraints. We need to prove that:
        # 1. trace[0] = 1, meaning (X - g^0) | (f(X) - 1)
        # 2. trace[k] = y, meaning (X - g^k) | (f(X) - y)
        # 3. For each u = g^i, i in [1020], we have (X - u) | (f(g^2*X) - f(g*X)^2 - f(X)^2)
        # 
        # The last condition implies that product (X - g^i) for each i in [1020] should 
        # divide the polynomial f(g^2*X) - f(g*X)^2 - f(X)^2

        # Bulding polynomial p0(X) = (f(X) - 1) / (X - g^0)
        assert (trace_polynomial - 1) % (X - G[0]) == 0, "f(1) is not equal to 1"
        p0 = (trace_polynomial - 1) / (X - G[0]) # Our first constraint

        # Building polynomial p1(X) = (f(X) - y) / (X - g^k)
        print(trace_polynomial(G[self._trace_length]))
        assert (trace_polynomial - self._statement) % (X - G[self._trace_length]) == 0, "f(trace_length) is not equal to the witness"
        p1 = (trace_polynomial - self._statement) / (X - G[self._trace_length]) # Our second constraint

        # Building polynomial p2(X) = (f(g^2*X) - f(g*X)^2 - f(X)^2) / (\prod_{i=0}^k of X - g^i)
        # Now, the product can be evaluated more effectively. Notice that the product is equal to
        # \prod_{g \in G}(X-g) / {\prod_{i=k+1}^{ |G| } (X - g^i)}, where the former product is
        # simply X^(|G|) - 1 while the latter is relatively small
        p2_denominator = (X**TRACE_DOMAIN_SIZE - 1) / prod([X - G[i] for i in range(self._trace_length-1, TRACE_DOMAIN_SIZE)])
        # Now, let us check why this holds
        assert p2_denominator == prod([X - G[i] for i in range(self._trace_length-1)]), "Denominator is not correct"

        # Now, we can build the polynomial p2(X)
        p2 = (trace_polynomial(G[2]*X) - trace_polynomial(G[1]*X)**2 - trace_polynomial(X)**2) / p2_denominator
        return [p0, p1, p2]

    
    def get_composition_polynomial(self, channel: Channel) -> PolynomialRing:
        """
        Computes the composition polynomial for the Fibonacci sequence
        """

        # Getting the constraint polynomials
        constraint_polynomials = self.get_constraint_polynomials()

        # Now, we need to commit to the composition polynomial
        composition_polynomial = sum([channel.get_random_scalar() * p for p in constraint_polynomials])
        return composition_polynomial


    def get_composition_polynomial_codeword(self, channel: Channel) -> List[Fp]:
        """
        Computes the composition polynomial codeword for the Fibonacci sequence
        """

        # Getting the composition polynomial
        composition_polynomial = self.get_composition_polynomial(channel)

        # Now, we need to evaluate the composition polynomial at the FRI domain
        return [composition_polynomial(x) for x in get_fri_domain()]
        

class TestFibonacciArithmetization(unittest.TestCase):
    """
    Tests for the Fibonacci Arithmetization.
    """

    def test_compute_square_fibonacci_trace(self) -> None:
        """
        Tests the computation of the square Fibonacci trace.
        """

        # Verifying that the trace is correct
        k = 1022
        test_trace = FibonacciArithmetization._compute_trace(Fp(1), Fp(3141592), k)
        assert len(test_trace) == k + 1, "Trace length is not correct"
        assert test_trace[0] == Fp(1), "First element of trace is not 1"
        assert test_trace[-1] == Fp(2338775057), "Last element of trace is not correct"
