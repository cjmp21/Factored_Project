-- 2. DATA EXPLORATION AND AUXILIARY TABLES CREATION

-- 1. Who are the best and worst performing teams in each league? / How much better are the best performers than the worst performers in each league?
-- 1.1. CREATING TABLE OF RESULTS BY TEAM IN THE LATEST SESION OF EACH LEAGUE (RESULTS_BY_TEAM)

; 
SELECT  *, IIF(COALESCE(SCORE1,0)>COALESCE(SCORE2,0),3,IIF(COALESCE(SCORE1,0)=COALESCE(SCORE2,0),1,0)) AS POINTS_TEAM1, IIF(COALESCE(SCORE2,0)>COALESCE(SCORE1,0),3,IIF(COALESCE(SCORE2,0)=COALESCE(SCORE1,0),1,0)) AS POINTS_TEAM2
FROM [dbo].[SPI_MATCHES_LATEST_2] -- MATCH BY MATCH SCORE FROM THE LATEST SESION

; WITH TABLE1 AS (
SELECT SEASON, LEAGUE, TEAM, SUM(SCORE1*GAMES) AS GOALS_IN_FAVOR, SUM(SCORE2*GAMES) AS GOALS_AGAINST, SUM(POINTS_TEAM1) AS POINTS, SUM(GAMES) GAMES, SUM(WON) WON, SUM(TIE) TIE, SUM(LOST) LOST 
FROM (
	SELECT SEASON, LEAGUE, TEAM1 AS TEAM, COALESCE(SCORE1,0) SCORE1, COALESCE(SCORE2,0) SCORE2, SUM(IIF(COALESCE(SCORE1,0)>COALESCE(SCORE2,0),3,IIF(COALESCE(SCORE1,0)=COALESCE(SCORE2,0),1,0))) AS POINTS_TEAM1
		   , COUNT(TEAM1) AS GAMES, SUM(IIF(COALESCE(SCORE1,0)>COALESCE(SCORE2,0),1,0)) AS WON, SUM(IIF(COALESCE(SCORE1,0)=COALESCE(SCORE2,0),1,0)) AS TIE
		   , SUM(IIF(COALESCE(SCORE2,0)>COALESCE(SCORE1,0),1,0)) AS LOST
	FROM [dbo].[SPI_MATCHES_LATEST_2] 
	GROUP BY SEASON, LEAGUE, TEAM1, COALESCE(SCORE1,0), COALESCE(SCORE2,0) 
) AS A
GROUP BY SEASON, LEAGUE, TEAM
)

, TABLE2 AS (
SELECT SEASON, LEAGUE, TEAM, SUM(SCORE1*GAMES) AS GOALS_IN_FAVOR, SUM(SCORE2*GAMES) AS GOALS_AGAINST, SUM(POINTS_TEAM1) AS POINTS, SUM(GAMES) GAMES, SUM(WON) WON, SUM(TIE) TIE, SUM(LOST) LOST 
FROM (
	SELECT SEASON, LEAGUE, TEAM2 AS TEAM, COALESCE(SCORE2,0) SCORE1, COALESCE(SCORE1,0) SCORE2, SUM(IIF(COALESCE(SCORE2,0)>COALESCE(SCORE1,0),3,IIF(COALESCE(SCORE2,0)=COALESCE(SCORE1,0),1,0))) AS POINTS_TEAM1
		   , COUNT(TEAM2) AS GAMES, SUM(IIF(COALESCE(SCORE2,0)>COALESCE(SCORE1,0),1,0)) AS WON, SUM(IIF(COALESCE(SCORE2,0)=COALESCE(SCORE1,0),1,0)) AS TIE
		   , SUM(IIF(COALESCE(SCORE1,0)>COALESCE(SCORE2,0),1,0)) AS LOST
	FROM [dbo].[SPI_MATCHES_LATEST_2] 
	GROUP BY SEASON, LEAGUE, TEAM2, COALESCE(SCORE1,0), COALESCE(SCORE2,0) 
) AS A
GROUP BY SEASON, LEAGUE, TEAM
)

SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST, IIF(GAMES=0,NULL,WON*1.000/GAMES) AS PRCNT_WON, IIF(GAMES=0,NULL,TIE*1.000/GAMES) AS PRCNT_TIE, IIF(GAMES=0,NULL,LOST*1.000/GAMES) AS PRCNT_LOST 
INTO RESULTS_BY_TEAM
FROM (
	SELECT SEASON, LEAGUE, TEAM, SUM(GOALS_IN_FAVOR) GOALS_IN_FAVOR, SUM(GOALS_AGAINST) GOALS_AGAINST, SUM(POINTS) POINTS, SUM(GAMES) GAMES, SUM(WON) WON, SUM(TIE) TIE, SUM(LOST) LOST
	FROM (
		SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST
		FROM TABLE1 
		UNION ALL
		SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST
		FROM TABLE2
	) AS A
	GROUP BY SEASON, LEAGUE, TEAM
) AS A

;
 
-- 1.2 CREATING TABLES OF TOP FIVE AND WORST FIVE TEAMS FOR EACH LEAGUE (TOP_FIVE, WORST_FIVE)

SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST, PRCNT_WON, PRCNT_TIE, PRCNT_LOST, [RANK]
INTO TOP_FIVE
FROM (
	SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST, PRCNT_WON, PRCNT_TIE, PRCNT_LOST 
		   , RANK()
		   OVER (PARTITION BY SEASON, LEAGUE
		   ORDER BY POINTS DESC) AS RANK
	FROM RESULTS_BY_TEAM
) AS A
WHERE RANK <=5

SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST, PRCNT_WON, PRCNT_TIE, PRCNT_LOST, [RANK_2] AS [RANK]
INTO WORST_FIVE
FROM (
	SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST, PRCNT_WON, PRCNT_TIE, PRCNT_LOST 
		   , RANK()
		   OVER (PARTITION BY SEASON, LEAGUE
		   ORDER BY POINTS ASC) AS RANK_1
		   , RANK()
		   OVER (PARTITION BY SEASON, LEAGUE
		   ORDER BY POINTS DESC) AS RANK_2
	FROM RESULTS_BY_TEAM
) AS A
WHERE RANK_1 <=5

-- 2. How competitive is each league?
-- 2.1. CALCULATING DISPERSION OF PRCNT_WON PER LEAGUE (LESS IS MORE COMPETITIVE, MORE IS LESS COMPETITIVE) / COMPETITIVENESS_LEAGUES

SELECT SEASON, LEAGUE, NUMBER_TEAMS, GAMES_PER_TEAM, AVG_PRCNT_WON, AVG_PRCNT_TIE, AVG_PRCNT_LOST, STDEV_PRCNT_WON, STDEV_PRCNT_TIE, STDEV_PRCNT_LOST
	  ,  ROW_NUMBER() OVER (ORDER BY STDEV_PRCNT_WON ASC) AS RANK_1, MIN_PRCNT_WON, MAX_PRCNT_WON
INTO COMPETITIVENESS_LEAGUES
FROM (
SELECT  SEASON, LEAGUE, COUNT(TEAM) AS NUMBER_TEAMS, MAX(GAMES) AS GAMES_PER_TEAM
	   , AVG(PRCNT_WON) AVG_PRCNT_WON, AVG(PRCNT_TIE) AVG_PRCNT_TIE, AVG(PRCNT_LOST) AVG_PRCNT_LOST
	   , STDEV(PRCNT_WON) STDEV_PRCNT_WON, STDEV(PRCNT_TIE) STDEV_PRCNT_TIE, STDEV(PRCNT_LOST) STDEV_PRCNT_LOST
	   , MIN(PRCNT_WON) MIN_PRCNT_WON, MAX(PRCNT_WON) MAX_PRCNT_WON
FROM (
	SELECT SEASON, LEAGUE, TEAM, GOALS_IN_FAVOR, GOALS_AGAINST, POINTS, GAMES, WON, TIE, LOST, PRCNT_WON, PRCNT_TIE, PRCNT_LOST
	FROM RESULTS_BY_TEAM
	WHERE LEAGUE NOT LIKE 'FA%'
) AS A 
GROUP BY SEASON, LEAGUE
) AS A

-- 2.2. CALCULATING PERCENTILES OF PRCNT_WON PER LEAGUE (PERCENTILES_LEAGUE)
SELECT DISTINCT SEASON, LEAGUE
	   , PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY PRCNT_WON)
							  OVER (PARTITION BY LEAGUE) AS P50_PRCNT_WON
	   , PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY PRCNT_WON)
							  OVER (PARTITION BY LEAGUE) AS P25_PRCNT_WON
	   , PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY PRCNT_WON)
							  OVER (PARTITION BY LEAGUE) AS P75_PRCNT_WON
INTO PERCENTILES_LEAGUE
FROM RESULTS_BY_TEAM
WHERE LEAGUE NOT LIKE 'FA%'



-- 3. How would the worst performers in the best league perform in the worst performing
--    league? How would the best performers in the worst league perform in the best
--    performing league?

-- 3.1 CALCULATING AN ADJUST_FACTOR TO COMPARE LEAGUES (ADJUST_FACTOR)
SELECT LEAGUE, ADJUST_FACTOR/100 AS ADJUST_FACTOR, ROW_NUMBER() OVER (ORDER BY ADJUST_FACTOR DESC) AS RANK_1
INTO ADJUST_FACTOR
FROM (
	SELECT LEAGUE, IIF(LEAGUE = 'UEFA Champions League', 100, IIF(LEAGUE = 'UEFA Europa League', 90.505, IIF( LEAGUE = 'UEFA Europa Conference League', 81.01, AVG_SPI))) AS ADJUST_FACTOR
	FROM (
		SELECT LEAGUE, AVG(SPI) AS AVG_SPI 
		FROM [dbo].[SPI_GLOBAL_RANKINGS_2]
		GROUP BY LEAGUE
	) AS A 
) AS A
WHERE LEAGUE NOT IN ('UEFA Champions League', 'UEFA Europa League', 'UEFA Europa Conference League') --> EXCLUDED BECAUSE MORE THAN A HALF OF THE GAMES HAVEN'T BEEN RECORDED IN THE DB YET

-- 3.2. WORST PERFORMERS OF THE BEST LEAGUE IN THE WORST LEAGUE (WORST_PERFORMERS_BEST_LEAGUE)

; WITH FACTOR AS (
SELECT SUM(ADJUST_FACTOR) AS FACTOR
FROM (
	SELECT LEAGUE AS WORST_LEAGUE, -ADJUST_FACTOR ADJUST_FACTOR FROM ADJUST_FACTOR
	WHERE RANK_1 = (SELECT MAX(RANK_1) FROM ADJUST_FACTOR)
UNION
	SELECT LEAGUE AS BEST_LEAGUE, ADJUST_FACTOR FROM ADJUST_FACTOR
	WHERE RANK_1 = (SELECT MIN(RANK_1) FROM ADJUST_FACTOR)
) AS A 
)

SELECT SEASON, LEAGUE, TEAM, ROUND(IIF(ADDED = 1, IIF(FACTOR=0,NULL, POINTS/FACTOR),POINTS),0) AS POINTS, IIF(ADDED = 1, NULL, GAMES) GAMES
	   , ROW_NUMBER() OVER (ORDER BY ROUND(IIF(ADDED = 1, IIF(FACTOR=0,NULL, POINTS/FACTOR),POINTS),0) DESC) AS RANK_1, ADDED
INTO WORST_PERFORMERS_BEST_LEAGUE
FROM (
SELECT A.SEASON, A.LEAGUE, A.TEAM, A.GOALS_IN_FAVOR, A.GOALS_AGAINST, A.POINTS, A.GAMES, A.WON, A.TIE, A.LOST, A.PRCNT_WON, A.PRCNT_TIE, A.PRCNT_LOST 
	   , (SELECT FACTOR FROM FACTOR) AS FACTOR, 1 AS ADDED
FROM WORST_FIVE AS A INNER JOIN (SELECT LEAGUE AS BEST_LEAGUE,  ADJUST_FACTOR FROM ADJUST_FACTOR
				WHERE RANK_1 = (SELECT MIN(RANK_1) FROM ADJUST_FACTOR)) AS B 
ON A.LEAGUE = B.BEST_LEAGUE
UNION ALL
SELECT A.*, (SELECT FACTOR FROM FACTOR) AS FACTOR, 0 AS ADDED 
FROM RESULTS_BY_TEAM  AS A INNER JOIN (SELECT LEAGUE AS WORST_LEAGUE,  ADJUST_FACTOR FROM ADJUST_FACTOR
				WHERE RANK_1 = (SELECT MAX(RANK_1) FROM ADJUST_FACTOR)) AS B 
ON A.LEAGUE = B.WORST_LEAGUE
) AS A 


-- 3.3. BEST PERFORMERS OF THE WORST LEAGUE IN THE BEST LEAGUE (BEST_PERFORMERS_WORST_LEAGUE)

; WITH FACTOR AS (
SELECT SUM(ADJUST_FACTOR) AS FACTOR
FROM (
SELECT LEAGUE AS WORST_LEAGUE, ADJUST_FACTOR FROM ADJUST_FACTOR
WHERE RANK_1 = (SELECT MIN(RANK_1) FROM ADJUST_FACTOR)
UNION
SELECT LEAGUE AS BEST_LEAGUE, -ADJUST_FACTOR ADJUST_FACTOR  FROM ADJUST_FACTOR
WHERE RANK_1 = (SELECT MAX(RANK_1) FROM ADJUST_FACTOR)
) AS A 
)

SELECT SEASON, LEAGUE, TEAM, ROUND(IIF(ADDED = 1, IIF(FACTOR=0,NULL, POINTS*FACTOR),POINTS),0) AS POINTS, IIF(ADDED = 1, NULL, GAMES) GAMES
   , ROW_NUMBER() OVER (ORDER BY ROUND(IIF(ADDED = 1, IIF(FACTOR=0,NULL, POINTS*FACTOR),POINTS),0) DESC) AS RANK_1, ADDED
INTO BEST_PERFORMERS_WORST_LEAGUE
FROM (
SELECT A.SEASON, A.LEAGUE, A.TEAM, A.GOALS_IN_FAVOR, A.GOALS_AGAINST, A.POINTS, A.GAMES, A.WON, A.TIE, A.LOST, A.PRCNT_WON, A.PRCNT_TIE, A.PRCNT_LOST 
	   , (SELECT FACTOR FROM FACTOR) AS FACTOR, 1 AS ADDED
FROM TOP_FIVE AS A INNER JOIN (SELECT LEAGUE AS WORST_LEAGUE,  ADJUST_FACTOR FROM ADJUST_FACTOR
				WHERE RANK_1 = (SELECT MAX(RANK_1) FROM ADJUST_FACTOR)) AS B 
ON A.LEAGUE = B.WORST_LEAGUE
UNION ALL
SELECT A.*, (SELECT FACTOR FROM FACTOR) AS FACTOR, 0 AS ADDED 
FROM RESULTS_BY_TEAM  AS A INNER JOIN (SELECT LEAGUE AS BEST_LEAGUE,  ADJUST_FACTOR FROM ADJUST_FACTOR
				WHERE RANK_1 = (SELECT MIN(RANK_1) FROM ADJUST_FACTOR)) AS B 
ON A.LEAGUE = B.BEST_LEAGUE
) AS A 
;

-- 4. END