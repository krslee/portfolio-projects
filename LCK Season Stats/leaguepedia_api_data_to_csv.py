import json
import os
import csv
import time

from mwrogue.esports_client import EsportsClient

site = EsportsClient("lol")

# This function writes query responses to csv files given a json response and file name
def write_to_csv(response, file_name):
    # file path
    file_path = './data/source/'

    # open a file for writing
    data_file = open(file_path + file_name, 'w', encoding="utf-8", newline='')

    # create the csv writer object
    csv_writer = csv.writer(data_file)

    count = 0
    
    for data in response:
        if count == 0:

            header = data.keys()

            csv_writer.writerow(header)

        values = data.values()
        
        csv_writer.writerow(values)

        count += 1

    data_file.close()
    

# This function formats string inputs to follow file naming convention
def format_string_for_file_name(string):
    return string.lower().replace(" ", "_")


# Leaguepedia API Cargo queries
# Get tournaments for a specified year and country
def get_country_tournaments(year, country):
    response = site.cargo_client.query(
        tables="Tournaments=T",
        fields="T.Name=Tournament, T.League, T.Region, T.Country, T.Year, T.DateStart, T.Date, T.OverviewPage",
        where=f"T.Year = {year} AND T.Country = '{country}'",
        limit=500
    )

    country_formatted = format_string_for_file_name(country)

    file_name = f"{country_formatted}_{year}_tournaments.csv"

    return [response, file_name]


# Get tournaments for a specified league
def get_league_tournaments(league):
    response = site.cargo_client.query(
        tables="Tournaments=T",
        fields="T.Name=Tournament, T.League, T.Region, T.Country, T.Year, T.DateStart, T.Date, T.OverviewPage",
        where=f"T.League = '{league}'",
        limit=500
    )

    league_formatted = format_string_for_file_name(league)

    file_name = f"{league_formatted}_tournaments.csv"

    return [response, file_name]


# Get all participating players per tournament for a specified league
def get_tournament_players(league):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, TournamentPlayers=TP",
            join_on="T.OverviewPage=TP.OverviewPage",
            fields="TP.OverviewPage, TP.Team, TP.N_PlayerInTeam, TP.Player, TP.Role, TP.Flag",
            where=f"T.League = '{league}'",
            limit=500,
            offset=offset
        )

        for data in response:
            final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(2) # delay to prevent being rate-limited

    league_formatted = format_string_for_file_name(league)

    file_name = f"{league_formatted}_tournament_players.csv"

    return [final_response, file_name]


# Get final results per tournament for a specified league
def get_tournament_results(league):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, TournamentResults=TR",
            join_on="T.OverviewPage=TR.OverviewPage",
            fields="TR.OverviewPage, TR.Date, TR.Place, TR.Place_Number, TR.Team",
            where=f"T.League = '{league}'",
            limit=500,
            offset=offset
        )

        for data in response:
                final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(2) # delay to prevent being rate-limited

    league_formatted = format_string_for_file_name(league)

    file_name = f"{league_formatted}_tournament_results.csv"

    return [final_response, file_name]


# Get all game results per tournament for a specified league
def get_scoreboard_games(league):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, ScoreboardGames=SG",
            join_on="T.OverviewPage=SG.OverviewPage",
            fields="SG.OverviewPage, SG.Team1, SG.Team2, SG.WinTeam, SG.LossTeam, SG.DateTime_UTC, SG.GameId, SG.MatchId, SG.N_GameInMatch, SG.Gamename, SG.Team1Score, SG.Team2Score, SG.Winner, SG.Gamelength, SG.Gamelength_Number, SG.Team1Bans, SG.Team2Bans, SG.Team1Picks, SG.Team2Picks",
            where=f"T.League = '{league}'",
            limit=500,
            offset=offset
        )

        for data in response:
                final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(2) # delay to prevent being rate-limited

    league_formatted = format_string_for_file_name(league)

    file_name = f"{league_formatted}_scoreboard_games.csv"

    return [final_response, file_name]


# Get player game results per tournament for a specified league
def get_scoreboard_players(league):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, ScoreboardPlayers=SP",
            join_on="T.OverviewPage=SP.OverviewPage",
            fields="SP.OverviewPage, SP.Name=Player, SP.Team, SP.Champion, SP.Kills, SP.Deaths, SP.Assists, SP.Gold, SP.CS, SP.DamageToChampions, SP.PlayerWin, SP.DateTime_UTC, SP.Role, SP.Role_Number, SP.IngameRole, SP.GameId, SP.MatchId",
            where=f"T.League = '{league}'",
            limit=500,
            offset=offset
        )

        for data in response:
            final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(3) # delay to prevent being rate-limited

    league_formatted = format_string_for_file_name(league)

    file_name = f"{league_formatted}_scoreboard_players.csv"

    return [final_response, file_name]


# Write results to csv files

year = 2024
country = 'South Korea'
league = 'Lol Champions Korea'

# tournaments = get_country_tournaments(year, country)
# write_to_csv(tournaments[0], tournaments[1])

# tournaments = get_league_tournaments(league)
# write_to_csv(tournaments[0], tournaments[1])

# tournament_players = get_tournament_players(league)
# write_to_csv(tournament_players[0], tournament_players[1])

# tournament_results = get_tournament_results(league)
# write_to_csv(tournament_results[0], tournament_results[1])

# scoreboard_games = get_scoreboard_games(league)
# write_to_csv(scoreboard_games[0], scoreboard_games[1])

scoreboard_players = get_scoreboard_players(league)
write_to_csv(scoreboard_players[0], scoreboard_players[1])
