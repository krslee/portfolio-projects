# Scraping YouTube video data using the YouTube Data API
# Appends information of videos in a playlist to a csv file
# Specifically BTS music videos 

# Note: Only for appending, not writing a file

from googleapiclient.discovery import build
import argparse
import urllib.parse as p
from datetime import datetime

import schedule
import time

import csv
import pandas as pd

# import function used to get video ids
from playlist_scraping import get_video_ids

api_key = 'MY_API_KEY'

youtube = build('youtube', 'v3', developerKey=api_key)

# Return Youtube API response based on video ID
def get_api_response(id):
	request = youtube.videos().list(
			part='id,snippet,statistics',
			id=id
		)

	response = request.execute()

	try:
		return response.get("items")[0]
	except:
		return None

# Return video information from API response
def get_video_info(response):
	# get video information
	video_id = response["id"]
	snippet = response["snippet"]
	statistics = response["statistics"]

	# dictionary storing all info
	result = {}

	# video id
	result["video_id"] = video_id

	# from snippet
	result["channel_name"] = snippet["channelTitle"]
	result["video_title"] = snippet["title"]
	result["time_published"] = snippet["publishedAt"]

	# from statistics
	try:
		result["comment_count"] = statistics["commentCount"]
	except:
		result["comment_count"] = response.get('commentCount', 0)

	try:
		result["like_count"] = statistics["likeCount"]
	except:
		result["like_count"] = response.get('like_count', 0)

	try:
		result["view_count"] = statistics["viewCount"]
	except:
		result["view_count"] = response.get('view_count', 0)

	return result

# Appending data to csv file
def append_data_to_csv(data, time):
	# get song title from video title
	video_title = data["video_title"]

	if "‘" in video_title:
		song_title = video_title.partition("‘")[2].partition("’")[0]
	elif "'" in video_title:
		song_title = video_title.partition("'")[2].partition("'")[0]
	else:
		song_title = video_title

	# reformat publication date
	if "T" in data["time_published"]:
		date_published = data["time_published"].partition("T")[0]

	# store data in array
	appending_data = [
		data["video_id"],
		data["video_title"],
		song_title,
		data["channel_name"],
		date_published,
		data["comment_count"],
		data["like_count"],
		data["view_count"],
		time
	]

	with open('bts_mvs.csv', 'a+', newline='', encoding='UTF8') as f:
	    writer = csv.writer(f)
	    writer.writerow(appending_data)


def update():
	# Parse URL that is passed
	parser = argparse.ArgumentParser(description="YouTube Video Data Extractor")
	parser.add_argument("url", help="ID of the YouTube video/playlist")
	args = parser.parse_args()
	playlist_url = args.url

	# Alternatively, assign URL to variable
	# playlist_url = 'MY_PLAYLIST'
	
	parsed_url = p.urlparse(playlist_url)

	# Get the playlist ID by parsing the query of the URL
	playlist_id = p.parse_qs(parsed_url.query).get("list")

	# If playlist ID successfully found,
	# Create csv file, get data from API response, and append data to file 
	if playlist_id:
		video_ids = get_video_ids(playlist_id[0])

		print(video_ids) # to ensure IDs were properly returned

		for vid in video_ids:
			# get response
			response = get_api_response(vid)

			# get the data
			if response:
				info = get_video_info(response)

				# append data to csv file with current time
				current_time = datetime.now()
				append_data_to_csv(info, current_time)

		# Read csv file into DataFrame and print
		# Making sure insertions were successful  
		df = pd.read_csv(r'C:\Users\Kristine\Desktop\SQL Projects\bts\bts_mvs.csv')
		print(df)
	else:
		raise Exception(f"Wasn't able to parse video URL: {playlist_url}")

# update();

# Schedule to run at midnight daily
schedule.every().day.at("00:00").do(update,'It is 00:00')
# schedule.every().hour.at(":00").do(update)

while True:
    schedule.run_pending()
    time.sleep(60) # wait one minute
