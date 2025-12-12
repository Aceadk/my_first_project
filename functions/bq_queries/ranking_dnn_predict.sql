-- Score candidate pairs with the trained ranking DNN.
SELECT
  other_user_id,
  predicted_label,
  predicted_label_probs[OFFSET(1)].prob AS match_prob
FROM ML.PREDICT(
  MODEL `crushhour_ml.ranking_dnn`,
  (SELECT * FROM `crushhour_ml.ranking_candidates_for_user`)
)
ORDER BY match_prob DESC
LIMIT 50;
