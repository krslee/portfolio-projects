/* 

2024 SPOTIFY STREAMING HISTORY 

Four tables created:
- streaming_history_audio
- streaming_history_tracks
- streaming_history_tracks_album_artists
- streaming_history_tracks_artists

*/


select *
from streaming_history_audio
where spotify_track_uri is not null
;

-- Counts
select 
	count(*) as record_count, 
	count(distinct spotify_track_uri) as track_count
from streaming_history_audio
;

-- Creating a view for 2024 Streams
create view streaming_history_track_streams_2024 as
	with streaming_history_audio as (
		select 
			*,
            -- adjustments to account for days spent in South Korea and daylight savings
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

select *
from streaming_history_track_streams_2024
order by ts
;

select 
	count(*) as record_count, 
	count(distinct spotify_track_uri) as track_count
from streaming_history_track_streams_2024
;

/* STREAMING HISTORY - 2024 TRENDS */

-- 2024 summary stats such as stream counts, time streamed, stat averages, unique tracks/artists/albums streamed
with 

stream_stats as (
	select 
		min(ts_adjusted) as first_stream_ts_adjusted,
		max(ts_adjusted) as last_stream_ts_adjusted,
		count(ts_adjusted) as stream_count,
		count(distinct date(ts_adjusted)) as days_streamed_count,
		round(count(ts_adjusted) / 366) as avg_daily_stream_count, -- leap year
		sum(ms_played) / 1000 / 60 as total_min_played,
		round((sum(ms_played) / 1000 / 60) / 366) as avg_daily_min_played,
		sum(ms_played) / 1000 / 60 / 60 as total_hr_played,
		round(((sum(ms_played)::numeric / 1000 / 60 / 60) / 366), 2) as avg_daily_hr_played
	from streaming_history_track_streams_2024 
),

unique_counts as (
	select 
		min(ts_adjusted) as first_stream_ts_adjusted,
		count(distinct streams.spotify_track_uri) as unique_track_count,
		count(distinct tracks.album_uri) as unique_album_count,
		count(distinct artists.artist_uri) as unique_artist_count
	from streaming_history_track_streams_2024 streams
	join streaming_history_tracks tracks 
		on streams.spotify_track_uri = tracks.uri
	join streaming_history_tracks_artists artists 
		on streams.spotify_track_uri = artists.track_uri
)

select 
	stream_stats.*,
	unique_counts.unique_track_count,
	unique_counts.unique_album_count,
	unique_counts.unique_artist_count
from stream_stats
join unique_counts
	on stream_stats.first_stream_ts_adjusted = unique_counts.first_stream_ts_adjusted
;

-- 2024 Days Not Streamed

with

all_dates as (
	select date(d) as date
	from generate_series('2024-01-01 00:00'::timestamp, '2024-12-31 00:00'::timestamp, '1 day'::interval) d
),

stream_dates as (
	select distinct date(ts_adjusted) as date 
	from streaming_history_track_streams_2024
)

select 
	all_dates.date,
	to_char(all_dates.date, 'Day') as day_name
from all_dates  
left join stream_dates
	on all_dates.date = stream_dates.date
where stream_dates.date is null
;



-- 2024 Streams by Month
-- Most Streams: May (1299 streams)
-- Most Minutes Played: May (3736 minutes)
with

stream_stats as (
	select 
		date_part('month', streams.ts_adjusted) as stream_month,
		to_char(streams.ts_adjusted, 'Month') as stream_month_name,
		count(streams.ts_adjusted) as stream_count,
		round(count(streams.ts_adjusted) / max(date_part('day', (date_trunc('month', streams.ts_adjusted) + interval '1 month - 1 day')))) as avg_daily_stream_count,
		sum(streams.ms_played) / 1000 / 60 as total_min_played,
		round((sum(streams.ms_played) / 1000 / 60) / 
  			max(date_part('day', (date_trunc('month', streams.ts_adjusted) + interval '1 month - 1 day')))) as avg_daily_min_played,
		sum(streams.ms_played) / 1000 / 60 / 60 as total_hr_played,
		round(((sum(streams.ms_played) / 1000 / 60 / 60) / 
  			max(date_part('day', (date_trunc('month', streams.ts_adjusted) + interval '1 month - 1 day'))))::numeric, 2) as avg_daily_hr_played
	from streaming_history_track_streams_2024 streams
	group by 
		stream_month_name,
		stream_month
),

unique_counts as (
	select 
		date_part('month', streams.ts_adjusted) as stream_month,
		to_char(streams.ts_adjusted, 'Month') as stream_month_name,
		count(distinct streams.spotify_track_uri) as unique_track_count,
		count(distinct tracks.album_uri) as unique_album_count,
		count(distinct artists.artist_uri) as unique_artist_count
	from streaming_history_track_streams_2024 streams
	join streaming_history_tracks tracks 
		on streams.spotify_track_uri = tracks.uri
	join streaming_history_tracks_artists artists 
		on streams.spotify_track_uri = artists.track_uri
	group by 
		stream_month_name,
		stream_month
)

select 
	stream_stats.*,
	unique_counts.unique_track_count,
	unique_counts.unique_album_count,
	unique_counts.unique_artist_count
from stream_stats
join unique_counts
	on stream_stats.stream_month = unique_counts.stream_month
order by stream_stats.stream_month
;


-- 2024 Streams by Days of the Week
-- Most Streams: Saturday (1967 streams)
-- Most Minutes Played: Saturday (5797 minutes)
select 
	date_part('isodow', streams.ts_adjusted) as stream_day_number,
	to_char(streams.ts_adjusted, 'Day') as stream_day_name,
	count(streams.ts_adjusted) as stream_count,
	sum(streams.ms_played) / 1000 / 60 as total_min_played,
	sum(streams.ms_played) / 1000 / 60 / 60 as total_hr_played
from streaming_history_track_streams_2024 streams
group by 
	stream_day_number,
	stream_day_name
order by stream_count
;


/* 2024 STREAMING HISTORY - TOP 10s */

-- 2024 Top 10 Tracks by Streams
select 
	tracks.uri,
	tracks.name,
	count(streams.spotify_track_uri) as stream_count
from streaming_history_track_streams_2024 streams
join streaming_history_tracks tracks
	on streams.spotify_track_uri = tracks.uri
group by 
	tracks.uri,
	tracks.name
order by stream_count desc 
limit 10;

-- 2024 Top 10 - Percentage of Total Streams
with

tracks as (
	select 
		spotify_track_uri,
		count(spotify_track_uri) as stream_count,
		sum(ms_played) / 1000 / 60 as total_min_played,
		rank() over (order by count(spotify_track_uri) desc) as rank
	from streaming_history_track_streams_2024
	group by spotify_track_uri
)

select 
	sum(stream_count) as total_stream_count,
	sum(case when rank <= 10 then stream_count end) as top_10_stream_count,
	round(sum(case when rank <= 10 then stream_count end) / sum(stream_count), 4) as top_10_stream_pct
from tracks 
;

-- 2024 Top 10 Albums by Streams
select 
	tracks.album_uri,
	tracks.album_name,
	count(streams.spotify_track_uri) as stream_count
from streaming_history_track_streams_2024 streams
join streaming_history_tracks tracks
	on streams.spotify_track_uri = tracks.uri
group by 
	tracks.album_uri,
	tracks.album_name
order by stream_count desc 
limit 10;

-- 2024 Top 10 Artists by Streams
select 
	artists.artist_uri,
	artists.artist_name,
	count(streams.spotify_track_uri) as stream_count,
	count(distinct streams.spotify_track_uri) as track_count
from streaming_history_track_streams_2024 streams
join streaming_history_tracks_artists artists 
	on streams.spotify_track_uri = artists.track_uri
group by 
	artists.artist_uri,
	artists.artist_name
order by stream_count desc 
limit 10;