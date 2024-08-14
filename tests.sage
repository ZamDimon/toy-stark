from __future__ import annotations
from typing import Callable, TypeAlias, List, Tuple

# Tests
from src.arithmetization.fibonacci import TestFibonacciArithmetization
from src.fri.fri import TestFRILayer
from src.math.domain import TestDomains

TestFn: TypeAlias = Callable[[None], None]

class TestDebugger:
    """
    Class for debugging the tests

    Since testing stuff in SageMath is such a pain in the ass, 
    we need a separate package for that :(
    """

    _TEMPLATE = '{:<40s} {:<10s}'
    _HEADERS = ['test_name', 'status']

    def __init__(self, tests: List[Tuple[TestFn, str]]) -> None:
        """
        Initializes the instance of test debugger
        """

        self._tests = tests

    def _print_row(self, row: List[str]) -> None:
        """
        Prints the row based on the provided row represented as a list
        """

        print('{:<40s} {:<15s}'.format(*row))

    def _print_line(self) -> None:
        """
        Prints the line in the table
        """
        print('-'*55)

    def _print_header(self) -> None:
        """
        Prints the header of the table
        """

        self._print_line()
        self._print_row(TestDebugger._HEADERS)
        self._print_line()

    def run(self) -> None:
        """
        Runs all the provided tests and debugs whether each has passed or not
        """

        self._print_header()
        for test_fn, name in self._tests:
            try:
                test_fn()
                self._print_row([name, 'passed ✅'])
            except:
                self._print_row([name, 'failed ❌'])
                
        self._print_line()

if __name__ == '__main__':
    # Running all the tests
    debugger = TestDebugger([
        (TestFRILayer().test_next_fri_polynomial, "FRI polynomial operator"),
        (TestFRILayer().test_next_domain, "FRI domain operator"),
        (TestDomains().test_domains_order, "domain generation"),
        (TestFibonacciArithmetization().test_compute_square_fibonacci_trace, "fibonacci sequence computation")
    ]).run()
