import os
import uuid
import socket
import datetime

from flask import Flask, request, jsonify

app = Flask(__name__)

# for demo purposes only to see different requests handled by instances of the application
count = 0

@app.route('/')
def index():
    global count
    count += 1
    return jsonify(
        project=os.environ.get('PROJECT'),
        version=os.environ.get('VERSION'),
        hostname=socket.gethostname(),
        counter=count
    )

@app.route('/storage')
def storage():
    # Declare the file atrget and how much data to read/write
    folderPath = os.environ.get('DATA_PATH')
    if folderPath is None:    
        return "Storage tests not enabled..."
    if os.path.isdir(folderPath) is False:
        return "Folder {} does not exists".format(folderPath)

    fileName = "{}.txt".format(str(uuid.uuid4()))
    filePath = "{}/{}".format(folderPath, fileName)
    totalBytes = 1024 * 1024 * 10

    # Test the write speed and compute the throughput
    f = open(filePath, "w")
    startedAt = datetime.datetime.now()
    for x in range(totalBytes):
        f.write("X")    
    f.close()
    finishedAt = datetime.datetime.now()
    writeSpeed = round((totalBytes / 1024 / 1024) / (finishedAt - startedAt).total_seconds(), 1)
    
    # Test the read speed and compute the throughput
    f = open(filePath, "r")
    startedAt = datetime.datetime.now()
    readTotal = len(f.read())
    f.close()
    finishedAt = datetime.datetime.now()
    readSpeed = round((readTotal / 1024 / 1024) / (finishedAt - startedAt).total_seconds(), 1)

    # Delete the temp file
    os.remove(filePath)

    # Return the result summarry
    return jsonify(
        filePath=os.environ.get('DATA_PATH'),
        fileName=fileName,
        writeMbps=writeSpeed,
        readMbps=readSpeed
    )


if __name__ == '__main__':
    app.run(host='0.0.0.0')