The goal of this project is to analyze metrics and trends of my 2024 Spotify track streaming history.

Spotify allows a user to request their [Extended Streaming History](https://support.spotify.com/us/article/understanding-my-data/) from Spotify, "a list of items (e.g. songs, videos, and podcasts) listened to or watched during the lifetime of your account".

I then pulled all unique Track IDs from a subset of my streaming history to retrieve track details via the [Spotify Web API](https://developer.spotify.com/documentation/web-api) and write track, artists, and album artist information to csv files for analysis.

Some basic transformations of the existing streaming data were completed using PostgreSQL such as:
- Filtering for 2024 streams with 30 sec or more of play time (what Spotify officially counts as a stream)
- Joining track and artist data to filtered streaming history to identify final list of unique dimensions

The associated Tableau workbook can be found [HERE](https://public.tableau.com/views/2024SpotifyTrackStreaming/2024Streaming?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link).
