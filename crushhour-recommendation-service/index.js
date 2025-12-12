const express = require("express");
const { BigQuery } = require("@google-cloud/bigquery");

const bigquery = new BigQuery();
const DATASET = "crushhour_ml";
const MF_MODEL = `${DATASET}.user_recs_mf`;
const RANKING_MODEL = `${DATASET}.ranking_dnn`;

const PORT = process.env.PORT || 3000;
const app = express();

app.use(express.json());

app.get("/recommendations", async (req, res) => {
  const uid =
    req.uid || req.query.uid || req.headers["x-user-id"] || req.headers["x-uid"];
  const limit = Number(req.query.limit || 50);

  if (!uid) {
    res.status(400).json({ error: "Missing uid" });
    return;
  }

  try {
    const query = `
      WITH candidates AS (
        SELECT user_id, other_user_id
        FROM ML.RECOMMEND(
          MODEL \`${MF_MODEL}\`,
          (SELECT @uid AS user_id)
        )
        WHERE other_user_id != @uid
        LIMIT 200
      ),
      features AS (
        SELECT
          c.user_id,
          c.other_user_id,
          up.age AS user_age,
          up.gender AS user_gender,
          up.country AS user_country,
          up.city AS user_city,
          op.age AS other_age,
          op.gender AS other_gender,
          op.country AS other_country,
          op.city AS other_city,
          0.0 AS interest_overlap,
          up.popularity_score AS user_popularity,
          op.popularity_score AS other_popularity
        FROM candidates c
        JOIN \`${DATASET}.user_profiles\` up ON up.user_id = c.user_id
        JOIN \`${DATASET}.user_profiles\` op ON op.user_id = c.other_user_id
      ),
      scored AS (
        SELECT
          f.user_id,
          f.other_user_id,
          p.predicted_label,
          p.predicted_label_probs[OFFSET(1)].prob AS match_prob
        FROM ML.PREDICT(
          MODEL \`${RANKING_MODEL}\`,
          TABLE features AS f
        ) AS p
      )
      SELECT other_user_id, match_prob
      FROM scored
      ORDER BY match_prob DESC
      LIMIT @limit
    `;

    const options = {
      query,
      params: { uid, limit },
    };

    const [job] = await bigquery.createQueryJob(options);
    const [rows] = await job.getQueryResults();

    const result = rows.map((r) => ({
      userId: r.other_user_id,
      score: r.match_prob,
    }));

    res.json(result);
  } catch (err) {
    console.error("Recommendation error:", err);
    res.status(500).json({ error: "Internal error" });
  }
});

app.listen(PORT, () => {
  console.log(`Recommendation service listening on port ${PORT}`);
});

module.exports = {
  app,
  bigquery,
  DATASET,
  MF_MODEL,
  RANKING_MODEL,
};
