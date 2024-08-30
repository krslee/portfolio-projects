from mwrogue.esports_client import EsportsClient
import urllib.request

site = EsportsClient("lol")

def get_filename_url_to_open(site: EsportsClient, filename, team, width=None):
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
    urllib.request.urlretrieve(url, team + '.png')


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


teams = get_teams('LCK 2024 Spring')

print(teams)

for team in teams:
    team_name = team.get('Team')

    url = f"{team_name}logo square.png"
    get_filename_url_to_open(site, url, team_name)

# print(get_teams('LCK 2024 Spring'))