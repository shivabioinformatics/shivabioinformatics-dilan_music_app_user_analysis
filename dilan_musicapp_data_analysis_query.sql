
/*
This queries does some 
explaratory analysis before making decisions what should be 
specifically explored
*/
SELECT
    tbl_users.name,
    tbl_users.email,
    tbl_mp3_views.mp3_id
FROM tbl_users
JOIN tbl_mp3_views
    ON tbl_users.id = tbl_mp3_views.view_id;


SELECT
    tbl_users.name,
    tbl_users.email,
    tbl_mp3.id
FROM tbl_users
JOIN tbl_mp3
    ON tbl_users.id = tbl_mp3.id;




/*
This query calculates the total number of favorites
for each user by counting the rows in tbl_favourite
where the is_favorite flag is set to 1.
*/


SELECT user_id,
       COUNT(*) AS total_favorites
FROM tbl_favourite
WHERE is_favorite = 1
GROUP BY user_id;



/*
 the query provides a list of users and the posts they have favorited, along 
 with a count of how many times each post was favorited (if multiple entries exist),
  and then organizes the list by user and the popularity of the posts.
*/

SELECT user_id,
       post_id,
       COUNT(*) AS times_favorited -- or 1 if only single favorites are stored
FROM tbl_favourite
WHERE is_favorite = 1
GROUP BY user_id, post_id
ORDER BY user_id, times_favorited DESC;




/*
This query returns a list of how many times each user (joined by name) 
has favorited each specific post. 
It only includes records where is_favorite = 1 
*/

SELECT 
  f.user_id,
  u.name AS user_name,
  f.post_id,
  COUNT(*) AS times_favorited
FROM tbl_favourite AS f
JOIN tbl_users AS u 
  ON f.user_id = u.id     -- 'id' in tbl_users matches 'user_id' in tbl_favourite
WHERE f.is_favorite = 1
GROUP BY 
  f.user_id, 
  u.name, 
  f.post_id
ORDER BY 
  f.user_id, 
  times_favorited DESC;

/*
Songs each user has favorited, along with song details

*/

SELECT
    f.user_id,
    u.name AS user_name,
    m.id AS mp3_id,
    m.mp3_title,
    m.mp3_artist,
    m.mp3_url,
    COUNT(*) AS times_favorited
FROM tbl_favourite f
JOIN tbl_users u 
    ON f.user_id = u.id           -- f.user_id matches u.id
JOIN tbl_mp3 m 
    ON f.post_id = m.id           -- f.post_id matches m.id
WHERE f.is_favorite = 1
  AND f.type = 'song'             -- Only consider favorites that are songs
GROUP BY
    f.user_id,
    u.name,
    m.id,
    m.mp3_title,
    m.mp3_artist,
    m.mp3_url
ORDER BY
    f.user_id,
    times_favorited DESC;




/*
This query retrieves a list of songs from the tbl_mp3 table (identified by m.mp3_title and m.mp3_artist), along with the total number of
 plays each song has received (calculated by summing the views column in tbl_mp3_views). It groups the results by mp3_id (so each song appears only once)
 and orders them
 in descending order of total plays. 
 Essentially, it shows you which songs have been played the most, from highest to lowest.
*/

SELECT 
  v.mp3_id,
  m.mp3_title,
  m.mp3_artist,
  SUM(v.views) AS total_plays
FROM tbl_mp3_views v
JOIN tbl_mp3 m 
   ON v.mp3_id = m.id
GROUP BY 
  v.mp3_id, 
  m.mp3_title, 
  m.mp3_artist
ORDER BY 
  total_plays DESC;

/*
Top 20 popular songs
*/

SELECT 
  v.mp3_id,
  m.mp3_title,
  m.mp3_artist,
  SUM(v.views) AS total_plays
FROM tbl_mp3_views v
JOIN tbl_mp3 m 
   ON v.mp3_id = m.id
GROUP BY 
  v.mp3_id, 
  m.mp3_title, 
  m.mp3_artist
ORDER BY 
  total_plays DESC
LIMIT 20;



SELECT 
    a.id AS artist_id,
    a.artist_name,
    SUM(v.views) AS total_views
FROM tbl_artist a
JOIN tbl_mp3 m ON m.artist_id = a.id
JOIN tbl_mp3_views v ON v.mp3_id = m.id
GROUP BY 
    a.id, 
    a.artist_name
ORDER BY 
    total_views DESC
LIMIT 10;


SELECT
    f.user_id,
    u.name AS user_name,
    m.id AS mp3_id,
    m.mp3_title,
    m.mp3_artist,
    m.mp3_url,
    m.total_views_new,       -- <== Include this column
    COUNT(*) AS times_favorited
FROM tbl_favourite f
JOIN tbl_users u 
    ON f.user_id = u.id
JOIN tbl_mp3 m 
    ON f.post_id = m.id
WHERE f.is_favorite = 1
  AND f.type = 'song'
GROUP BY
    f.user_id,
    u.name,
    m.id,
    m.mp3_title,
    m.mp3_artist,
    m.mp3_url,
    m.total_views_new        -- <== You need to include it in the GROUP BY if SQL mode requires it
ORDER BY
    f.user_id,
    times_favorited DESC;



/*
Which songs have the highest total_views_new 
(i.e., which are most viewed overall), you can run a 
query directly against the tbl_mp3 table and sort by total_views_new
*/

SELECT
  m.id AS mp3_id,
  m.mp3_title,
  m.mp3_artist,
  m.total_views_new
FROM tbl_mp3 m
ORDER BY m.total_views_new DESC
LIMIT 10;

/*
the top songs and top artists per user—that is, 
for each user, the song(s) (or artist(s)) that they have
 liked the most (or that have the most views)—you can extend 
 your current query using techniques such as window functions or 
 subqueries to “rank” the songs or aggregate by artist. Here are a 
 couple of approaches:
*/ 
SELECT
    user_id,
    user_name,
    mp3_id,
    mp3_title,
    mp3_artist,
    mp3_url,
    total_views_new,
    times_favorited
FROM (
    SELECT
        f.user_id,
        u.name AS user_name,
        m.id AS mp3_id,
        m.mp3_title,
        m.mp3_artist,
        m.mp3_url,
        m.total_views_new,
        COUNT(*) AS times_favorited,
        ROW_NUMBER() OVER (PARTITION BY f.user_id ORDER BY COUNT(*) DESC) AS rn
    FROM tbl_favourite f
    JOIN tbl_users u 
        ON f.user_id = u.id
    JOIN tbl_mp3 m 
        ON f.post_id = m.id
    WHERE f.is_favorite = 1
      AND f.type = 'song'
    GROUP BY
        f.user_id,
        u.name,
        m.id,
        m.mp3_title,
        m.mp3_artist,
        m.mp3_url,
        m.total_views_new
) AS ranked
WHERE rn = 1
ORDER BY user_id;


SELECT
    user_id,
    user_name,
    mp3_artist,
    SUM(times_favorited) AS total_favorites_for_artist
FROM (
    SELECT
        f.user_id,
        u.name AS user_name,
        m.mp3_artist,
        COUNT(*) AS times_favorited
    FROM tbl_favourite f
    JOIN tbl_users u 
        ON f.user_id = u.id
    JOIN tbl_mp3 m 
        ON f.post_id = m.id
    WHERE f.is_favorite = 1
      AND f.type = 'song'
    GROUP BY
        f.user_id,
        u.name,
        m.mp3_artist,
        m.id    -- if a user can favorite multiple songs by the same artist, we count each song
) AS artist_favs
GROUP BY
    user_id,
    user_name,
    mp3_artist
ORDER BY
    user_id,
    total_favorites_for_artist DESC;

/*
Top 3 artists per users, seems to be accurate so far, one moth old data though 
*/

WITH artist_favs AS (
    /* 1) Get raw counts of how many times each user has favorited each artist’s songs */
    SELECT
        f.user_id,
        u.name         AS user_name,
        u.email        AS user_email,
        m.mp3_artist   AS artist,
        COUNT(*)       AS times_favorited
    FROM tbl_favourite f
    JOIN tbl_users u 
        ON f.user_id = u.id
    JOIN tbl_mp3 m 
        ON f.post_id = m.id
    WHERE f.is_favorite = 1
      AND f.type = 'song'
    GROUP BY
        f.user_id,
        u.name,
        u.email,
        m.mp3_artist,
        m.id
), artist_agg AS (
    /* 2) Aggregate further so each (user, artist) has a single total_favorites_for_artist */
    SELECT
        user_id,
        user_name,
        user_email,
        artist,
        SUM(times_favorited) AS total_favorites_for_artist
    FROM artist_favs
    GROUP BY
        user_id,
        user_name,
        user_email,
        artist
), ranked AS (
    /* 3) Assign a rank to each artist per user, based on total favorites (descending) 
          Also compute total_favorites_for_user across all artists for that user */
    SELECT
        user_id,
        user_name,
        user_email,
        artist,
        total_favorites_for_artist,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY total_favorites_for_artist DESC
        ) AS rn,
        SUM(total_favorites_for_artist) OVER (
            PARTITION BY user_id
        ) AS total_favorites_for_user
    FROM artist_agg
)
SELECT
    user_id,
    user_name,
    user_email,
    /* Pivot the top 3 artists into columns */
    MAX(CASE WHEN rn = 1 THEN artist END) AS artist_1,
    MAX(CASE WHEN rn = 2 THEN artist END) AS artist_2,
    MAX(CASE WHEN rn = 3 THEN artist END) AS artist_3,
    /* Show total favorites across all artists (or rename to #_of_total_view) */
    MAX(total_favorites_for_user) AS "#_of_total_view"
FROM ranked
WHERE rn <= 3   /* Only need rows for the top 3 artists per user */
GROUP BY
    user_id,
    user_name,
    user_email
ORDER BY user_id;
