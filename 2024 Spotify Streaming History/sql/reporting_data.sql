/*

create view streaming_history_track_streams_2024 as
	with streaming_history_audio as (
		select 
			*,
			case 
				when ts between '2024-05-01 00:00:00' and '2024-05-17 00:00:00' then ts + interval '9 hour'
				when ts between '2024-01-01 00:00:00' and '2024-03-10 02:00:00' then ts - interval '8 hour'
				when ts between '2024-11-03 02:00:00' and '2025-01-01 00:00:00' then ts - interval '8 hour'
				else ts - interval '7 hour'
			end as ts_adjusted
		from streaming_history_audio
	)
	
	select 
		ts,
		ts_adjusted,
		platform,
		ms_played,
		spotify_track_uri,
		master_metadata_track_name,
		reason_start,
		reason_end,
		shuffle,
		skipped,
		offline,
		offline_timestamp,
		incognito_mode
	from streaming_history_audio audio 
	where date_part('year', ts_adjusted) = 2024
		and spotify_track_uri is not null
		and (ms_played/1000) >= 30
; 

*/

-- Report: 2024 Streaming History Audio (Tracks)
select 
	streams.ts,
	streams.ts_adjusted,
	streams.platform,
	streams.ms_played,
	tracks.duration_ms,
	streams.master_metadata_track_name,
	tracks.uri as track_uri,
	tracks.name as track_name,
	tracks.album_uri,
	tracks.album_name,
	case when tracks.album_release_date_precision = 'day' then tracks.album_release_date::date end as album_release_date,
	case 
		when tracks.album_release_date_precision = 'day' then date_part('year', tracks.album_release_date::date)
		when tracks.album_release_date_precision = 'year' then tracks.album_release_date::int
	end as album_release_year,
-- 	tracks.album_release_date,
-- 	tracks.album_release_date_precision,
	streams.reason_start,
	streams.reason_end,
	streams.shuffle,
	streams.skipped,
	streams.offline,
	streams.offline_timestamp,
	streams.incognito_mode
from streaming_history_track_streams_2024 streams 
left join streaming_history_tracks tracks 
	on streams.spotify_track_uri = tracks.uri 
;

-- Report: 2024 Streaming History Audio (Tracks Artists)
select distinct
	artists.*
from streaming_history_track_streams_2024 streams 
join streaming_history_tracks_artists artists 
	on streams.spotify_track_uri = artists.track_uri
;

-- Report: 2024 Tracks Ranked by Streams
select 
	spotify_track_uri as track_uri,
	count(spotify_track_uri) as stream_count,
	sum(ms_played) as total_ms_played,
	rank() over (order by count(spotify_track_uri) desc, sum(ms_played) desc) as rank
from streaming_history_track_streams_2024
group by spotify_track_uri