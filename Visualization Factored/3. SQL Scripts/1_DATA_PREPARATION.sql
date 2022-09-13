-- DATA PREPARATION

-- 1. CREATING SPI_MATCHES_2
SELECT season, [date], league_id, league, team1, team2, spi1, spi2, prob1, prob2, probtie, proj_score1, proj_score2, importance1, importance2, score1, score2, xg1, xg2, nsxg1, nsxg2, adj_score1, adj_score2 
FROM spi_matches
WHERE ISNUMERIC(SCORE1)= 0

select SEASON, [date] AS SMALLDATETIME, YEAR([date]) AS YEAR_D, MONTH([date]) AS MONTH_D
	   , league_id, league, team1, team2, CAST(spi1 AS decimal(4,2)) AS SPI1, CAST(spi2 AS NUMERIC(4,2)) AS SPI2, CAST(PROB1 AS NUMERIC(5,4)) AS PROB1, CAST(PROB2 AS NUMERIC(5,4)) AS PROB2
	   , CAST(probtie AS NUMERIC(5,4)) AS probtie, CAST(proj_score1 AS NUMERIC(3,2)) AS proj_score1, CAST(proj_score2 AS NUMERIC(3,2)) AS proj_score2
	   , TRY_CAST(importance1  AS NUMERIC(3,1)) AS importance1, TRY_CAST(importance2 AS NUMERIC(3,1)) AS importance2, TRY_CAST(SCORE1 AS NUMERIC) SCORE1, TRY_CAST(SCORE2 AS NUMERIC) SCORE2
	   , TRY_CAST(XG1 AS NUMERIC(3,2)) AS XG1, TRY_CAST(XG2 AS NUMERIC(3,2)) AS XG2, TRY_CAST(NSXG1 AS NUMERIC(3,2)) AS NSXG1, TRY_CAST(NSXG2 AS NUMERIC(3,2)) AS NSXG2
	   , TRY_CAST(ADJ_SCORE1 AS NUMERIC(3,2)) AS ADJ_SCORE1, TRY_CAST(ADJ_SCORE2 AS NUMERIC(3,2)) AS ADJ_SCORE2
INTO SPI_MATCHES_2
from spi_matches

-- 2. CREATING SPI_MATCHES_LATEST_2
SELECT season, [date], league_id, league, team1, team2, spi1, spi2, prob1, prob2, probtie, proj_score1, proj_score2, importance1, importance2, score1, score2, xg1, xg2, nsxg1, nsxg2, adj_score1, adj_score2 
FROM spi_matches_latest

SELECT SEASON, [date] AS SMALLDATETIME, YEAR([date]) AS YEAR_D, MONTH([date]) AS MONTH_D
	   , league_id, league, team1, team2, CAST(spi1 AS decimal(4,2)) AS SPI1, CAST(spi2 AS NUMERIC(4,2)) AS SPI2, CAST(PROB1 AS NUMERIC(5,4)) AS PROB1, CAST(PROB2 AS NUMERIC(5,4)) AS PROB2
	   , CAST(probtie AS NUMERIC(5,4)) AS probtie, CAST(proj_score1 AS NUMERIC(3,2)) AS proj_score1, CAST(proj_score2 AS NUMERIC(3,2)) AS proj_score2
	   , TRY_CAST(importance1  AS NUMERIC(3,1)) AS importance1, TRY_CAST(importance2 AS NUMERIC(3,1)) AS importance2, TRY_CAST(SCORE1 AS NUMERIC) SCORE1, TRY_CAST(SCORE2 AS NUMERIC) SCORE2
	   , TRY_CAST(XG1 AS NUMERIC(3,2)) AS XG1, TRY_CAST(XG2 AS NUMERIC(3,2)) AS XG2, TRY_CAST(NSXG1 AS NUMERIC(3,2)) AS NSXG1, TRY_CAST(NSXG2 AS NUMERIC(3,2)) AS NSXG2
	   , TRY_CAST(ADJ_SCORE1 AS NUMERIC(3,2)) AS ADJ_SCORE1, TRY_CAST(ADJ_SCORE2 AS NUMERIC(3,2)) AS ADJ_SCORE2
INTO SPI_MATCHES_LATEST_2
FROM spi_matches_latest


-- 3.CREATING SPI_GLOBAL_RANKINGS_2
SELECT [rank], prev_rank, [name], league, [off], def, spi
FROM [dbo].[spi_global_rankings]

SELECT [rank], prev_rank, [name], league, CAST([off] AS NUMERIC(3,2)) AS [off], CAST(def AS NUMERIC(3,2)) AS [def], CAST(spi AS NUMERIC(4,2)) AS [SPI]
INTO SPI_GLOBAL_RANKINGS_2
FROM [dbo].[spi_global_rankings]



-- 4. CREATING SPI_GLOBAL_RANKINGS_INTL_2
SELECT [rank], [name], confed, [off], def, spi
FROM [dbo].[spi_global_rankings_intl]

SELECT [rank], [name], confed, CAST([off] AS NUMERIC(3,2)) AS [off], CAST(def AS NUMERIC(3,2)) AS [def], CAST(spi AS NUMERIC(4,2)) AS [SPI]
INTO SPI_GLOBAL_RANKINGS_INTL_2
FROM [dbo].[spi_global_rankings_intl]

-- 5. DROP OF INITIAL TABLES

DROP TABLE spi_matches, spi_matches_latest, [spi_global_rankings], [spi_global_rankings_intl]
;

-- END