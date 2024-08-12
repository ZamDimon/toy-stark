from typing import List
from hashlib import sha256
from math import log2, ceil
from src.math.field import Fp

class MerkleTree(object):
    """
    A super naive implemented of the Merkle Tree in SageMath
    """

    def __init__(self, data: List[Fp]):
        """
        Initializes a Merkle Tree based on the provided list of objects
        """

        n = len(data) # Get the number of elements
        assert n > 0, "Cannot build an empty Merkle Tree"
        N = 2 ** ceil(log2(n)) # Get the number of leaves

        # Now, writing the data to the class...
        self._n = n # Number of elements
        self._data = data + [Fp(0)] * (N - n) # Data padded with zeros
        self._height = int(log2(N)) # Height of the tree
        self._facts = {} # Dictionary to store the facts
        self._root = self._build_tree() # Root of the tree

    def get_root(self) -> str:
        """
        Returns the root of the Merkle Tree
        """

        return self._root

    def get_authentication_path(self, leaf_id):
        """
        Returns the authentication path for the leaf with the provided id
        """

        assert 0 <= leaf_id < self._n, "Leaf id is out of bounds"

        node_id = leaf_id + self._n
        current = self._root
        decommitment = []

        # In a Merkle Tree, the path from the root to a leaf, corresponds to the the leaf id's
        # binary representation, starting from the second-MSB, where '0' means 'left', and '1' means
        # 'right'.
        # We therefore iterate over the bits of the binary representation - skipping the '0b'
        # prefix, as well as the MSB.
        for bit in bin(node_id)[3:]:
            current, auth = self._facts[current]
            if bit == '1':
                auth, current = current, auth
            decommitment.append(auth)

        return decommitment

    def _build_tree(self):
        """
        Based on the self._data, builds the Merkle Tree
        """

        return self._recursive_build_tree(1)

    def _recursive_build_tree(self, node_id: Integer):
        """
        Recursively builds the Merkle Tree
        """

        if node_id >= len(self._data):
            # A leaf.
            id_in_data = node_id - len(self._data)
            leaf_data = str(self._data[id_in_data])
            h = sha256(leaf_data.encode()).hexdigest()
            self._facts[h] = leaf_data
            return h
        
        # An internal node.
        left = self._recursive_build_tree(node_id * 2)
        right = self._recursive_build_tree(node_id * 2 + 1)
        h = sha256((left + right).encode()).hexdigest()
        self._facts[h] = (left, right)
        return h
