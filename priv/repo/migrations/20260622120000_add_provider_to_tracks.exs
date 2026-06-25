defmodule PR.Repo.Migrations.AddProviderToTracks do
  use Ecto.Migration

  # Renames tracks.spotify_id -> external_id and adds a provider column so the
  # queue can hold tracks from more than one streaming service. The novelty
  # views select the renamed column, so they are dropped and recreated.

  def up do
    execute "DROP VIEW track_novelty"
    execute "DROP VIEW artist_novelty"
    execute "DROP VIEW recent_plays"

    drop unique_index(:tracks, [:spotify_id], name: :already_queued)

    rename table(:tracks), :spotify_id, to: :external_id

    alter table(:tracks) do
      add :provider, :string, null: false, default: "spotify"
    end

    create unique_index(:tracks, [:provider, :external_id],
             where: "played_at is null",
             name: :already_queued
           )

    recreate_views()
  end

  def down do
    execute "DROP VIEW track_novelty"
    execute "DROP VIEW artist_novelty"
    execute "DROP VIEW recent_plays"

    drop unique_index(:tracks, [:provider, :external_id], name: :already_queued)

    alter table(:tracks) do
      remove :provider
    end

    rename table(:tracks), :external_id, to: :spotify_id

    create unique_index(:tracks, [:spotify_id], where: "played_at is null", name: :already_queued)

    recreate_legacy_views()
  end

  defp recreate_views do
    execute """
      CREATE VIEW recent_plays as (
        select
          t.external_id,
          t.provider,
          t.name,
          t.artist,
          floor(
            (
              extract(
                epoch
                from
                  t.inserted_at - (now() - interval '3 week')
              )
            ) / 36000
          ) as recency
        from
          tracks t
        where
          t.inserted_at > now() - interval '3 week'
          and t.played_at is not null
        order by
          recency desc
      )
    """

    execute """
      CREATE VIEW artist_novelty as (
        with artist_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            artist
          from
            recent_plays
          group by
            artist
        )
        select
          artist,
          floor(100 - (un_novelty / (
            select max(un_novelty) from artist_un_novelty
          ) * 100))::integer as artist_novelty
        from
          artist_un_novelty
      )
    """

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

  defp recreate_legacy_views do
    execute """
      CREATE VIEW recent_plays as (
        select
          t.spotify_id,
          t.name,
          t.artist,
          floor(
            (
              extract(
                epoch
                from
                  t.inserted_at - (now() - interval '3 week')
              )
            ) / 36000
          ) as recency
        from
          tracks t
        where
          t.inserted_at > now() - interval '3 week'
          and t.played_at is not null
        order by
          recency desc
      )
    """

    execute """
      CREATE VIEW artist_novelty as (
        with artist_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            artist
          from
            recent_plays
          group by
            artist
        )
        select
          artist,
          floor(100 - (un_novelty / (
            select max(un_novelty) from artist_un_novelty
          ) * 100))::integer as artist_novelty
        from
          artist_un_novelty
      )
    """

    execute """
      CREATE VIEW track_novelty as (
        with track_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            spotify_id
          from
            recent_plays
          group by
            spotify_id
        )
        select
          spotify_id,
          floor(100 - (un_novelty / (
            select max(un_novelty) from track_un_novelty
          ) * 100))::integer as track_novelty
        from
          track_un_novelty
      )
    """
  end
end
