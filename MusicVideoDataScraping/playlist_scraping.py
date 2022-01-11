# Functions to IDs of videos in a playlist
# Functions imported in yt_video_scraping.py to use

from googleapiclient.discovery import build
import argparse
import urllib.parse as p

api_key = 'MY_API_KEY'

youtube = build('youtube', 'v3', developerKey=api_key)

# Return Youtube API response based on playlist ID
def get_api_response(id, nextPageToken=None):
	if nextPageToken: # second page and onward
		request = youtube.playlistItems().list(
				part='snippet',
				playlistId=id,
				maxResults=50,
				pageToken=nextPageToken
			)
	else: # first page
		request = youtube.playlistItems().list(
				part='snippet',
				playlistId=id,
				maxResults=50
			)

	response = request.execute()

	return response

# Return video information from API response
def get_video_ids(playlist_id):
	# get response
	response = get_api_response(playlist_id)
	items = response.get("items")
	nextPageToken = response.get("nextPageToken")

	# get id of each video in list and add to results
	result = []

	for item in items:
		snippet = item["snippet"]

		# get video id
		video_id = snippet["resourceId"]["videoId"]
		result.append(video_id)

	# continue this for following pages of playlist items
	while nextPageToken:
		response = get_api_response(playlist_id, nextPageToken)
		items = response.get("items")
		nextPageToken = response.get("nextPageToken")

		for item in items:
			snippet = item["snippet"]

			# get video id
			video_id = snippet["resourceId"]["videoId"]
			result.append(video_id)

	return result
