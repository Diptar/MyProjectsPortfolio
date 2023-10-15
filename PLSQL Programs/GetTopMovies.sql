-- Get top 10 movies by total revenue / Budget / movie likes
DROP FUNCTION IF EXISTS get_top_moviesinfo;
CREATE OR REPLACE FUNCTION get_top_moviesinfo(param_sort_coloumn CHARACTER VARYING,param_color TEXT,param_country TEXT[],param_release_year INT,limitrows INT DEFAULT 5)
RETURNS TABLE (
kpi_rnk BIGINT,
movie_title TEXT,
movie_rating TEXT ,
movie_genre TEXT,
movie_release_year TEXT,
movie_imdb_score FLOAT,
total_revenue NUMERIC,
total_budget NUMERIC,
total_likes BIGINT,
total_actor_likes BIGINT
)
AS 
$function$
BEGIN
RETURN QUERY
SELECT 
	CASE 
		 WHEN param_sort_coloumn = 'Budget' THEN bud_rnk
		 WHEN param_sort_coloumn = 'Revenue' THEN rev_rnk
		 WHEN param_sort_coloumn = 'Total movie likes' THEN movie_likes_rnk
		 WHEN param_sort_coloumn = 'Total actor likes' THEN actors_like_rnk
	END AS kpi_rnk,
	COALESCE(sub.title,'Total') title,
	sub.rating AS rating,sub.genre AS genre,sub.release_year AS release_year,sub.imdb_score AS imdb_score,
	sub.total_revenue AS total_revenue,
	sub.total_budget AS total_budget,
	sub.total_likes AS total_likes,
	sub.total_actor_likes AS total_actor_likes
FROM 
(
	SELECT 
	DENSE_RANK() OVER(ORDER BY SUM(gross_revenue) DESC) rev_rnk,
	DENSE_RANK() OVER(ORDER BY SUM(budget) DESC) bud_rnk,
	DENSE_RANK() OVER(ORDER BY SUM(movie_likes) DESC) movie_likes_rnk,
	DENSE_RANK() OVER(ORDER BY SUM(lead_actor_likes) DESC) actors_like_rnk,
	title,rating,genre,RIGHT(release_date,4) release_year,imdb_score,
	SUM(gross_revenue) total_revenue,
	SUM(budget) total_budget,
	SUM(movie_likes) total_likes,
	SUM(lead_actor_likes) total_actor_likes
	FROM imdb 
	WHERE total_reviews >= 100 -- AT LEAST 100 reviews ARE given TO that movie:
	AND imdb_score >= 6 -- AT LEAST 6
	AND color = param_color
	AND country = ANY(param_country)
	AND RIGHT(release_date,4)::INT =param_release_year
	GROUP BY ROLLUP (title ,rating,RIGHT(release_date,4),genre,imdb_score)
	HAVING (GROUPING(title) = 0 AND GROUPING(rating) = 0 AND GROUPING(RIGHT(release_date,4)) = 0 AND GROUPING(imdb_score) = 0)
			OR GROUPING(title) = 1 
) sub 
WHERE 
	CASE 
		 WHEN param_sort_coloumn = 'Budget' THEN bud_rnk <= limitrows + 1
		 WHEN param_sort_coloumn = 'Revenue' THEN rev_rnk <= limitrows + 1
		 WHEN param_sort_coloumn = 'Total movie likes' THEN movie_likes_rnk <= limitrows + 1
		 WHEN param_sort_coloumn = 'Total actor likes' THEN actors_like_rnk <= limitrows + 1
	END
ORDER BY
CASE WHEN param_sort_coloumn = 'Budget' THEN bud_rnk
	 WHEN param_sort_coloumn = 'Revenue' THEN rev_rnk
	 WHEN param_sort_coloumn = 'Total movie likes' THEN movie_likes_rnk
	 WHEN param_sort_coloumn = 'Total actor likes' THEN actors_like_rnk
END ; 
END;
$function$ LANGUAGE PLPGSQL ;

-- Calling the user defined function:
SELECT * 
FROM 
get_top_moviesinfo(
param_sort_coloumn => 'Revenue',
param_color => 'Color',
param_country => ARRAY['USA','UK'],
param_release_year => 2007,
limitrows => 10
);
