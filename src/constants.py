"""
Constants for QuiVer.
"""

__all__ = [
    "METS",
    "OCRD",
    "QUIVER_MAIN",
    "RESULTS",
    "WORKFLOW_DIR"
]

from ocrd_models.constants import NAMESPACES
METS = "{" + NAMESPACES['mets'] + "}"
OCRD = "{" + NAMESPACES['ocrd'] + "}"

QUIVER_MAIN = 'https://github.com/OCR-D/quiver-back-end/blob/main'
RESULTS = '/../../results/'
WORKFLOW_DIR = '/app/workflows/ocrd_workflows/'
