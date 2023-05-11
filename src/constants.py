"""
Constants for QuiVer.
"""

__all__ = [
    "METS",
    "OCRD",
    "QUIVER_MAIN",
    "RESULTS"
]

from ocrd_models.constants import NAMESPACES
METS = "{" + NAMESPACES['mets'] + "}"
OCRD = "{" + NAMESPACES['ocrd'] + "}"

QUIVER_MAIN = 'https://github.com/OCR-D/quiver-back-end/blob/main'
RESULTS = '/../../results/'
