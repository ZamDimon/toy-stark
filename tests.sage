from typing import Callable
from fri import TestFRILayer

def run_test(test: Callable[[None], None], name: str) -> None:
    test()
    print(f"{name} passed!")

run_test(TestFRILayer().test_next_fri_polynomial, "FRI polynomial operator")
run_test(TestFRILayer().test_next_domain, "FRI domain operator")