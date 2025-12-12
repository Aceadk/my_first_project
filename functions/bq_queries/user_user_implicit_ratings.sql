-- Recompute implicit interaction scores between users.
CREATE OR REPLACE TABLE `crushhour_ml.user_user_implicit_ratings` AS
SELECT
  user_id,
  other_user_id,
  SUM(rating) AS implicit_score
FROM (
  -- Swipe right
  SELECT
    user_id,
    other_user_id,
    2 AS rating
  FROM `crushhour_ml.interaction_events`
  WHERE event_type = 'SWIPE_RIGHT'

  UNION ALL

  -- Matches
  SELECT
    user_id,
    other_user_id,
    3 AS rating
  FROM `crushhour_ml.interaction_events`
  WHERE event_type = 'MATCH_CREATED'

  UNION ALL

  -- Profile views
  SELECT
    user_id,
    other_user_id,
    1 AS rating
  FROM `crushhour_ml.interaction_events`
  WHERE event_type = 'PROFILE_VIEW'
) AS x
GROUP BY user_id, other_user_id;
