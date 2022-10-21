
  create view "main"."teams__dbt_tmp" as (
    

SELECT
    S.visitorneutral AS team_long,
    R.team
FROM "main"."main_prep"."prep_schedule" S
LEFT JOIN "main"."main_prep"."prep_team_ratings" AS R ON R.team_long = S.visitorneutral
GROUP BY ALL
  );
