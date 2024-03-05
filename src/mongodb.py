"""
A module that deals with all interactions with MongoDB.
"""

import requests


def post_to_mongodb(result: dict) -> int:
    """
    Posting the results of OCR runs + evaluation to MongoDB
    """
    # Replace the uri string with your MongoDB deployment's connection string.

    url = 'http://quiver-api-1:8084/api/runs'
    res = requests.post(url, json=result, timeout=10)
    return res.status_code
