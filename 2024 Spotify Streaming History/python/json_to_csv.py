# Python script to convert JSON file to CSV

import json
import os
import csv

# Opening JSON files and loading the data

# open a file for writing
data_file = open('./data/source/streaming_history_audio.csv', 'w', encoding='utf-8', newline='')

# create the csv writer object
csv_writer = csv.writer(data_file)

count = 0

path = './Streaming_History_Audio/'

for file_name in os.listdir(path):
    if file_name.endswith(".json"):
        # Prints only text file present in My Folder
        print(file_name)

        json_file = open(path + file_name, encoding='utf-8')

        jsondata = json.load(json_file)

        # jsondata = data['data']
        
        for data in jsondata:
            if count == 0:

                # Writing headers of CSV file
                header = data.keys()
                print(header)
                csv_writer.writerow(header)
                count += 1
            
            csv_writer.writerow(data.values())

data_file.close()
