-- Get top-N recommendations for a single user from the matrix factorization model.
SELECT
  *
FROM ML.RECOMMEND(
  MODEL `crushhour_ml.user_recs_mf`,
  (SELECT 'USER_ID_HERE' AS user_id)
)
WHERE other_user_id != 'USER_ID_HERE'
LIMIT 100;
