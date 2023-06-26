"""
A module that deals with all interactions with MongoDB.
"""

from pymongo import MongoClient

def post_to_mongodb(result: dict):
    """
    Posting the results of OCR runs + evaluation to MongoDB
    """
    # Replace the uri string with your MongoDB deployment's connection string.

    client = MongoClient('quiver-mongodb-1', 27017)

    # database and collection code goes here

    db = client.results
    coll = db.quiver
    result = coll.insert_one(result)

    # display the results of your operation

    print(result.inserted_id)

    # Close the connection to MongoDB when you're done.

    client.close()

def query():
    pass