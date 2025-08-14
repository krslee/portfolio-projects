The goal of this project is to analyze metrics and trends of my 2024 Spotify track streaming history.

I requested my Extended Streaming History from Spotify, "a list of items (e.g. songs, videos, and podcasts) listened to or watched during the lifetime of your account".

https://support.spotify.com/us/article/understanding-my-data/

I then pulled all unique Track IDs from a subset of my streaming history to retrieve track details via Spotify's web API and write track, artists, and album artist information to csv files for analysis.

https://developer.spotify.com/documentation/web-api

I used PostgreSQL to do some basic transformations of my existing streaming data such as:
- Filtering for 2024 streams with 30 sec or more of play time (what Spotify officially counts as a stream)
- Joining track and artist data to filtered streaming history to identify final list of unique dimensions

Related Tableau workbook can be found HERE.