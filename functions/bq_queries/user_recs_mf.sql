-- Train a matrix factorization model for user-to-user recommendations using implicit feedback.
CREATE OR REPLACE MODEL `crushhour_ml.user_recs_mf`
OPTIONS(
  model_type = 'matrix_factorization',
  user_col = 'user_id',
  item_col = 'other_user_id',
  rating_col = 'implicit_score',
  feedback_type = 'implicit',
  num_factors = 64,
  l2_reg = 0.1,
  max_iterations = 20
) AS
SELECT
  user_id,
  other_user_id,
  implicit_score
FROM `crushhour_ml.user_user_implicit_ratings`;
