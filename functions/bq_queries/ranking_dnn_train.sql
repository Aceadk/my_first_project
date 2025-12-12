-- Train a DNN classifier for match likelihood using ranking_examples features.
CREATE OR REPLACE MODEL `crushhour_ml.ranking_dnn`
OPTIONS(
  model_type = 'dnn_classifier',
  input_label_cols = ['label'],
  auto_class_weights = TRUE,
  activation_fn = 'relu',
  learn_rate = 0.01,
  hidden_units = [128, 64, 32],
  early_stop = TRUE
) AS
SELECT
  label,
  user_age,
  user_gender,
  user_country,
  user_city,
  other_age,
  other_gender,
  other_country,
  other_city,
  interest_overlap,
  user_popularity,
  other_popularity
FROM `crushhour_ml.ranking_examples`;
