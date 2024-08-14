from __future__ import annotations
from typing import List, Tuple, TypeAlias

# Internal imports
from src.math.field import p, w, Fp, R, X
from src.math.domain import get_trace_domain, get_fri_domain, TRACE_DOMAIN_SIZE
from src.utils.merkle_tree import MerkleTree
from src.utils.channel import Channel
from src.fri.fri import FRILayer, FRICommitment
from src.arithmetization.fibonacci import FibonacciArithmetization

if __name__ == "__main__":
    TRACE_LENGTH = 1022 # Depth of the Fibonacci sequence
    assert TRACE_LENGTH < TRACE_DOMAIN_SIZE, "Trace length is too large"

    # Creating a channel for simulating the communication between prover and verifier
    # The proof will be generated using this channel
    channel = Channel()
    arithmetization = FibonacciArithmetization.init_with_random_witness(TRACE_LENGTH)

    composition_polynomial = arithmetization.get_composition_polynomial(channel)
    codeword = arithmetization.get_composition_polynomial_codeword(channel)
    codeword_tree = MerkleTree(codeword)
    print(f'Commitment to the composition polynomial is {codeword_tree.get_root()}')
    
    commitment = FRICommitment(R(composition_polynomial), get_fri_domain(), channel)
    commitment.commit()
    commitment.decommit()

    # Saving proof to proof.txt file
    with open('proof.txt', 'w') as f:
        f.write(str(channel._proof))
    
    print("Proof generated successfully!")
