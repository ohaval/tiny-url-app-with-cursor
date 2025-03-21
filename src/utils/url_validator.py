"""URL validation utilities."""

from typing import Tuple

import validators

MAX_URL_LENGTH = 2048


def validate_url(url: str) -> Tuple[bool, str]:
    """Validate a URL string.

    Args:
        url: The URL to validate

    Returns:
        Tuple of (is_valid, error_message)
    """
    if not url:
        return False, "URL cannot be empty"

    if len(url) > MAX_URL_LENGTH:
        msg = f"URL length exceeds maximum of {MAX_URL_LENGTH} characters"
        return False, msg

    if not url.startswith(("http://", "https://")):
        return False, "URL must start with http:// or https://"

    if not validators.url(url):
        return False, "Invalid URL format"

    return True, ""
