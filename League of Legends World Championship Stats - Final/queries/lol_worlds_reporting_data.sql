/* View/query results saved as static files for usage in BI reporting */


/* This view produces individual Worlds tournament details */ 
create or replace view vw_tournaments as (
	select 
		case 
			when tournament like 'Worlds 20%' then left(tournament, 11)
			else tournament
		end as tournament_group,
		case 
			when tournament like '%Play-In%' then 'Play-In'
			when tournament like '%Qualif%' then 'Qualifier Series'
			else 'Main Event'
		end as tournament_stage,
		*
	from tournaments 
);


/* This query produces roster details per Worlds */ 
select t.tournament_group, *
from tournament_rosters tr 
join vw_tournaments t 
	on tr.overviewpage = t.overviewpage
;

/* This query produces team member (player and coach) details per Worlds */ 
select t.tournament, t.tournament_group, tp.* 
from tournament_players tp
left join vw_tournaments t 
	on tp.overviewpage = t.overviewpage
order by tournament, team, nplayerinteam;


/* This view produces Worlds tournament results */ 
create or replace view vw_tournament_results as (
	select 
		t.overviewpage,
		t.date,
		coalesce(tr.place, 'N/A') as place,
		coalesce(tr.place_number, -1) as place_number,
		tr.team,
		tr.date_precision,
		tr.prize,
		tr.prize_usd,
		t.tournament,
		t.tournament_group,
		t.datestart,
		t.date as dateend
	from tournament_results tr 
	join vw_tournaments t
		on tr.overviewpage = t.overviewpage
	order by tournament, league, place
)
;	

/* This view produces Worlds match results by pulling final game results per match from scoreboard_games */ 
create or replace view vw_match_results as (
	with 

	match_games_ranked as (
		select *, row_number() over (partition by matchid order by ngameinmatch desc) as gamenumberdesc 
		from scoreboard_games
	),

	match_final_game as (
		select *
		from match_games_ranked
		where gamenumberdesc = 1
	),
	
	match_scores as (
		select 
			overviewpage,
			matchid,
			datetime_utc,
			winteam as team,
			lossteam as opposingteam,
			'Win' as result,
			case 
				when winner = 1 then team1score
				when winner = 2 then team2score
			end as gameswon,
			case 
				when winner = 2 then team1score
				when winner = 1 then team2score
			end as gameslost
		from match_final_game

		union all

		select 
			overviewpage,
			matchid,
			datetime_utc,
			lossteam as team,
			winteam as opposingteam,
			'Loss' as result,
			case 
				when winner = 2 then team1score
				when winner = 1 then team2score
			end as gameswon,
			case 
				when winner = 1 then team1score
				when winner = 2 then team2score
			end as gameslost
		from match_final_game
	)

	select 
		match.overviewpage,
		t.tournament,
		t.tournament_group,
		t.league,
		t.region,
		t.year,
		match.matchid,
		match.datetime_utc,
		split_part(match.matchid, '_', 2) as matchround,
		split_part(match.matchid, '_', 3) as matchnumber,
		match.team,
		match.opposingteam,
		coalesce(match.result, 'N/A') as result,
		match.gameswon,
		match.gameslost
	from vw_tournaments t 
	join match_scores match
		on t.overviewpage = match.overviewpage
	order by t.tournament, match.matchid
)
;

-- Bans + Pick Stats Combined
create or replace view vw_ban_pick_stats as (
	with 

	game_summary as (
		select 
			matchid,
			split_part(matchid, '_', 2) as matchround,
			split_part(matchid, '_', 3) as matchnumber,
			gameid,
			ngameinmatch as gamenumber,
			gamename,
			gamelength_number,
			team1,
			team2
		from scoreboard_games
	),

	champion_stats as (
		select 
			overviewpage,
			matchid,
			gameid,
			team,
			player,
			champion,
			side,
			ingamerole,
			case when playerwin = 'Yes' then 1 else 0 end as iswin,
			case when playerwin = 'No' then 1 else 0 end as isloss,
			kills,
			deaths,
			assists,
			gold,
			cs,
			damagetochampions
		from scoreboard_players 
	),

	champion_bans as (
		select 
			overviewpage, 
			matchid,
			gameid, 
			team1 as team, 
			unnest(string_to_array(team1bans, ',')) as champion
		from scoreboard_games

		union all

		select 
			overviewpage, 
			matchid,
			gameid, 
			team2 as team, 
			unnest(string_to_array(team2bans, ',')) as champion
		from scoreboard_games
	),

	ban_pick_stats as (
		select 
			overviewpage,
			matchid,
			gameid,
			'Pick' as action,
			team,
			player,
			champion,
			side,
			ingamerole,
			iswin,
			isloss,
			kills,
			deaths,
			assists,
			gold,
			cs,
			damagetochampions
		from champion_stats

		union 

		select 
			overviewpage,
			matchid,
			gameid,
			'Ban' as action,
			team,
			null as player,
			champion,
			null as side,
			null as ingamerole,
			null as iswin,
			null as isloss,
			null as kills,
			null as deaths,
			null as assists,
			null as gold,
			null as cs,
			null as damagetochampions
		from champion_bans
	)

	select 
		t.overviewpage,
		t.tournament,
		t.tournament_group,
		t.league,
		t.region,
		t.year,
		stats.matchid,
		game_summary.matchround,
		game_summary.matchnumber,
		stats.gameid,
		game_summary.gamenumber,
		game_summary.gamename,
		game_summary.gamelength_number,
		stats.team,
		case when stats.team = game_summary.team1 then team2 else team1 end as opposingteam,
		stats.player,
		stats.champion,
		stats.side,
		stats.action,
		stats.ingamerole,
		stats.iswin,
		stats.isloss,
		stats.kills,
		stats.deaths,
		stats.assists,
		stats.gold,
		stats.cs,
		stats.damagetochampions
	from tournaments_grouped t
	left join ban_pick_stats stats 
		on t.overviewpage = stats.overviewpage 
	join game_summary
		on stats.gameid = game_summary.gameid
	order by tournament, matchid, gameid, action, team, player
)
;