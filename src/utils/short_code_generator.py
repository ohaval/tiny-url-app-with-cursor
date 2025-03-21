"""Short code generator for URL shortening service."""

import secrets
import string

CODE_LENGTH = 8
CHARS = string.ascii_letters + string.digits


def generate_short_code() -> str:
    """Generate a cryptographically secure 8-character code."""
    return "".join(secrets.choice(CHARS) for _ in range(CODE_LENGTH))
