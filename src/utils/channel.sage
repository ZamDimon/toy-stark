import inspect
from hashlib import sha256
from src.math.field import Fp, p


def serialize(entity: object) -> str:
    """
    Serializes an object into a string.
    """

    if isinstance(entity, (list, tuple)):
        return ','.join(map(serialize, entity))

    return entity._serialize_()


class Channel():
    """
    A Channel instance can be used by a prover or a verifier to preserve the semantics of an
    interactive proof system, while under the hood it is in fact non-interactive, and uses Sha256
    to generate randomness when this is required.
    It allows writing string-form data to it, and reading either random integers of random
    FieldElements from it.
    """

    def __init__(self) -> None:
        self._state = '0'
        self._proof = []

    def send(self, msg: str) -> None:
        """
        Emulates sending a message to the other party.
        """

        self._state = sha256((self._state + msg).encode()).hexdigest()
        self._proof.append(f'{inspect.stack()[0][3]}:{msg}')

    def _receive_random_int(self,
        min_value: Integer, 
        max_value: Integer, 
        show_in_proof: bool = True) -> Integer:
        """
        Emulates a random integer sent by the verifier in the range [min, max] (including min and
        max).
        """

        # Note that when the range is close to 2^256 this does not emit a uniform distribution,
        # even if sha256 is uniformly distributed.
        # It is, however, close enough for the toy's purposes.
        num = min_value + (int(self._state, 16) % (max_value - min_value + 1))
        self._state = sha256((self._state).encode()).hexdigest()
        
        if show_in_proof:
            self._proof.append(f'{inspect.stack()[0][3]}:{num}')

        return num

    def get_random_scalar(self) -> Fp:
        """
        Emulates a random field element sent by the verifier.
        """

        num = self._receive_random_int(0, p-1, show_in_proof=False)
        self._proof.append(f'{inspect.stack()[0][3]}:{num}')
        return Fp(num)

