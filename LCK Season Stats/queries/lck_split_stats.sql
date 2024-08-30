-- Final Scores Per Team
-- The following query pulls final rankings and stats for all participating teams per split
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
	where tournaments.tournament not like '%Playoffs'
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

team_wins as (
	select 
		overviewpage,
		winteam as team,
		count(matchid) as matches_won,
		sum(case
			when winner = 1 then team1score
			when winner = 2 then team2score
		end) as games_won,
		sum(case
			when winner = 1 then team2score 
			when winner = 2 then team1score
		end) as games_lost
	from final_scores_per_match
	group by 
		overviewpage,
		team
),

team_losses as (
	select 
		overviewpage,
		lossteam as team,
		count(matchid) as matches_lost,
		sum(case
			when winner = 1 then team2score 
			when winner = 2 then team1score
		end) as games_won,
		sum(case
			when winner = 1 then team1score  
			when winner = 2 then team2score
		end) as games_lost
	from final_scores_per_match
	group by 
		overviewpage,
		team
)

select 
	results.tournament,
	results.league,
	results.year,
	results.place,
	results.team,
	teams.currentname,
	coalesce(wins.matches_won, 0) as matches_won,
	coalesce(losses.matches_lost, 0) as matches_lost,
	coalesce(wins.games_won, 0) + coalesce(losses.games_won, 0) as games_won,
	coalesce(wins.games_lost, 0) + coalesce(losses.games_lost, 0) as games_lost
from tournament_results results 
left join partnership_teams teams 
	on results.team = teams.team
left join team_wins wins 
	on results.overviewpage = wins.overviewpage
	and results.team = wins.team
left join team_losses losses 
	on results.overviewpage = losses.overviewpage
	and results.team = losses.team 
;


-- Weekly Scores and Ranks Per Team
-- The following query pulls weekly rankings and stats for all participating teams per split
-- Rankings are assigned based on the following counts in order: Most Matches Won, Least Matches Lost, Most Games Won, Least Games Lost
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
	where tournaments.tournament not like '%Playoffs'
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

match_wins as (
	select 
		overviewpage,
		matchid,
		split_part(matchid, '_', 2) as match_week,
		winteam as team,
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

match_wins_agg as (
	select
		overviewpage,
		match_week,
		team,
		count(matchid) as matches_won,
		sum(games_won) as games_won,
		sum(games_lost) as games_lost
	from match_wins
	group by 
		overviewpage,
		match_week,
		team
),

match_losses as (
	select 
		overviewpage,
		matchid,
		split_part(matchid, '_', 2) as match_week,
		lossteam as team,
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

match_losses_agg as (
	select
		overviewpage,
		match_week,
		team,
		count(matchid) as matches_lost,
		sum(games_won) as games_won,
		sum(games_lost) as games_lost
	from match_losses
	group by 
		overviewpage,
		match_week,
		team
),

match_weeks as (
	select 
		overviewpage,
		split_part(matchid, '_', 2) as match_week,
		count(matchid) as total_matches
	from final_scores_per_match
	group by overviewpage, match_week
),

weekly_results as (
	select 
		results.tournament,
		weeks.match_week,
		case
			when weeks.match_week = 'Tiebreakers' then 100 -- arbitrary number to place tiebreakers last
			else split_part(weeks.match_week, ' ', 2)::int 
		end as match_week_number,
		weeks.total_matches,
		results.team,
		coalesce(wins.matches_won, 0) as matches_won,
		coalesce(losses.matches_lost, 0) as matches_lost,
		coalesce(sum(wins.games_won), 0) + coalesce(sum(losses.games_won), 0) as games_wons,
		coalesce(sum(wins.games_lost), 0) + coalesce(sum(losses.games_lost), 0) as games_lost
	from tournament_results results 
	left join match_weeks weeks 
		on results.overviewpage = weeks.overviewpage
	left join match_wins_agg wins
		on results.overviewpage = wins.overviewpage
		and results.team = wins.team
		and weeks.match_week = wins.match_week
	left join match_losses_agg losses
		on results.overviewpage = losses.overviewpage
		and results.team = losses.team 
		and weeks.match_week = losses.match_week
	group by
		results.tournament,
		weeks.match_week,
		match_week_number,
		weeks.total_matches,
		results.team,
		matches_won,
		matches_lost
),

weekly_results_cumulative as (
	select 
		*,
		sum(matches_won) over (partition by tournament, team order by match_week) as matches_won_cumulative,
		sum(matches_lost) over (partition by tournament, team order by match_week) as matches_lost_cumulative,
		sum(games_wons) over (partition by tournament, team order by match_week) as games_won_cumulative,
		sum(games_lost) over (partition by tournament, team order by match_week) as games_lost_cumulative
	from weekly_results
)

select 
	*,
	rank() over (partition by tournament, match_week order by games_won_cumulative desc, games_lost_cumulative, games_won_cumulative desc, games_lost_cumulative) as weekly_rank
from weekly_results_cumulative
order by match_week, weekly_rank
;

