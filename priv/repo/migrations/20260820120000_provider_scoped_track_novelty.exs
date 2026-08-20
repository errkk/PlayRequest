defmodule PR.Repo.Migrations.ProviderScopedTrackNovelty do
  use Ecto.Migration

  # track_novelty grouped by external_id alone, so two tracks from different
  # providers that happen to share an id pooled their play counts. recent_plays
  # already carries provider, so group and select on it too.

  def up do
    execute "DROP VIEW track_novelty"

    execute """
      CREATE VIEW track_novelty as (
        with track_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            external_id,
            provider
          from
            recent_plays
          group by
            external_id,
            provider
        )
        select
          external_id,
          provider,
          floor(100 - (un_novelty / (
            select max(un_novelty) from track_un_novelty
          ) * 100))::integer as track_novelty
        from
          track_un_novelty
      )
    """
  end

  def down do
    execute "DROP VIEW track_novelty"

    execute """
      CREATE VIEW track_novelty as (
        with track_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            external_id
          from
            recent_plays
          group by
            external_id
        )
        select
          external_id,
          floor(100 - (un_novelty / (
            select max(un_novelty) from track_un_novelty
          ) * 100))::integer as track_novelty
        from
          track_un_novelty
      )
    """
  end
end
