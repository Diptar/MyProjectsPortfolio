-- Implementing Type 2 SCD:
CREATE OR REPLACE PROCEDURE load_to_movies_dim_type_two_scd()
LANGUAGE PLPGSQL 
AS 
$$
DECLARE 
	movie_rec RECORD;
BEGIN 
	FOR movie_rec IN 
	(SELECT 
	-- Source table columns:
	src.movie_id movie_id_src,
	src.title title_src,
	src.release_date release_date_src,
	src.color color_src,
	src.genre genre_src,
	src.lang lang_src,
	src.country country_src,
	src.rating rating_src,
	src.lead_actor lead_actor_src,
	src.director director_src,
	src.lead_actor_likes lead_actor_likes_src,
	src.cast_likes cast_likes_src,
	src.director_likes director_likes_src,
	src.movie_likes movie_likes_src,
	src.imdb_score imdb_score_src,
	src.total_reviews total_reviews_src,
	src.duration duration_src,
	src.gross_revenue gross_revenue_src,
	src.budget budget_src,
	-- Target table columns:
	tgt.movie_id movie_id_tgt,
	tgt.title title_tgt,
	tgt.release_date release_date_tgt,
	tgt.color color_tgt,
	tgt.genre genre_tgt,
	tgt.lang lang_tgt,
	tgt.country country_tgt,
	tgt.rating rating_tgt,
	tgt.lead_actor lead_actor_tgt,
	tgt.director director_tgt,
	tgt.lead_actor_likes lead_actor_likes_tgt,
	tgt.cast_likes cast_likes_tgt,
	tgt.director_likes director_likes_tgt,
	tgt.movie_likes movie_likes_tgt,
	tgt.imdb_score imdb_score_tgt,
	tgt.total_reviews total_reviews_tgt,
	tgt.duration duration_tgt,
	tgt.gross_revenue gross_revenue_tgt,
	tgt.budget budget_tgt
	FROM  
	movies_src src 
	LEFT JOIN 
	movies_dim tgt 
	ON src.movie_id = tgt.movie_id -- JOIN Based On Business Key:
	) LOOP 
		-- Insert record to target table if movie id is null in target:
		IF movie_rec.movie_id_tgt IS NULL THEN 
		INSERT INTO movies_dim VALUES (movie_rec.movie_id_src,movie_rec.title_src,movie_rec.release_date_src,
		movie_rec.color_src,movie_rec.genre_src,movie_rec.lang_src,movie_rec.country_src,movie_rec.rating_src,
		movie_rec.lead_actor_src,movie_rec.director_src,movie_rec.lead_actor_likes_src,movie_rec.cast_likes_src,
		movie_rec.director_likes_src,movie_rec.movie_likes_src,movie_rec.imdb_score_src,movie_rec.total_reviews_src,
		movie_rec.duration_src,movie_rec.gross_revenue_src,movie_rec.budget_src,CEIL(RANDOM()*3000000 + 10000)::INTEGER,TO_CHAR(CURRENT_DATE,'dd-Mon-yyyy'),'31-Dec-9999' );
		
		ELSE 
			IF movie_rec.genre_src <> movie_rec.genre_tgt OR movie_rec.rating_src <> movie_rec.rating_tgt OR movie_rec.imdb_score_src <> movie_rec.imdb_score_tgt OR movie_rec.gross_revenue_src <> movie_rec.gross_revenue_tgt THEN 
				-- Update the end date of historical record to current date
				UPDATE movies_dim SET end_date = TO_CHAR(CURRENT_DATE,'dd-Mon-yyyy') WHERE movie_id = movie_rec.movie_id_src ;
				-- Insert the new record:
				INSERT INTO movies_dim VALUES (movie_rec.movie_id_src,movie_rec.title_src,movie_rec.release_date_src,
				movie_rec.color_src,movie_rec.genre_src,movie_rec.lang_src,movie_rec.country_src,movie_rec.rating_src,
				movie_rec.lead_actor_src,movie_rec.director_src,movie_rec.lead_actor_likes_src,movie_rec.cast_likes_src,
				movie_rec.director_likes_src,movie_rec.movie_likes_src,movie_rec.imdb_score_src,movie_rec.total_reviews_src,
				movie_rec.duration_src,movie_rec.gross_revenue_src,movie_rec.budget_src,CEIL(RANDOM()*3000000 + 10000)::INTEGER,TO_CHAR(CURRENT_DATE,'dd-Mon-yyyy'),'31-Dec-9999' );
			END IF;
		END IF;
	END LOOP;
	RAISE NOTICE 'Type 2 SCD is applied on dimension table';
END;
$$

CALL load_to_movies_dim_type_two_scd();









