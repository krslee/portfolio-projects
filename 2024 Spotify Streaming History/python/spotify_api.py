import requests
import json
import os
import csv

import credentials

url = 'https://api.spotify.com/v1/'

access_token = credentials.access_token

# this function to extracts track details via API
# accepts an array of track IDs
def get_tracks_data(track_ids):
    count = 0

    tracks_data = []

    while count < len(track_ids):
        start_index = 0 + count
        end_index = 50 + count

        track_ids_str = ','.join(track_ids[start_index:end_index])

        response = requests.get(url + 'tracks?ids=' + track_ids_str, headers={'Authorization': 'Bearer ' + access_token})
        data = response.json()['tracks']

        tracks_data += data

        count += 50
        print(count)

    return tracks_data

# this function unnests relevant track related details from the API response and stores in an array
# accepts an array with raw track data
def get_track_details(data):
    track_details = []

    for track in data:
        album_artists = track['album']['artists']
        track_artists = track['artists']

        response_unnested = {
            'uri': track['uri'],
            'name': track['name'],
            'duration_ms': track['duration_ms'],
            'artist_1_uri': track_artists[0]['uri'],
            'artist_1_name': track_artists[0]['name'],
            'artist_2_uri': track_artists[1]['uri'] if len(track_artists) > 1 else None,
            'artist_2_name': track_artists[1]['name']  if len(track_artists) > 1 else None,
            'artist_3_uri': track_artists[2]['uri'] if len(track_artists) > 2 else None,
            'artist_3_name': track_artists[2]['name']  if len(track_artists) > 2 else None,
            'album_uri': track['album']['uri'],
            'album_name': track['album']['name'],
            'album_artist_1_uri': album_artists[0]['uri'],
            'album_artist_1_name': album_artists[0]['name'],
            'album_artist_2_uri': album_artists[1]['uri'] if len(album_artists) > 1 else None,
            'album_artist_2_name': album_artists[1]['name']  if len(album_artists) > 1 else None,
            'album_artist_3_uri': album_artists[2]['uri'] if len(album_artists) > 2 else None,
            'album_artist_3_name': album_artists[2]['name']  if len(album_artists) > 2 else None
        }

        track_details.append(response_unnested)

    return track_details


# this function unnests relevant track and album details from the API response and stores in an array
# accepts an array with raw track data
def get_tracks(data):
    tracks = []

    for track in data:
        response_unnested = {
            'uri': track['uri'],
            'name': track['name'],
            'duration_ms': track['duration_ms'],
            'album_uri': track['album']['uri'],
            'album_name': track['album']['name'],
            'album_release_date': track['album']['release_date'],
            'album_release_date_precision': track['album']['release_date_precision']
        }

        tracks.append(response_unnested)

    return tracks

# this function unnests relevant artists details from the API response and stores in an array
# accepts an array with raw track data
def get_track_artists(data):
    track_artists = []

    for track in data:
        for artist in track['artists']:
            response_unnested = {
                'track_uri': track['uri'],
                'artist_uri': artist['uri'],
                'artist_name': artist['name']
            }

            track_artists.append(response_unnested)

    return track_artists


# this function unnests relevant album artists details from the API response and stores in an array
# accepts an array with raw track data
def get_track_album_artists(data):
    track_album_artists = []

    for track in data:
        for artist in track['album']['artists']:
            response_unnested = {
                'track_uri': track['uri'],
                'artist_uri': artist['uri'],
                'artist_name': artist['name']
            }

            track_album_artists.append(response_unnested)

    return track_album_artists

# this function writes records of an array to a csv file
# accepts a string as the file name, an array of data, and the function to retrieve the data
def write_to_csv(file_name, data, get_function):
    # Opening JSON files and loading the data

    # open a file for writing
    data_file = open(file_name, 'w', encoding='utf-8', newline='')

    # create the csv writer object
    csv_writer = csv.writer(data_file)

    items = get_function(data)

    count = 0

    for item in items:
        if count == 0:

            # Writing headers of CSV file
            header = item.keys()
            print(header)
            csv_writer.writerow(header)

        count += 1

        csv_writer.writerow(item.values())

    print(f'{count} records written')


# local path with streaming history export
path = './Streaming_History_Audio/'

# array to store track IDs
track_ids = []

# iterate through export to add track IDs to defined array
for file_name in os.listdir(path):
    if file_name.endswith(".json"):
        # Prints only text file present in My Folder
        print(file_name)

        json_file = open(path + file_name, encoding='utf-8')

        jsondata = json.load(json_file)

        # print(jsondata)
        
        for data in jsondata:
            track_uri = data['spotify_track_uri']
            track_stream_ts = data['ts']
            track_stream_year = track_stream_ts[0:4]

            if track_uri != None: # and track_stream_year == year:
                track_id = track_uri.split(':')[2]

                if track_id not in track_ids:
                    track_ids.append(track_id)


api_response = get_tracks_data(track_ids)

# write_to_csv('Streaming_History_Track_Details.csv', api_response, get_track_details)
# write_to_csv('./data/source/streaming_history_tracks.csv', api_response, get_tracks)
# write_to_csv('./data/source/streaming_history_tracks_artists.csv', api_response, get_track_artists)
# write_to_csv('./data/source/streaming_history_tracks_album_artists.csv', api_response, get_track_album_artists)
