/**

QS World Universities Rankings Data Exploration (2021-2022)
Data Source: https://www.kaggle.com/prasertk/qs-world-university-rankings-2021

**/

-- Select which database to use
USE QSWorldUniversityRankings

-- Return all ranked universities
SELECT * FROM WorldUniversityRankings2021$
-- SELECT * FROM QSWorldUniversityRankings..WorldUniversityRankings2022$

-- Due to values in original data file, some rows are missing ranks and scores i.e. have null values
-- Thus, I deleted rows where rank_display is null
-- Did the same for 2022 rankings

DELETE FROM QSWorldUniversityRankings..WorldUniversityRankings2021$ 
WHERE rank_display IS NULL;

DELETE FROM QSWorldUniversityRankings..WorldUniversityRankings2022$ 
WHERE rank_display IS NULL;




/* 2021 TOP 200 UNIVERSITIES */

-- Display Top 200 universities of 2021
SELECT * FROM WorldUniversityRankings2021$
WHERE rank_display <= 200

-- Alternatively:
-- SELECT TOP 200 * FROM QSWorldUniversityRankings..WorldUniversityRankings2021$
-- However, excludes 201st university in table which also technically ranked 200

-- Display US universities in the Top 200
SELECT * FROM WorldUniversityRankings2021$
WHERE rank_display <= 200 AND country = 'United States'

-- Number of universities in the Top 200 per country
SELECT country, COUNT(*) AS universities_count
FROM WorldUniversityRankings2021$
WHERE rank_display <= 200
GROUP BY country
ORDER BY universities_count DESC

-- Universities in the Top 200 with max score by country
SELECT a.rank_display, a.university, a.country, a.score
FROM WorldUniversityRankings2021$ a
INNER JOIN (
    SELECT country, MAX(score) AS score
    FROM WorldUniversityRankings2021$
    GROUP BY country
) AS m ON a.country = m.country AND a.score = m.score
WHERE rank_display <= 200
ORDER BY a.rank_display

-- Max, min, and average scores of universities in the Top 200 by country
SELECT country, MAX(score) AS max_score, MIN(score) AS min_score, ROUND(AVG(score),2) AS avg_score
FROM WorldUniversityRankings2021$
WHERE rank_display <= 200
GROUP BY country
ORDER BY avg_score DESC




/* COMPARING 2021 RANKINGS TO 2022 RANKINGS */

-- Rankings and scores for each university in both 2021 and 2022
SELECT a.university, a. country, a.rank_display AS rank_display_2021, a.score AS score_2021, 
	b.rank_display AS rank_display_2022, b.score AS score_2022
FROM WorldUniversityRankings2021$ a
JOIN WorldUniversityRankings2022$ b
ON a.university = b.university
ORDER BY b.rank_display

-- Differences in ranks and scores between 2021 and 2022
-- Values calculated so that:
-- Rank difference - positive number -> ranked higher than the previous year
-- Score difference - positive number -> better score than the previous year
SELECT a.university, a. country, a.rank_display AS rank_display_2021, b.rank_display AS rank_display_2022, (a.rank_display-b.rank_display) AS rank_difference, 
a.score AS score_2021, b.score AS score_2022, ROUND((b.score-a.score),2) AS score_difference
FROM WorldUniversityRankings2021$ a
JOIN WorldUniversityRankings2022$ b
ON a.university = b.university
ORDER BY b.rank_display




/* CTE EXAMPLE */

-- Universities with max score in the Top 200 by country
WITH MaxScores (country, score)
AS (
	SELECT country, MAX(score) AS score
    FROM WorldUniversityRankings2021$
    GROUP BY country
)

SELECT a.rank_display, a.university, a.country, a.score
FROM WorldUniversityRankings2021$ a
INNER JOIN MaxScores m 
ON a.country = m.country AND a.score = m.score
WHERE rank_display <= 200
ORDER BY a.rank_display




/* TEMP TABLE EXAMPLE */

-- Universities with max score in the Top 200 by country
SELECT country, MAX(score) as score
INTO #MaxScores
FROM WorldUniversityRankings2021$
GROUP BY country

SELECT a.rank_display, a.university, a.country, a.score
FROM WorldUniversityRankings2021$ a
INNER JOIN #MaxScores m 
ON a.country = m.country AND a.score = m.score
WHERE rank_display <= 200
ORDER BY a.rank_display
