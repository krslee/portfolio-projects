-- LCK 2024 Spring Data Exploration + Analyses

-- Sample Records

-- Tournaments
select * from tournaments 
where tournament like 'LCK 2024 Spring%'
order by tournament, league;

-- Players + Coaches
select * from tournament_players tp
left join tournaments t 
	on tp.overviewpage = t.overviewpage
where tournament = 'LCK 2024 Spring'
order by tournament, league, team, nplayerinteam;

-- Results
select * from tournament_results tr
left join tournaments t 
	on tr.overviewpage = t.overviewpage
where tournament = 'LCK 2024 Spring Playoffs'
order by tournament, league, place;

-- Scoreboard
select * from scoreboard_games sg
left join tournaments t 
	on sg.overviewpage = t.overviewpage
where tournament = 'LCK 2024 Spring'
order by tournament, league, datetime_utc;

-- Scoreboard - Players
select * from scoreboard_players sp 
left join tournaments t 
	on sp.overviewpage = t.overviewpage
where tournament = 'LCK 2024 Spring'
order by tournament, league, datetime_utc
limit 100;

-- Distinct Roles
select distinct role
from tournament_players
order by role;



-- View pulling all LCK tournaments under partnership
create or replace view partnership_tournaments as (
	select *
	from tournaments
	where year >= 2021 -- first year under partnership
		and date <= current_date
);

-- View pulling all partnership teams
create or replace view partnership_teams as (
	select distinct
		players.team,
		case 
			when team in ('Afreeca Freecs') then 'Kwangdong Freecs'
			when team in ('Fredit BRION', 'BRION') then 'OKSavingsBank BRION'
			when team in ('Liiv SANDBOX', 'FearX') then 'BNK FearX'
			when team in ('DWG KIA') then 'Dplus KIA'
			else team
		end as currentname,
		min(year) as year_since
	from tournament_players players
	join partnership_tournaments tournaments 
		on players.overviewpage = tournaments.overviewpage
	group by players.team, currentname
	order by currentname
);


-- Summary Stats (Seasons Info)
-- The following query pulls a summary of season information
with 
partnership_tournaments as (
	select 
		*,
		case
			when tournament like '%Spring%' then 'Spring'
			when tournament like '%Summer%' then 'Summer'
		end as season
	from partnership_tournaments
),

season_info as (
	select 
		league,
		year,
		season,
		min(case when tournament not like '%Playoffs' then datestart end) as split_datestart,
		max(case when tournament not like '%Playoffs' then date end) as split_dateend,
		min(case when tournament like '%Playoffs' then datestart end) as playoffs_datestart,
		max(case when tournament like '%Playoffs' then date end) as playoffs_dateend,
		count(distinct case when role != 'Coach' then player end) as player_count
	from partnership_tournaments tournaments
	join tournament_players players 
		on tournaments.overviewpage = players.overviewpage
	group by league, year, season
),

season_matches as (
	select 
		year,
		season,
		count(distinct case when tournament not like '%Playoffs' then matchid end) as split_total_matches,
		count(distinct case when tournament like '%Playoffs' then matchid end) as playoffs_total_matches,
		count(distinct case when tournament not like '%Playoffs' then gameid end) as split_total_games,
		count(distinct case when tournament like '%Playoffs' then gameid end) as playoffs_total_games,
		count(distinct gameid) as total_games,
		sum(gamelength_number) as gamelength_number
	from scoreboard_games games
	join partnership_tournaments tournaments 
		on games.overviewpage = tournaments.overviewpage
	group by year, season
)

select 
	info.*,
	matches.split_total_matches,
	matches.playoffs_total_matches,
	matches.split_total_games,
	matches.playoffs_total_games,
	matches.total_games,
	matches.gamelength_number
from season_info info
join season_matches matches
	on info.year = matches.year
	and info.season = matches.season
;


-- Team Stats
-- (Current Roster) The following query pulls rosters per team based on latest tournament participated in
with tournament_players as (
	select 
		tournaments.tournament,
		players.team,
		teams.currentname,
		players.role,
		players.nplayerinteam,
		split_part(players.player, ' (', 1) as player,
		rank() over (partition by currentname order by date desc) as tournamentrankdesc
	from tournament_players players 
	join partnership_tournaments tournaments 
		on players.overviewpage = tournaments.overviewpage
	left join partnership_teams teams 
		on players.team = teams.team
)

select 
	tournament as latest_tournament,
	team,
	currentname,
	role,
	nplayerinteam,
	player
from tournament_players
where tournamentrankdesc = 1
order by tournament, currentname, nplayerinteam;

-- (Tournament Results) The following query pulls all tournaments participated per team ranked by recency
with tournaments_per_teams as (
	select distinct
		tournaments.tournament,
		tournaments.year,
		tournaments.date,
		results.team,
		teams.currentname,
		results.place
	from tournament_results results
	join partnership_tournaments tournaments
		on results.overviewpage = tournaments.overviewpage
	left join partnership_teams teams 
		on results.team = teams.team
),

ranked_tournaments_per_teams as (
	select 
		*,
		row_number() over (partition by currentname order by date desc) as tournamentrankdesc
	from tournaments_per_teams
)

select 
	*,
	count(team) over (partition by tournament) as total_teams
from ranked_tournaments_per_teams
order by tournament;



-- Player Stats
-- The following query pulls game stats for all participating players per tournament
with 
tournaments as (
	select *
	from partnership_tournaments
),

player_stats as (
	select 
		overviewpage,
		team,
		player,
		ingamerole,
		count(distinct champion) as total_champions_played,
		count(distinct matchid) as total_matches,
		count(distinct case when playerwin = 'Yes' then matchid end) as matches_won,
		count(distinct case when playerwin = 'No' then matchid end) as matches_lost,
		count(gameid) as total_games,
		count(case when playerwin = 'Yes' then gameid end) as games_won,
		count(case when playerwin = 'No' then gameid end) as games_lost,
		sum(kills) as kills,
		sum(deaths) as deaths,
		sum(assists) as assists,
		sum(gold) as gold_summed,
		sum(cs) as cs_summed,
		sum(damagetochampions) as damage_summed
	from scoreboard_players 
	group by overviewpage, team, player, ingamerole
)

select 
	tournaments.tournament,
	tournaments.league,
	tournaments.region,
	tournaments.year,
	stats.team,
	stats.player,
	stats.ingamerole,
	stats.total_champions_played,
	stats.total_matches,
	stats.matches_won,
	stats.matches_lost,
	stats.total_games,
	stats.games_won,
	stats.games_lost,
	stats.kills,
	stats.deaths,
	stats.assists,
	stats.gold_summed,
	stats.cs_summed,
	stats.damage_summed
from player_stats stats
join tournaments
	on stats.overviewpage = tournaments.overviewpage
order by tournament, team, player
;

-- Champion Stats
-- The following query pulls game stats for all champions banned/picked per tournament
with 
tournaments as (
	select *
	from partnership_tournaments
),

champion_stats as (
	select 
		overviewpage,
		champion,
		ingamerole,
		count(gameid) as pick_count,
		count(distinct player) as player_count,
		count(case when playerwin = 'Yes' then gameid end) as win_count,
		count(case when playerwin = 'No' then gameid end) as loss_count,
		sum(kills) as kills,
		sum(deaths) as deaths,
		sum(assists) as assists,
		sum(gold) as gold_summed,
		sum(cs) as cs_summed,
		sum(damagetochampions) as damage_summed
	from scoreboard_players 
	group by overviewpage, champion, ingamerole
),

champion_bans as (
	select 
		overviewpage, 
		gameid, 
		team1, 
		unnest(string_to_array(team1bans, ',')) as champion
	from scoreboard_games

	union all

	select 
		overviewpage, 
		gameid, 
		team2, 
		unnest(string_to_array(team2bans, ',')) as champion
	from scoreboard_games
),

champion_ban_count as (
	select
		overviewpage,
		champion,
		count(gameid) as ban_count
	from champion_bans
	group by overviewpage, champion
),

champion_bans_stats as (
	select
		coalesce(stats.overviewpage, bans.overviewpage) as overviewpage,
		coalesce(stats.champion, bans.champion) as champion,
		coalesce(stats.ingamerole, 'No Pick') as ingamerole,
		coalesce(bans.ban_count, 0) as ban_count,
		coalesce(stats.pick_count, 0) as pick_count,
		coalesce(stats.player_count, 0) as player_count,
		coalesce(stats.win_count, 0) as win_count,
		coalesce(stats.loss_count, 0) as loss_count,
-- 		rank() over (order by stats.win_count desc) as win_rank,
-- 		rank() over (order by stats.loss_count desc) as loss_rank,
		coalesce(stats.kills, 0) as kills,
		coalesce(stats.deaths, 0) as deaths,
		coalesce(stats.assists, 0) as assists,
		coalesce(stats.gold_summed, 0) as gold_summed,
		coalesce(stats.cs_summed, 0) as cs_summed,
		coalesce(stats.damage_summed, 0) as damage_summed
	from champion_stats stats
	full outer join champion_ban_count bans
		on stats.overviewpage = bans.overviewpage
		and stats.champion = bans.champion
)

select 
	tournaments.tournament,
	tournaments.league,
	tournaments.region,
	tournaments.year,
	bans_stats.champion,
	bans_stats.ingamerole,
	bans_stats.ban_count,
	bans_stats.pick_count,
	bans_stats.player_count,
	bans_stats.win_count,
	bans_stats.loss_count,
	bans_stats.kills,
	bans_stats.deaths,
	bans_stats.assists,
	bans_stats.gold_summed,
	bans_stats.cs_summed,
	bans_stats.damage_summed
from tournaments
join champion_bans_stats bans_stats
	on tournaments.overviewpage = bans_stats.overviewpage
order by tournament, champion
;
