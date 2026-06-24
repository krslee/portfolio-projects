import json
import os
import csv
import time

from mwrogue.esports_client import EsportsClient
from mwrogue.auth_credentials import AuthCredentials

credentials = AuthCredentials(user_file="me")
site = EsportsClient('lol', credentials=credentials)
# site = EsportsClient("lol")

# This function writes query responses to csv files given a json response and file name
def write_to_csv(response, file_name):
    # file path
    file_path = './data/source/'

    # open a file for writing
    data_file = open(file_path + file_name, 'w', encoding="utf-8", newline='')

    # create the csv writer object
    csv_writer = csv.writer(data_file)

    count = 0
    
    for item in response:
        if count == 0:

            header = item.keys()

            csv_writer.writerow(header)

        values = item.values()
        
        csv_writer.writerow(values)

        count += 1

    data_file.close()
    

# This function formats string inputs to follow file naming convention
def format_string_for_file_name(string):
    return string.lower().replace(" ", "_")


# Leaguepedia API Cargo queries
# Get tournaments for a specified league
def get_tournaments(filters, file_prefix):
    response = site.cargo_client.query(
        tables="Tournaments=T",
        fields="T.Name=Tournament, T.League, T.Region, T.Country, T.Year, T.DateStart, T.Date, T.OverviewPage",
        where={filters},
        # where="T.League = 'World Championship'",
        limit=500
    )

    # tournament_formatted = format_string_for_file_name(tournament)

    file_name = f"{file_prefix}_tournaments.csv"

    return [response, file_name]


# Get all participating rosters for a specified tournament
def get_tournament_rosters(filters, file_prefix):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, TournamentRosters=TR, Teams",
            join_on="T.OverviewPage=TR.OverviewPage, TR.Team=Teams.Name",
            fields="T.OverviewPage, TR.Tournament, TR.Team, TR.Region, Teams.Region=TeamRegion, TR.RosterLinks, TR.Roles, TR.Flags",
            where={filters},
            limit=500,
            offset=offset
        )

        for data in response:
            final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(10) # delay to prevent being rate-limited

    # tournament_formatted = format_string_for_file_name(tournament)

    file_name = f"{file_prefix}_tournament_rosters.csv"

    return [final_response, file_name]


# Get all participating players for a specified tournament
def get_tournament_players(filters, file_prefix):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, TournamentPlayers=TP",
            join_on="T.OverviewPage=TP.OverviewPage",
            fields="T.OverviewPage, TP.Team, TP.N_PlayerInTeam, TP.Player, TP.Role, TP.Flag",
            where={filters},
            limit=500,
            offset=offset
        )

        for data in response:
            final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(10) # delay to prevent being rate-limited

    # tournament_formatted = format_string_for_file_name(tournament)

    file_name = f"{file_prefix}_tournament_players.csv"

    return [final_response, file_name]


# Get final results for a specified tournament
def get_tournament_results(filters, file_prefix):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, TournamentResults=TR",
            join_on="T.OverviewPage=TR.OverviewPage",
            fields="T.OverviewPage, TR.Date, TR.Place, TR.Place_Number, TR.Team, TR.Prize, TR.Prize_USD",
            where={filters},
            limit=500,
            offset=offset
        )

        for data in response:
                final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(10) # delay to prevent being rate-limited

    # tournament_formatted = format_string_for_file_name(tournament)

    file_name = f"{file_prefix}_tournament_results.csv"

    return [final_response, file_name]


# Get all game results for a specified tournament
def get_scoreboard_games(filters, file_prefix):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, ScoreboardGames=SG",
            join_on="T.OverviewPage=SG.OverviewPage",
            fields=("T.OverviewPage, SG.Team1, SG.Team2, SG.WinTeam, SG.LossTeam, SG.DateTime_UTC, SG.GameId, SG.MatchId, SG.N_GameInMatch, SG.Gamename," + 
                "SG.Team1Score, SG.Team2Score, SG.Winner, SG.Gamelength, SG.Gamelength_Number, SG.Team1Bans, SG.Team2Bans, SG.Team1Picks, SG.Team2Picks," + 
                "SG.Team1Clouds, SG.Team1Infernals, SG.Team1Mountains, SG.Team1Oceans, SG.Team1Hextechs, SG.Team1Chemtechs, SG.Team1Elders," + 
                "SG.Team2Clouds, SG.Team2Infernals, SG.Team2Mountains, SG.Team2Oceans, SG.Team2Hextechs, SG.Team2Chemtechs, SG.Team2Elders"),
            # fields="T.OverviewPage, SG.*",
            where={filters},
            limit=500,
            offset=offset
        )

        for data in response:
                final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(10) # delay to prevent being rate-limited

    # tournament_formatted = format_string_for_file_name(tournament)

    file_name = f"{file_prefix}_scoreboard_games.csv"

    return [final_response, file_name]


# Get player game results for a specified tournament
def get_scoreboard_players(filters, file_prefix):
    final_response = []
    row_count = 500
    offset = 0

    while row_count == 500:
        response = site.cargo_client.query(
            tables="Tournaments=T, ScoreboardPlayers=SP",
            join_on="T.OverviewPage=SP.OverviewPage",
            fields="T.OverviewPage, SP.Name=Player, SP.Team, SP.Champion, SP.Side, SP.Kills, SP.Deaths, SP.Assists, SP.Gold, SP.CS, SP.DamageToChampions, SP.PlayerWin, SP.DateTime_UTC, SP.Role, SP.Role_Number, SP.IngameRole, SP.GameId, SP.MatchId",
            where={filters},
            limit=500,
            offset=offset
        )

        for data in response:
            final_response.append(data)

        row_count = len(response)
        offset += 500
        print(row_count)

        time.sleep(15) # delay to prevent being rate-limited

    # tournament_formatted = format_string_for_file_name(tournament)

    file_name = f"{file_prefix}_scoreboard_players.csv"

    return [final_response, file_name]


# Write results to csv files
def main():

    tournament_filter_list = [
        # {'field': 'Year', 'value': '2024', 'filter': '='},
        # {'field': 'Country', 'value': 'South Korea', 'filter': '='},
        {'field': 'League', 'value': 'World Championship', 'filter': '='},
        {'field': 'Name', 'value': 'Worlds', 'filter': 'like'}
    ]

    filters = ""
    file_prefix = ""

    for filter in tournament_filter_list:
        if filter == tournament_filter_list[0]:
            # Append to filters
            if filter['filter'] == 'like':
                filters += 'T.' + filter['field'] + " like '%" + filter['value'] + "%'"
            else:
                filters += 'T.' + filter['field'] + " = '" + filter['value'] + "'"
        else:
            # Append to filters
            if filter['filter'] == 'like':
                filters += ' AND T.' + filter['field'] + " like '%" + filter['value'] + "%'"
            else:
                filters += ' AND T.' + filter['field'] + " = '" + filter['value'] + "'"
        # Append to file prefix
        file_prefix += format_string_for_file_name(filter['value']) + '_'

    print(filters)
    print(file_prefix)

    print('Starting get_tournaments')
    tournaments = get_tournaments(filters, file_prefix)
    write_to_csv(tournaments[0], tournaments[1])

    # print('Starting get_tournament_rosters')
    # tournament_rosters = get_tournament_rosters(filters, file_prefix)
    # write_to_csv(tournament_rosters[0], tournament_rosters[1])

    # print('Starting get_tournament_players')
    # tournament_players = get_tournament_players(filters, file_prefix)
    # write_to_csv(tournament_players[0], tournament_players[1])

    # print('Starting get_tournament_results')
    # tournament_results = get_tournament_results(filters, file_prefix)
    # write_to_csv(tournament_results[0], tournament_results[1])

    # print('Starting get_scoreboard_games')
    # scoreboard_games = get_scoreboard_games(filters, file_prefix)
    # write_to_csv(scoreboard_games[0], scoreboard_games[1])

    # print('Starting get_scoreboard_players')
    # scoreboard_players = get_scoreboard_players(filters, file_prefix)
    # write_to_csv(scoreboard_players[0], scoreboard_players[1])

main()