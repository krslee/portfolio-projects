import time

from mwrogue.esports_client import EsportsClient
import urllib.request

site = EsportsClient("lol")

def get_filename_url_to_open(site: EsportsClient, filename, savefilename, path, width=None):
    response = site.client.api(
        action="query",
        format="json",
        titles=f"File:{filename}",
        prop="imageinfo",
        iiprop="url",
        iiurlwidth=width,
    )

    image_info = next(iter(response["query"]["pages"].values()))["imageinfo"][0]

    if width:
        url = image_info["thumburl"]
    else:
        url = image_info["url"]

    #In case you would like to save the image in a specific location, you can add the path after 'url,' in the line below.
    urllib.request.urlretrieve(url, path + savefilename + '.png')


def get_teams(tournament_name):
    response = site.cargo_client.query(
        tables="Tournaments=T, TournamentRosters=TR",
        join_on="T.OverviewPage=TR.OverviewPage",
        fields="TR.Team",
        where=f"T.Name = '{tournament_name}'",
        limit=500
    )

    teams = []

    for team in response:
        teams.append(team)

    return teams


def get_champions():
    response = site.cargo_client.query(
        tables="Champions=C",
        fields="C.Name",
        limit=200
    )

    champions = []

    for champion in response:
        champions.append(champion)

    return champions


# teams = get_teams('LCK Cup 2025')
# print(teams)

# for team in teams:
#     team_name = team.get('Team')

#     url = f"{team_name}logo square.png"
#     get_filename_url_to_open(site, url, team_name)


champions = get_champions()
print(champions)

champions_output_path = './images/champion_icons/'

for champion in champions:
    champion_name = champion.get('Name')
    champion_index = champions.index(champion)+1


    url = f"{champion_name}Square.png"
    get_filename_url_to_open(site, url, champion_name, champions_output_path)

    print(str(champion_index) + ": Saved " + champion_name + " Icon")

    if champion_index % 50 == 0:
        time.sleep(3)

