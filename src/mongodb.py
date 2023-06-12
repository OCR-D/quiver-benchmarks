from pymongo import MongoClient

def post_to_mongodb(json_file: dict):

    # Replace the uri string with your MongoDB deployment's connection string.

    client = MongoClient('quiver-mongodb-1', 27017)

    # database and collection code goes here

    db = client.results
    coll = db.quiver
    result = coll.insert_one(json_file)

    # display the results of your operation

    print(result.inserted_id)

    # Close the connection to MongoDB when you're done.

    client.close()
