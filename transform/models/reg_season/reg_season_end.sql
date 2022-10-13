{{
  config(
    materialized = "view",
    post_hook = "COPY (SELECT * FROM {{ this }} ) TO '/tmp/storage/{{ this.table }}.parquet' (FORMAT 'parquet', CODEC 'ZSTD');"
) }}

WITH cte_wins AS (
  SELECT S.scenario_id, 
      S.winning_team,
      CASE 
        WHEN S.winning_team = S.home_team THEN S.home_conf
        ELSE S.visiting_conf
      END AS conf,
      CASE
        WHEN S.winning_team = S.home_team THEN S.home_team_elo_rating
        ELSE S.visiting_team_elo_rating
      END AS elo_rating,
      COUNT(1) as wins
  FROM {{ ref( 'reg_season_simulator' ) }} S
  GROUP BY ALL
),
cte_ranked_wins AS (
  SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY scenario_id, conf ORDER BY wins DESC, winning_team DESC ) as season_rank
  FROM cte_wins
  --no tiebreaker, so however row number handles order ties will need to be dealt with
),
cte_made_playoffs AS (
  SELECT *,
    CASE WHEN season_rank <= 10 THEN 1
      ELSE 0 
    END AS made_playoffs,
    CASE WHEN season_rank BETWEEN 7 AND 10 THEN 1
      ELSE 0
    END AS made_play_in,
    conf || '-' || season_rank::text AS seed
  FROM cte_ranked_wins 
)
SELECT * FROM cte_made_playoffs