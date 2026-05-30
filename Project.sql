DROP TABLE IF EXISTS netflix;

/* 
PRE-ANALYSIS NOTES:
In Excel, I counted the max character lengths using MAX(LEN(column_range)) 
to accurately map out the exact varchar boundaries for our schema definitions below.
*/ 
CREATE TABLE netflix (
    show_id      VARCHAR(6),
    type         VARCHAR(10),
    title        VARCHAR(150),
    director     VARCHAR(208),
    casts        VARCHAR(1000),
    country      VARCHAR(150),
    date_added   VARCHAR(50),
    release_year INT,
    rating       VARCHAR(10),
    duration     VARCHAR(15),
    listed_in    VARCHAR(100),
    description  VARCHAR(250)
);

SELECT * FROM netflix;

-- ============================================================================
-- Business Problem 1: Count Content Volume & Audit Age-Inappropriate Ratings for US Market
-- ============================================================================

/* 
NOTE: 
1st Query: Count The Number Of Movies Vs Tv Shows On Our Site.
I want to check how many movies and TV shows are NOT appropriate for some age segmentations, 
especially for users Under 18. These specific movies and series should come from the United States.
*/
SELECT 
    type,
    COUNT(*) AS total_content
FROM netflix
GROUP BY type;

SELECT 
    type,
    rating,
    country,
    COUNT(*) AS content_count
FROM netflix
WHERE rating IN ('TV-MA', 'R', 'NC-17') 
  AND country = 'United States'
GROUP BY type, rating, country
ORDER BY content_count DESC
LIMIT 50;

-- ============================================================================
-- Business Problem 2: Market Share Analysis - Most Common vs. Most Unpopular Ratings
-- ============================================================================

/* 
NOTE: 
As we are to Find the most common Rating of those Content_Types, we have to Rank them 
in order to see which one is the top. We can't use MAX/MIN because those are text data types.
We will find the top 5 most common ratings from two separate contents.
*/
SELECT 
    type,
    rating,
    total_content
FROM (
    SELECT 
        type,
        rating,
        COUNT(*) AS total_content,
        RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
    FROM netflix
    GROUP BY type, rating
) AS ranked_ratings 
WHERE ranking <= 5;

/* 
NOTE: 
Or We Could Find the Worst top 5 / should we call "the most unpopular ratings of 2021" 
so we can prepare what to do to gain some audiences for those shows.
*/
WITH top_5_worst_common_ratings AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS total_content,
        RANK() OVER(PARTITION BY type ORDER BY COUNT(*) ASC) AS ranking
    FROM netflix
    GROUP BY type, rating
) 
SELECT 
    type,
    rating,
    ranking,
    total_content
FROM top_5_worst_common_ratings
WHERE ranking <= 5
ORDER BY type, ranking ASC;

-- ============================================================================
-- Business Problem 3: 2021 Content Strategy & Niche Genre Penetration
-- ============================================================================

SELECT 
    title,
    casts,
    description
FROM netflix
WHERE release_year = 2021 
  AND type = 'Movie';

/* 
NOTE: 
Find out how many movies and TV shows came out in the year 2021. 
Purpose: Do this to filter down those movies and make sure those are not appearing on under-18 phones.
*/
WITH adult_rated_movies_and_shows AS (
    SELECT 
        type,
        listed_in AS genre,
        rating,
        release_year,
        COUNT(*) AS total_titles,
        RANK() OVER(PARTITION BY type ORDER BY COUNT(*) ASC) AS ranking 
    FROM netflix
    WHERE rating IN ('TV-MA', 'R', 'NC-17') 
      AND release_year = 2021 
    GROUP BY rating, type, listed_in, release_year
)
SELECT 
    ranking,
    type,
    genre,
    rating,
    total_titles
FROM adult_rated_movies_and_shows
WHERE ranking <= 5;

-- ============================================================================
-- Business Problem 4: Global Footprint - Top 5 Content-Producing Countries
-- ============================================================================

/* 
NOTE: 
By using STRING_TO_ARRAY, we will convert our string and put it inside a list, 
then UNNEST does the rest of the job by giving each row a separate value.
*/
SELECT 
    UNNEST(STRING_TO_ARRAY(country, ',')) AS country_origin,
    COUNT(show_id) AS total_content
FROM netflix
GROUP BY country_origin 
ORDER BY total_content DESC
LIMIT 5;

-- ============================================================================
-- Business Problem 5: Production Benchmarks - Longest Movie Runtimes
-- ============================================================================

SELECT * 
FROM netflix
WHERE type = 'Movie' 
  AND duration = (SELECT MAX(duration) FROM netflix);

-- ============================================================================
-- Business Problem 6: Temporal Velocity - Dynamic Review of Content Added Over Time
-- ============================================================================

SELECT * 
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= (SELECT MAX(TO_DATE(date_added, 'Month DD, YYYY')) FROM netflix) - INTERVAL '5 years';

-- ============================================================================
-- Business Problem 7: Directory Spotlight - Comprehensive Catalog for Toshiya Shinohara
-- ============================================================================

/* 
NOTE: 
I formatted the date so that it can be easily visualized by our Executives. 
By using ILIKE, we won't have to worry about any case sensitivity issues.
*/
SELECT 
    title,
    type,
    listed_in AS genre,
    casts,
    director,
    description,
    duration,
    TO_DATE(date_added, 'Month DD, YYYY') AS clean_date_added
FROM netflix 
WHERE director ILIKE '%Toshiya Shinohara%' 
  AND TO_DATE(date_added, 'Month DD, YYYY') BETWEEN '2021-01-01' AND '2021-12-31';

-- ============================================================================
-- Business Problem 8: Long-Form Content Metrics - TV Shows with More Than 5 Seasons
-- ============================================================================

SELECT * 
FROM netflix 
WHERE type = 'TV Show' 
  AND SPLIT_PART(duration, ' ', 1)::NUMERIC > 5;

-- ============================================================================
-- Business Problem 9: Categorical Distribution - Granular Total Content Items per Genre
-- ============================================================================

/* 
NOTE: 
Change those with the mixture of TV shows and movies.
*/
SELECT 
    UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre,
    COUNT(show_id) AS total_count
FROM netflix
GROUP BY genre
ORDER BY total_count DESC;

-- ============================================================================
-- Business Problem 10: Market Concentration - Annual Content Ingestion Ratio for US
-- ============================================================================

/* 
NOTE: 
We will use the date_added columns and EXTRACT only the year from it after converting to a date format.
We will get the total contents that were added in those years by each country.
*/
SELECT 
    EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year_added,
    COUNT(*) AS annual_count,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM netflix WHERE country = 'United States')::NUMERIC * 100, 2) AS percent_of_total_us_catalog
FROM netflix
WHERE country = 'United States'
GROUP BY year_added
ORDER BY year_added DESC;

-- ============================================================================
-- Business Problem 11: Genre Deep-Dives - Crime TV Shows
-- ============================================================================

SELECT * 
FROM netflix 
WHERE listed_in ILIKE '%Crime TV Shows%';

-- ============================================================================
-- Business Problem 12: Data Integrity Audits - Content Missing Director Attribution
-- ============================================================================

SELECT * 
FROM netflix 
WHERE director IS NULL;

-- ============================================================================
-- Business Problem 13: Actor Historical Track Record - Recent Works for 'Muhammad Ali'
-- ============================================================================

SELECT * 
FROM netflix
WHERE casts ILIKE '%Muhammad Ali%' 
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;

-- ============================================================================
-- Business Problem 14: Star Power Analytics - Top 10 High-Volume Cast Members in the US
-- ============================================================================

/* 
NOTE: 
There are too many casts in one show, but an actor can perform in different films, 
so we need to split them one by one.
*/
SELECT 
    UNNEST(STRING_TO_ARRAY(casts, ',')) AS actor_name,
    COUNT(*) AS appearance_count
FROM netflix 
WHERE country ILIKE '%United States%'
GROUP BY actor_name
ORDER BY appearance_count DESC
LIMIT 10;

-- ============================================================================
-- Custom Business Problem 15: Deep Sentiment & Tone Classification
-- ============================================================================

/* 
NOTE:
Categorize the content based on the presence of keywords in the description field. 
Label content containing these keywords to understand overall genres. 
Count how many items fall into each category.
*/
WITH content_classification AS (
    SELECT 
        *,
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Contains Violence/Mature'
            WHEN description ILIKE '%love%' THEN 'Dramas & Romantic'
            WHEN description ILIKE '%comedy%' THEN 'Comedy Shows'
            WHEN description ILIKE '%crime%' THEN 'Crime & Detective'
            ELSE 'Other Genres/General'
        END AS strategic_category
    FROM netflix
)
SELECT 
    strategic_category,
    COUNT(*) AS total_content
FROM content_classification
GROUP BY strategic_category
ORDER BY total_content DESC;