defmodule PR.Wrapped do
  @moduledoc """
  End of year stats. Raw SQL because most of these lean on window functions
  and nested CTEs. Users with merged_into_id count as the account they point at.
  """

  alias PR.Repo

  @tz Application.compile_env(:pr, :timezone)

  # Every query starts with these. $1 and $2 bound the period being looked at;
  # tr and pt cover all time for queries that need history (novelty, firsts).
  @base """
  with tr as (
    select t.id, t.name, t.artist, t.provider, t.external_id, t.duration, t.img, t.inserted_at,
           t.inserted_at at time zone 'UTC' at time zone '#{@tz}' as local,
           coalesce(u.merged_into_id, u.id) as user_id
    from tracks t join users u on u.id = t.user_id
  ),
  pt as (
    select p.id, p.track_id, p.reason, coalesce(u.merged_into_id, u.id) as user_id
    from points p join users u on u.id = p.user_id
    where p.reason <> 'burn'
  ),
  people as (
    select id, trim(first_name) || coalesce(' ' || left(trim(last_name), 1), '') as name, image
    from users
  ),
  yr as (select * from tr where inserted_at >= $1 and inserted_at < $2)
  """

  def all(year, user_id) do
    this = range(year)
    ever = {~N[2000-01-01 00:00:00], elem(this, 1)}
    people = person_stats(this)
    pairs = pairs(this)
    twins = twins(this)
    active = MapSet.new(people, & &1.id)

    %{
      year: year,
      totals: totals(this),
      last_year: totals(range(year - 1)),
      ever: totals(ever),
      heatmap: heatmap(this),
      busiest_day: busiest_day(this),
      people: people,
      pair: pair_of_the_year(pairs),
      biggest_fans: pairs |> Enum.sort_by(& &1.likes, :desc) |> Enum.take(3),
      unreturned: pairs |> Enum.sort_by(&(&1.returned - &1.likes)) |> Enum.take(3),
      twins: Enum.take(twins, 3),
      old_twins:
        ever
        |> twins()
        |> Enum.reject(&(&1.a_id in active and &1.b_id in active))
        |> Enum.take(3),
      old_pair:
        ever
        |> pairs()
        |> Enum.reject(&(&1.giver_id in active and &1.receiver_id in active))
        |> pair_of_the_year(),
      songs: songs(this),
      anthems: songs(ever),
      loved_plays: loved_plays(this),
      artists: artists(this),
      owned_artists: owned_artists(this),
      top_artists: top_artists(this),
      novelty_love: novelty_love(this),
      quiet_days: quiet_days(this),
      solo_regulars: solo_regulars(this),
      heavy_rotation: heavy_rotation(this),
      longest: longest(this),
      you: you(user_id, people, pairs, twins)
    }
  end

  def range(year) do
    {NaiveDateTime.new!(year, 1, 1, 0, 0, 0), NaiveDateTime.new!(year + 1, 1, 1, 0, 0, 0)}
  end

  def totals(range) do
    """
    select count(*)::int as tracks,
           coalesce(round(sum(duration) / 3600000.0), 0)::int as hours,
           count(distinct user_id)::int as people,
           (select count(*) from pt join yr on yr.id = pt.track_id)::int as love
    from yr
    """
    |> query(range)
    |> hd()
  end

  def heatmap(range) do
    """
    select extract(isodow from local)::int as dow, extract(hour from local)::int as hour,
           count(*)::int as n
    from yr group by 1, 2
    """
    |> query(range)
  end

  def busiest_day(range) do
    """
    select local::date as day, count(*)::int as tracks, count(distinct user_id)::int as people
    from yr group by 1 order by 2 desc limit 1
    """
    |> query(range)
    |> List.first()
  end

  @doc "One row per person active in the period"
  def person_stats(range) do
    """
    , q as (select user_id, count(*) as queued from yr group by 1),
    rx as (
      select yr.user_id, count(*) as love_rx,
             count(*) filter (where pt.reason = 'super_like') as supers_rx
      from pt join yr on yr.id = pt.track_id group by 1
    ),
    gv as (select pt.user_id, count(*) as given from pt join yr on yr.id = pt.track_id group by 1),
    firsts as (
      select id, row_number() over (partition by provider, external_id order by inserted_at) = 1 as first_ever
      from tr
    ),
    nv as (
      select yr.user_id, round(100.0 * avg(firsts.first_ever::int))::int as pct_new
      from yr join firsts using (id) group by 1
    )
    select p.id, p.name, p.image,
           coalesce(q.queued, 0)::int as queued,
           coalesce(rx.love_rx, 0)::int as love_rx,
           coalesce(rx.supers_rx, 0)::int as supers_rx,
           coalesce(gv.given, 0)::int as given,
           nv.pct_new
    from people p
    left join q on q.user_id = p.id
    left join rx on rx.user_id = p.id
    left join gv on gv.user_id = p.id
    left join nv on nv.user_id = p.id
    where coalesce(q.queued, 0) + coalesce(gv.given, 0) > 0
    order by queued desc
    """
    |> query(range)
  end

  @doc "Likes from giver to receiver, with likes returned and how much the receiver queued"
  def pairs(range) do
    """
    , n as (select user_id, count(*) as n from yr group by 1),
    pr as (
      select pt.user_id as giver, yr.user_id as receiver, count(*) as likes
      from pt join yr on yr.id = pt.track_id
      where pt.user_id <> yr.user_id
      group by 1, 2
    )
    select g.id as giver_id, g.name as giver, g.image as giver_image,
           r.id as receiver_id, r.name as receiver, r.image as receiver_image,
           pr.likes::int, coalesce(back.likes, 0)::int as returned,
           n.n::int as receiver_tracks, coalesce(nb.n, 0)::int as giver_tracks
    from pr
    left join pr back on back.giver = pr.receiver and back.receiver = pr.giver
    join n on n.user_id = pr.receiver
    left join n nb on nb.user_id = pr.giver
    join people g on g.id = pr.giver
    join people r on r.id = pr.receiver
    """
    |> query(range)
  end

  # Both directions as a share of the other's tracks, geometric mean so it
  # needs to be mutual
  def pair_of_the_year(pairs) do
    pairs
    |> Enum.filter(&(&1.giver_id < &1.receiver_id and &1.returned > 0 and &1.giver_tracks > 0))
    |> Enum.max_by(
      &:math.sqrt(&1.likes / &1.receiver_tracks * (&1.returned / &1.giver_tracks)),
      fn -> nil end
    )
  end

  @doc "Jaccard similarity on artists queued, people with at least 15 artists"
  def twins(range) do
    """
    , ua as (select distinct user_id, lower(artist) as artist from yr),
    sizes as (select user_id, count(*) as n from ua group by 1 having count(*) >= 15),
    inter as (
      select a.user_id as x, b.user_id as y, count(*) as shared
      from ua a join ua b on a.artist = b.artist and a.user_id < b.user_id
      join sizes sa on sa.user_id = a.user_id
      join sizes sb on sb.user_id = b.user_id
      group by 1, 2
    )
    select px.id as a_id, px.name as a, px.image as a_image,
           py.id as b_id, py.name as b, py.image as b_image,
           i.shared::int, round(100.0 * i.shared / (sx.n + sy.n - i.shared))::int as pct
    from inter i
    join sizes sx on sx.user_id = i.x join sizes sy on sy.user_id = i.y
    join people px on px.id = i.x join people py on py.id = i.y
    order by pct desc limit 20
    """
    |> query(range)
  end

  @doc "Songs queued by the most different people"
  def songs(range) do
    """
    select name, artist, max(img) as img, count(*)::int as plays,
           count(distinct user_id)::int as queuers
    from yr group by provider, external_id, name, artist
    order by queuers desc, plays desc limit 5
    """
    |> query(range)
  end

  def loved_plays(range) do
    """
    select yr.name, yr.artist, yr.img, p.name as queued_by, yr.local::date as day,
           count(*) filter (where pt.reason = 'like')::int as likes,
           count(*) filter (where pt.reason = 'super_like')::int as supers
    from yr join pt on pt.track_id = yr.id join people p on p.id = yr.user_id
    group by yr.id, yr.name, yr.artist, yr.img, yr.local, p.name
    order by 3 * count(*) filter (where pt.reason = 'super_like')
             + count(*) filter (where pt.reason = 'like') desc
    limit 5
    """
    |> query(range)
  end

  def artists(range) do
    """
    select artist, count(*)::int as plays, count(distinct user_id)::int as queuers
    from yr group by artist order by queuers desc, plays desc limit 5
    """
    |> query(range)
  end

  @doc "Artists only one person played"
  def owned_artists(range) do
    """
    select p.name, p.image, yr.artist, count(*)::int as plays
    from yr join people p on p.id = yr.user_id
    group by p.name, p.image, yr.artist
    having count(*) >= 8
       and count(*) = (select count(*) from yr y2 where y2.artist = yr.artist)
    order by plays desc limit 5
    """
    |> query(range)
  end

  def top_artists(range) do
    """
    select distinct on (user_id) user_id, artist, count(*)::int as plays
    from yr group by user_id, artist order by user_id, plays desc
    """
    |> query(range)
    |> Map.new(&{&1.user_id, &1})
  end

  @doc "Love per play for songs never queued before vs ones the office knows"
  def novelty_love(range) do
    """
    , firsts as (
      select id, row_number() over (partition by provider, external_id order by inserted_at) = 1 as first_ever
      from tr
    ),
    love as (select track_id, count(*) as n from pt group by 1)
    select firsts.first_ever, count(*)::int as plays,
           round(coalesce(sum(love.n), 0)::numeric / count(*), 2)::float as love_per_play
    from yr join firsts using (id) left join love on love.track_id = yr.id
    group by 1
    """
    |> query(range)
    |> Map.new(&{&1.first_ever, &1})
  end

  @doc "SoundCloud share of plays, by how many people queued that day"
  def quiet_days(range) do
    """
    , days as (
      select local::date as day, count(distinct user_id) as people,
             count(*) filter (where provider = 'soundcloud') as sc, count(*) as total
      from yr group by 1
    )
    select case when people = 1 then 1 when people <= 3 then 2 when people <= 6 then 3 else 4 end as bucket,
           count(*)::int as days, round(100.0 * sum(sc) / sum(total), 1)::float as pct_soundcloud
    from days group by 1 order by 1
    """
    |> query(range)
  end

  def solo_regulars(range) do
    """
    , d as (
      select local::date as day, min(user_id) as user_id
      from yr group by 1 having count(distinct user_id) = 1
    )
    select p.name, p.image, count(*)::int as solo_days,
           count(*) filter (where extract(isodow from day) = 5)::int as fridays
    from d join people p on p.id = d.user_id
    group by p.name, p.image order by solo_days desc limit 3
    """
    |> query(range)
  end

  @doc "Most plays of one song inside any 3 week window"
  def heavy_rotation(range) do
    """
    , w as (
      select id, count(*) over (
        partition by provider, external_id order by inserted_at
        range between interval '21 days' preceding and current row
      ) as n
      from tr
    )
    select yr.name, yr.artist, max(yr.img) as img, max(w.n)::int as plays
    from yr join w using (id)
    group by yr.provider, yr.external_id, yr.name, yr.artist
    order by plays desc limit 1
    """
    |> query(range)
    |> List.first()
  end

  def longest(range) do
    """
    select yr.name, yr.artist, yr.img, yr.duration, p.name as queued_by
    from yr join people p on p.id = yr.user_id
    order by duration desc limit 1
    """
    |> query(range)
    |> List.first()
  end

  def you(user_id, people, pairs, twins) do
    user_id = canonical_id(user_id)

    case Enum.find(people, &(&1.id == user_id)) do
      nil ->
        nil

      me ->
        %{
          me: me,
          fan:
            pairs
            |> Enum.filter(&(&1.receiver_id == user_id))
            |> Enum.max_by(& &1.likes, fn -> nil end),
          twin: Enum.find(twins, &(user_id in [&1.a_id, &1.b_id]))
        }
    end
  end

  defp canonical_id(user_id) do
    case Repo.query!("select coalesce(merged_into_id, id) from users where id = $1", [user_id]) do
      %{rows: [[id]]} -> id
      _ -> user_id
    end
  end

  defp query(sql, {from, to}) do
    %{columns: columns, rows: rows} = Repo.query!(@base <> sql, [from, to])
    columns = Enum.map(columns, &String.to_atom/1)
    Enum.map(rows, &Map.new(Enum.zip(columns, &1)))
  end
end
