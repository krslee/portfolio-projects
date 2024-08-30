DROP TABLE tournaments CASCADE;

CREATE TABLE tournaments(
	tournament VARCHAR(255),
 	league VARCHAR(50),
	region VARCHAR(50),
	country VARCHAR(50),
	year int,
	datestart date,
	date date,
	overviewpage VARCHAR(255),
	datestart_precision int,
	date_precision int
);

COPY tournaments(
	tournament,
	league, 
	region,
	country, 
	year, 
	datestart,
	date,
	overviewpage,
	datestart_precision,
	date_precision
)
FROM 'C:\Users\Kristine\Desktop\Data Projects\lck-stats\data\source\lol_champions_korea_tournaments.csv'
DELIMITER ','
CSV HEADER;


CREATE TABLE scoreboard_games(
	overviewpage VARCHAR(255),
	team1 VARCHAR(50),
	team2 VARCHAR(50),
	winteam VARCHAR(50),
	lossteam VARCHAR(50),
	datetime_utc timestamp,
	gameid VARCHAR(255),
	matchid VARCHAR(255),
	ngameinmatch int,
	gamename VARCHAR(50),
	team1score int,
	team2score int,
	winner int,
	gamelength VARCHAR(50),
	gamelength_number float,
	team1bans VARCHAR(255),
	team2bans VARCHAR(255),
	team1picks VARCHAR(255),
	team2picks VARCHAR(255),
	datetime_utc_precision int
);

COPY scoreboard_games(
	overviewpage,
	team1, 
	team2, 
	winteam, 
	lossteam, 
	datetime_utc,
	gameid,
	matchid,
	ngameinmatch,
	gamename,
	team1score,
	team2score,
	winner,
	gamelength,
	gamelength_number,
	team1bans,
	team2bans,
	team1picks,
	team2picks,
	datetime_utc_precision
)
FROM 'C:\Users\Kristine\Desktop\Data Projects\lck-stats\data\source\lol_champions_korea_scoreboard_games.csv'
DELIMITER ','
CSV HEADER;


CREATE TABLE tournament_players(
	overviewpage VARCHAR(255),
	team VARCHAR(50),
	nplayerinteam int,
	player VARCHAR(50),
	role VARCHAR(50),
	flag VARCHAR(50)
);

COPY tournament_players(
	overviewpage,
	team, 
	nplayerinteam,
	player,
	role,
	flag
)
FROM 'C:\Users\Kristine\Desktop\Data Projects\\lck-stats\data\source\lol_champions_korea_tournament_players.csv'
DELIMITER ','
CSV HEADER;



CREATE TABLE tournament_results(
	overviewpage VARCHAR(255),
	date date,
	place VARCHAR(10),
	place_number int,
	team VARCHAR(50),
	date_precision int
);

COPY tournament_results(
	overviewpage, 
	date,
	place,
	place_number,
	team,
	date_precision
)
FROM 'C:\Users\Kristine\Desktop\Data Projects\lck-stats\data\source\lol_champions_korea_tournament_results.csv'
DELIMITER ','
CSV HEADER;


CREATE TABLE scoreboard_players(
	overviewpage VARCHAR(255),
	player VARCHAR(255),
	team VARCHAR(50),
	champion VARCHAR(50),
	kills int,
	deaths int,
	assists int,
	gold int,
	cs int,
	damagetochampions int,
	playerwin VARCHAR(10),
	datetime_utc timestamp,
	role VARCHAR(10),
	rolenumber int,
	ingamerole VARCHAR(10),
	gameid VARCHAR(255),
	matchid VARCHAR(255),
	datetime_utc_precision int
);

COPY scoreboard_players(
	overviewpage, 
	player,
	team,
	champion,
	kills,
	deaths,
	assists,
	gold,
	cs,
	damagetochampions,
	playerwin,
	datetime_utc,
	role,
	rolenumber,
	ingamerole,
	gameid,
	matchid,
	datetime_utc_precision
)
FROM 'C:\Users\Kristine\Desktop\Data Projects\lck-stats\data\source\lol_champions_korea_scoreboard_players.csv'
DELIMITER ','
CSV HEADER;