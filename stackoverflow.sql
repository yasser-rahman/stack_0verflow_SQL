-- How many unique questions are there by each tag?
SELECT
  tag,
  COUNT(DISTINCT id) AS question_count
FROM
  `jrjames83-1171.sampledata.top_questions`
WHERE tag != 'undefined'
GROUP BY
  tag
ORDER BY
  question_count DESC
  /*********************************************************/
    -- Can a question belong To multiple tags?
SELECT
  title,
  COUNT(DISTINCT tag) AS n_tags
FROM
  `jrjames83-1171.sampledata.top_questions`
WHERE
  tag != 'undefined'
GROUP BY
  title
ORDER BY
  n_tags DESC
  /*********************************************************/

  SELECT
  title,
  ARRAY_AGG(DISTINCT tag) AS tags_list
FROM
  `jrjames83-1171.sampledata.top_questions`
WHERE
  tag != 'undefined'
GROUP BY
  title
  /***********************************************************/

  -- Find questions with more than two unique tags
SELECT
  title,
  COUNT(DISTINCT tag) AS n_tags
FROM
  `jrjames83-1171.sampledata.top_questions`
WHERE
  tag != 'undefined'
GROUP BY
  title
HAVING
  n_tags > 2

  /********************************************************/

    -- Find questions with more than two unique tags where the question was about Python
SELECT
  title,
  ARRAY_AGG(DISTINCT tag) AS tags_list
FROM
  `jrjames83-1171.sampledata.top_questions`
WHERE
  TRIM(LOWER(title)) LIKE '%python%'
GROUP BY
  title
HAVING
  ARRAY_LENGTH(tags_list) > 2
ORDER BY 
  ARRAY_LENGTH(tags_list) DESC

-- Subquery technique
SELECT
  subquery.title,
  subquery.tags_list
FROM (
  SELECT
    title,
    ARRAY_AGG(DISTINCT tag) AS tags_list
  FROM
    `jrjames83-1171.sampledata.top_questions`
  WHERE
    TRIM(LOWER(title)) LIKE '%python%'
  GROUP BY
    title) AS subquery
WHERE
  ARRAY_LENGTH(tags_list) > 2
ORDER BY
  ARRAY_LENGTH(tags_list) DESC

/*******************************************************/

  -- For each tag,  get me all questions associated with them
SELECT
  tag,
  ARRAY_AGG(DISTINCT title) AS associated_questions
FROM
  `jrjames83-1171.sampledata.top_questions`
GROUP BY
  tag

/*********************************************************/

 -- For each tag,  get me all questions associated with them
SELECT
  tag,
  COUNT(DISTINCT id) AS n_questions
FROM
  `jrjames83-1171.sampledata.top_questions`
GROUP BY
  tag
ORDER BY
  n_questions DESC
LIMIT
  10
  /**************************************************************/
    -- What is the average number of questions per tag?
WITH
  base_table AS (
  SELECT
    tag,
    COUNT(DISTINCT id) AS n_questions
  FROM
    `jrjames83-1171.sampledata.top_questions`
  GROUP BY
    tag )
SELECT
  AVG(base_table.n_questions) AS avg_questions_per_tag,
  MIN(base_table.n_questions) AS min_questions_per_tag,
  MAX(base_table.n_questions) AS MAX_questions_per_tag
FROM
  base_table
  /******************************************************/
   -- Which tags have < average number of questions?
WITH
  base_table AS 
    (
    SELECT
      tag,
      COUNT(DISTINCT id) AS n_questions
    FROM
      `jrjames83-1171.sampledata.top_questions`
    GROUP BY
      tag )
SELECT
  *
FROM
  base_table
WHERE
  base_table.n_questions < 
    (
      SELECT
        AVG(n_questions)
      FROM
        base_table)

/*******************************************************/

-- Language popularity based on title search ONLY
SELECT
  (CASE
    WHEN TRIM(LOWER(title)) LIKE '%java%'THEN 'Java'
    WHEN TRIM(LOWER(title)) LIKE '%python%'THEN 'Python'
    WHEN TRIM(LOWER(title)) LIKE '%sql%'THEN 'SQL'
    ELSE 'Other Language'
  END)   AS Language,
  COUNT(*) AS Popularity
FROM
  `jrjames83-1171.sampledata.top_questions`
GROUP BY
  1
ORDER BY
  2 DESC
  /*****************************************************/

  WITH
  base_table AS(
  SELECT
    DISTINCT id,
    title,
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT tag), " ") AS tag_string
  FROM
    `jrjames83-1171.sampledata.top_questions`
  GROUP BY
    1,
    2 ),
  language_table AS(
  SELECT
    CASE
      WHEN TRIM(LOWER(title)) LIKE '%java%'AND 
        TRIM(LOWER(tag_string)) LIKE '%java%' THEN 'Java_in_both'
      WHEN TRIM(LOWER(title)) LIKE '%java%'AND
         TRIM(LOWER(tag_string)) NOT LIKE '%java%' THEN 'Java_title_only'
      WHEN TRIM(LOWER(title)) NOT LIKE '%java%'AND
       TRIM(LOWER(tag_string)) LIKE '%java%' THEN 'Java_tag_only'
      WHEN TRIM(LOWER(title)) LIKE '%python%'AND
       TRIM(LOWER(tag_string)) LIKE '%python%' THEN 'Python_in_both'
      WHEN TRIM(LOWER(title)) LIKE '%python%'AND
       TRIM(LOWER(tag_string)) NOT LIKE '%python%' THEN 'Python_title_only'
      WHEN TRIM(LOWER(title)) NOT LIKE '%python%'AND
       TRIM(LOWER(tag_string)) LIKE '%python%' THEN 'Python_tag_only'
      WHEN TRIM(LOWER(title)) LIKE '%sql%'AND
       TRIM(LOWER(tag_string)) LIKE '%sql%' THEN 'SQL_in_both'
      WHEN TRIM(LOWER(title)) LIKE '%sql%'AND
       TRIM(LOWER(tag_string)) NOT LIKE '%sql%' THEN 'SQL_title_only'
      WHEN TRIM(LOWER(title)) NOT LIKE '%sql%'AND
       TRIM(LOWER(tag_string)) LIKE '%sql%' THEN 'SQL_tag_only'
    ELSE NULL
   END AS LANGUAGE,
    COUNT(*) AS Popularity
  FROM
    base_table
  GROUP BY 1 
   )
SELECT
  COALESCE(LANGUAGE, 'No_Match') AS LANGUAGE,
  Popularity
FROM
  language_table
ORDER BY
  1 DESC
/***********************************************************/
WITH
  base_table AS (
  SELECT
    DISTINCT
    CASE
      WHEN TRIM(LOWER(title)) LIKE '%python%' THEN 'Python'
      WHEN TRIM(LOWER(title)) LIKE '%java%' THEN 'Java'
      WHEN TRIM(LOWER(title)) LIKE '%sql%' THEN 'SQL'
      ELSE NULL
    END AS LANGUAGE,
    id,
    quarter,
    quarter_views
  FROM
    `jrjames83-1171.sampledata.top_questions` ),
  summary_table AS(
  SELECT
    LANGUAGE,
    EXTRACT(YEAR FROM quarter) AS year,
    SUM(quarter_views) AS views
  FROM
    base_table
  WHERE
    LANGUAGE IS NOT NULL
  GROUP BY
    LANGUAGE, year
  ORDER BY
    LANGUAGE, year DESC )
SELECT
  st.*,
  ROUND((views / LAG(views) OVER (PARTITION BY LANGUAGE ORDER BY year) - 1) * 100, 2) ||'%'      AS pct_change_yoy
FROM
  summary_table AS st


