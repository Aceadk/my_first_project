-- Build labeled ranking examples for model training.
CREATE OR REPLACE TABLE `crushhour_ml.ranking_examples` AS
WITH matches AS (
  SELECT DISTINCT
    user_id,
    other_user_id,
    TRUE AS label
  FROM `crushhour_ml.interaction_events`
  WHERE event_type = 'MATCH_CREATED'
),
negatives AS (
  -- Negative samples: swipes with no match
  SELECT DISTINCT
    e.user_id,
    e.other_user_id,
    FALSE AS label
  FROM `crushhour_ml.interaction_events` e
  LEFT JOIN matches m
    ON e.user_id = m.user_id
   AND e.other_user_id = m.other_user_id
  WHERE m.user_id IS NULL
    AND e.event_type = 'SWIPE_RIGHT'
  LIMIT 100000
),
base AS (
  SELECT * FROM matches
  UNION ALL
  SELECT * FROM negatives
),
features AS (
  SELECT
    b.label,
    b.user_id,
    b.other_user_id,
    up.age AS user_age,
    up.gender AS user_gender,
    up.country AS user_country,
    up.city AS user_city,
    op.age AS other_age,
    op.gender AS other_gender,
    op.country AS other_country,
    op.city AS other_city,
    -- compute interest overlap, distance, popularity, etc.
    ARRAY_LENGTH(
      ARRAY(
        SELECT DISTINCT i
        FROM UNNEST(up.interests) i
        INNER JOIN UNNEST(op.interests) j ON i = j
      )
    ) /
    NULLIF(
      ARRAY_LENGTH(
        ARRAY(
          SELECT DISTINCT i
          FROM UNNEST(up.interests) i
          UNION DISTINCT
          SELECT DISTINCT j
          FROM UNNEST(op.interests) j
        )
      ), 0
    ) AS interest_overlap,
    -- For distance, you can precompute approximate km as column or compute here.
    up.popularity_score AS user_popularity,
    op.popularity_score AS other_popularity
  FROM base b
  JOIN `crushhour_ml.user_profiles` up
    ON up.user_id = b.user_id
  JOIN `crushhour_ml.user_profiles` op
    ON op.user_id = b.other_user_id
)
SELECT * FROM features;
