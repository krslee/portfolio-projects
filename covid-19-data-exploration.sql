/*

Covid 19 Data Exploration 
Data Source: https://ourworldindata.org/covid-deaths

*/

-- SELECTING FROM COVID DEATHS TABLE

SELECT * 
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4




-- DATA BY LOCATION/COUNTRIES

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Showing likelihood of dying due to Covid contraction

SELECT continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 2,3 

-- Looking at Total Cases vs Total Deaths (US)
-- Showing likelihood of dying due to Covid contraction (in US)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2 

-- Looking at Total Cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentageInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 

-- Looking at Total Cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
FROM CovidProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2 

-- Showing countries with Highest Infection Rate

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS HighestPercentageInfected 
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestPercentageInfected DESC

-- Showing countries with Highest Death Count 

SELECT continent, location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY TotalDeathCount DESC

-- Showing countries in North America with Highest Death Count 

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent = 'North America'
GROUP BY location
ORDER BY TotalDeathCount DESC




-- DATA BY CONTINENT

-- Showing Total Death Count of each continent

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income'
-- original dataset includes values irrevelant to this query such as "High income", "Upper middle income", etc.
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing Total Death Count of each continent (v2)

SELECT location, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income'
GROUP BY location
ORDER BY TotalDeathCount DESC




-- GLOBAL DATA

-- Showing daily global data

SELECT date, SUM(new_cases) as TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, 
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 

-- Showing global totals

SELECT SUM(new_cases) as TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, 
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2 




-- SELECTING FROM COVID VACCINATIONS TABLE

-- Looking at Total Population vs Vaccinations

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) 
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS d
JOIN CovidProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- USER CTE

WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS
(
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS bigint)) 
		OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
	FROM CovidProject..CovidDeaths AS d
	JOIN CovidProject..CovidVaccinations AS v
		ON d.location = v.location
		AND d.date = v.date
	WHERE d.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	NewVaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) 
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS d
JOIN CovidProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM #PercentPopulationVaccinated




-- CREATING VIEW EXAMPLE 

-- Percent of population vaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) 
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS d
JOIN CovidProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinated
