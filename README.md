# NETFLIX MOVIES & TV SHOWS ANALYSIS BY USING SQL

![NetflixLogo](https://github.com/LukusArthur/Netflix_SQL_Project/blob/main/logo.jpg)

## Overview
The project entails conducting a thorough investigation of Netflix’s films and TV series using SQL. It aims at gathering useful insights and solving a variety of business issues from the dataset. Below is an extensive description of the objectives, business issues, solutions, insights, and conclusions of the project.

## Objectives
- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.
- 
## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schemas
```sql
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
```
Business Problems and Solutions
### 1. Count Content Volume & Audit Age-Inappropriate Ratings for US Market
Objective: Determine the distribution of content types on Netflix and count the availability of age-restricted materials.

```sql
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


```

**My Observation: I checked how many movies and TV shows are NOT appropriate for some age segmentations, especially for users Under 18. These specific movies and series should come from the United States.

### 2. Market Share Analysis - Most Common vs. Most Unpopular Ratings
**Objective:** Identify the top 5 most common ratings for both content types, as well as the top 5 rarest ratings.

```sql
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
```

**My Observation:** As we are to Find the most common Rating of those Content_Types, we have to Rank them in order to see which one is the top. We can't use MAX/MIN because those are text data types. Alternatively, finding the worst top 5 / "the most unpopular ratings of 2021" helps us prepare strategy changes to gain audiences for those specific segments.

### 3. 2021 Content Strategy & Niche Genre Penetration
**Objective:** Retrieve all movies released in a specific year (2021).

```sql

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
```

**My Observation Objective:** Calculate the absolute volume of mature content dropped in 2021 to effectively trace, isolate, and filter out entries that should not appear on restricted underage accounts.

### 4. Find the Top 5 Countries with the Most Content on Netflix
Objective: Identify the top 5 countries with the highest number of content items.

```sql
/* 
NOTE: 
By using STRING_TO_ARRAY, we will convert our string and put it inside a list, 
then UNNEST does the rest of the job by giving each row a separate value.
*/
SELECT 
    TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS country_origin,
    COUNT(show_id) AS total_content
FROM netflix
GROUP BY country_origin 
ORDER BY total_content DESC
LIMIT 5;
```
**My Observation Objective:** Convert comma-separated strings directly into lists using STRING_TO_ARRAY before leveraging UNNEST to isolate distinct geographic entries per row
almost forgot - TRIM() would remove some spaces that might have in those countries which might cause unexpected errors later on.

### 5. Identify the Longest Movie
**Objective:** Find the movie with the longest duration.
```sql
SELECT * 
FROM netflix
WHERE type = 'Movie' 
  AND duration = (SELECT MAX(duration) FROM netflix);
```
**My Observation Objective:** I used Subquery to find the longest duration of the movie 

### 6. Find Content Added in the Last 5 Years
**Objective:** Retrieve content added to Netflix across a rolling 5-year timeline backward from the maximum data capture point.

```sql
SELECT * 
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= (SELECT MAX(TO_DATE(date_added, 'Month DD, YYYY')) FROM netflix) - INTERVAL '5 years';
```

### 7. Directory Spotlight - Comprehensive Catalog for Toshiya Shinohara
**Objective:** List all content directed by a target director ('Toshiya Shinohara') across the platform.

```sql
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
```
**My Observation Objective:** Format text blocks into structured date metrics for seamless executive evaluation while applying ILIKE operators to safely ignore casing anomalies.

### 8. List All TV Shows with More Than 5 Seasons
**Objective:** Identify TV shows with more than 5 seasons.
```sql
SELECT * 
FROM netflix 
WHERE type = 'TV Show' 
  AND SPLIT_PART(duration, ' ', 1)::NUMERIC > 5;
```
**My Observation** I did use SPLIT_PART to serperate the numeric value and the text behind it. Or else I won't be able to filter down 

### 9. Count the Number of Content Items in Each Genre
**Objective:** Count the total number of content items distributed across individual genres.
```sql
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
```
**My Observation:** Some Movies And TV Shows are mixed with some shows and movies so we split then like we used to do in Query 4 and serperate them one by one then Make An Aggregation

### 10. Find Each Year and the Average Numbers of Content Released by United States on Netflix
**Objective:** Track annual catalog ingestion trends inside a target regional market.

```sql
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
```
**My Observation Objective:** Isolate calendar years directly from formatted text rows using EXTRACT to generate clear metrics indicating content ratios relative to the total US market space.

### 11. List All Movies that are Crime TV Shows
**Objective:** Retrieve all titles classified under the specific 'Crime TV Shows' descriptor.

```sql
SELECT * 
FROM netflix 
WHERE listed_in ILIKE '%Crime TV Shows%';
```
### 12. Find All Content Without a Director
**Objective:** List content rows that do not feature an assigned director.

```sql
SELECT * 
FROM netflix 
WHERE director IS NULL;
```
### 13. Find How Many Movies Actor 'Muhammad Ali' Appeared in Over the Last 10 Years
**Objective:** Count historical media appearances featuring a specified actor profile over a trailing 10-year block.
```sql
SELECT * 
FROM netflix
WHERE casts ILIKE '%Muhammad Ali%' 
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;
```

### 14. Star Power Analytics - Top 10 High-Volume Cast Members in the US
Objective: Identify the top 10 actors with the highest volume of cast appearances in localized productions.
```sql
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
```
**My Observation Objective:** Deconstruct dense multi-actor cast fields into distinct individual rows to accurately tabulate and rank isolated worker occurrences.

### 15. Deep Sentiment & Tone Classification
**Objective:** Categorize media entries using string-matching algorithms based on underlying log descriptions.

```sql
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
```

**My Observation Objective:** Design a dynamic, multi-tier conditional evaluation matrix using keyword lookups to successfully partition descriptions into detailed emotional buckets for high-level content analytics.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

- This is the end of the Project!
