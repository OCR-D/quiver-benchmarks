"""
API server for querying MongoDB.
To be used by the front end.
"""

from fastapi import FastAPI
from pymongo import MongoClient
from datetime import datetime
from bson import json_util
import json
import re

CLIENT = MongoClient('quiver-mongodb-1', 27017)
DB = CLIENT.results
COLL = DB.quiver

app = FastAPI()

@app.get('/latest')
def get_latest_results():
    """
    Returns the results of the latest runs
    """
    # get all the dates
    timestamps = COLL.distinct('metadata.timestamp')
    timestamps_dates = []
    for stamp in timestamps:
        timestamps_dates.append(datetime.strptime(stamp,'%Y-%m-%d'))

    # find out which is the latest one
    current_date = datetime.today()
    closest_date = min(timestamps_dates, key=lambda d: abs(d - current_date))
    closest_string = datetime.strftime(closest_date,'%Y-%m-%d')    

    # query for the most recent date
    results = COLL.find({'metadata.timestamp': closest_string})

    # return result
    return json.loads(json_util.dumps(results))

@app.get('/all')
def get_all_results():
    """
    Get results of all runs.
    """

    cursor = COLL.find()

    # iterate code goes here
    return json.loads(json_util.dumps(cursor))


@app.get('/results/{gt_name}')
def get_results_for_gt(gt_name: str):
    """
    Get all results for a specific set of Ground Truth.
    """
    regex = re.compile(gt_name)
    cursor = COLL.find({'metadata.gt_workspace.@id': regex})

    return json.loads(json_util.dumps(cursor))

