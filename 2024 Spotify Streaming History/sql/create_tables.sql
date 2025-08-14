-- TRUNCATE TABLE streaming_history_audio;
-- DROP TABLE streaming_history_audio;

CREATE TABLE streaming_history_audio(
	ts timestamp,
	platform VARCHAR(10),
	ms_played int,
	conn_country VARCHAR(3),
	ip_addr VARCHAR(50),
	master_metadata_track_name VARCHAR(255),
	master_metadata_album_artist_name VARCHAR(255),
	master_metadata_album_album_name VARCHAR(255),
	spotify_track_uri VARCHAR(255),
	episode_name VARCHAR(255),
	episode_show_name VARCHAR(255),
	spotify_episode_uri VARCHAR(255),
	audiobook_title VARCHAR(255),
	audiobook_uri VARCHAR(255),
	audiobook_chapter_uri VARCHAR(255),
	audiobook_chapter_title VARCHAR(255),
	reason_start VARCHAR(50),
	reason_end  VARCHAR(50),
	shuffle boolean,
	skipped boolean,
	offline boolean,
	offline_timestamp int,
	incognito_mode boolean
);

COPY streaming_history_audio(
	ts,
	platform,
	ms_played,
	conn_country,
	ip_addr,
	master_metadata_track_name,
	master_metadata_album_artist_name,
	master_metadata_album_album_name,
	spotify_track_uri,
	episode_name,
	episode_show_name,
	spotify_episode_uri,
	audiobook_title,
	audiobook_uri,
	audiobook_chapter_uri,
	audiobook_chapter_title,
	reason_start,
	reason_end,
	shuffle,
	skipped,
	offline,
	offline_timestamp,
	incognito_mode
)
FROM '.\data\source\streaming_history_audio.csv'
DELIMITER ','
CSV HEADER;


-- DROP TABLE streaming_history_tracks;
-- TRUNCATE TABLE streaming_history_tracks;

CREATE TABLE streaming_history_tracks(
	uri VARCHAR(255),
	name VARCHAR(255),
	duration_ms int,
	album_uri VARCHAR(255),
	album_name VARCHAR(255),
	album_release_date VARCHAR(10),
	album_release_date_precision VARCHAR(10)
);

COPY streaming_history_tracks(
	uri,
	name,
	duration_ms,
	album_uri,
	album_name,
	album_release_date,
	album_release_date_precision
)
FROM '.\data\source\streaming_history_tracks.csv'
DELIMITER ','
CSV HEADER;



-- TRUNCATE TABLE streaming_history_tracks_artists;
-- DROP TABLE streaming_history_tracks_artists;

CREATE TABLE streaming_history_tracks_artists(
	track_uri VARCHAR(255),
	artist_uri VARCHAR(255),
	artist_name VARCHAR(255)
);

COPY streaming_history_tracks_artists(
	track_uri,
	artist_uri,
	artist_name
)
FROM '.\data\source\streaming_history_tracks_artists.csv'
DELIMITER ','
CSV HEADER;



-- TRUNCATE TABLE streaming_history_tracks_album_artists;
-- DROP TABLE streaming_history_tracks_album_artists;

CREATE TABLE streaming_history_tracks_album_artists(
	track_uri VARCHAR(255),
	album_artist_uri VARCHAR(255),
	album_artist_name VARCHAR(255)
);

COPY streaming_history_tracks_album_artists(
	track_uri,
	album_artist_uri,
	album_artist_name
)
FROM '.\data\source\streaming_history_tracks_album_artists.csv'
DELIMITER ','
CSV HEADER;

