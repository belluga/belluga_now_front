// TODO(belluga): Define the full Favorite aggregate once backend exposes
// partner metadata, description, and actionable intents beyond the resume.
// For now we only surface FavoriteResume projections on tenant home, but
// controllers/repositories should plan to promote this placeholder into the
// canonical domain entity instead of creating screen-specific models.
class Favorite {
  const Favorite();

  // TODO(belluga): Add id, title, imagery, and engagement stats when the
  // Favorite aggregate is formalised. Keep ValueObjects for each field and
  // ensure repositories return this type as the primary contract.
}
