with 
tournament_results as (
	select 
		tournaments.tournament,
		tournaments.league,
		tournaments.region,
		tournaments.year,
		results.*
	from tournament_results results 
	left join partnership_tournaments tournaments
		on results.overviewpage = tournaments.overviewpage
	where tournaments.tournament like '%Playoffs'
)

select * from tournament_results


-- Playoffs Results
-- The following query pulls rankings and stats for all participating teams per playoffs
with 
tournament_results as (
	select 
		tournaments.tournament,
		tournaments.league,
		tournaments.region,
		tournaments.year,
		results.*
	from partnership_tournaments tournaments 
	left join tournament_results results 
		on tournaments.overviewpage = results.overviewpage
	where tournaments.tournament like '%Playoffs'
),

scoreboard_games_ordered as (
	select *, row_number() over (partition by matchid order by ngameinmatch desc) as order_desc 
	from scoreboard_games
),

final_scores_per_match as (
	select 
		overviewpage,
		matchid,
		datetime_utc,
		team1,
		team2,
		winteam,
		lossteam,
		ngameinmatch,
		team1score,
		team2score,
		winner
	from scoreboard_games_ordered
	where order_desc = 1
),

matches_won as (
	select
		overviewpage,
		matchid,
		datetime_utc,
 		winteam as team,
 		lossteam as opposing_team,
		1 as match_won,
		case
			when winner = 1 then team1score
			when winner = 2 then team2score
		end as games_won,
		case
			when winner = 1 then team2score 
			when winner = 2 then team1score
		end as games_lost
	from final_scores_per_match
),

matches_lost as (
	select
		overviewpage,
		matchid,
		datetime_utc,
 		lossteam as team,
 		winteam as opposing_team,
		0 as match_won,
		case
			when winner = 1 then team2score 
			when winner = 2 then team1score
		end as games_won,
		case
			when winner = 1 then team1score  
			when winner = 2 then team2score
		end as games_lost
	from final_scores_per_match
),

all_matches_per_team as (
	select *, row_number() over (partition by overviewpage, team order by datetime_utc desc) as match_order_desc 
	from (
		select *
		from matches_won

		union all

		select *
		from matches_lost
	) matches
)

select 
	results.*,
	teams.currentname,
	matches.matchid as final_matchid,
	matches.datetime_utc,
	split_part(matches.matchid, '_', 2) as final_round,
	matches.opposing_team,
	matches.match_won,
	matches.games_won as final_match_games_won,
	matches.games_lost as final_match_games_lost
from tournament_results results
join all_matches_per_team matches
	on results.overviewpage = matches.overviewpage
	and results.team = matches.team
left join partnership_teams teams 
	on results.team = teams.team
where match_order_desc = 1
;