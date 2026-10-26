defmodule PR.WrappedTest do
  use PR.DataCase

  alias PR.Wrapped

  @year 2026

  defp at(day, hour \\ 10), do: NaiveDateTime.new!(@year, 3, day, hour, 0, 0)

  defp play(user, attrs) do
    insert(:track, Map.merge(%{user: user, played_at: DateTime.utc_now()}, attrs))
  end

  defp like(user, track, reason \\ :like),
    do: insert(:point, user: user, track: track, reason: reason)

  setup do
    alice = insert(:user, first_name: "Alice", last_name: "Smith")
    bob = insert(:user, first_name: "Bob", last_name: "Jones")
    # Alice's second account
    alice2 = insert(:user, first_name: "Alice", last_name: "Smith", merged_into_id: alice.id)

    a1 = play(alice, %{artist: "ABBA", external_id: "s1", inserted_at: at(2)})
    a2 = play(alice2, %{artist: "ABBA", external_id: "s2", inserted_at: at(2, 11)})
    b1 = play(bob, %{artist: "ABBA", external_id: "s1", inserted_at: at(3)})
    _last_year = play(bob, %{artist: "Air", inserted_at: ~N[2025-06-01 10:00:00]})

    like(bob, a1)
    like(bob, a2, :super_like)
    like(alice2, b1)

    %{alice: alice, alice2: alice2, bob: bob}
  end

  test "totals only count the year" do
    assert %{tracks: 3, people: 2, love: 3} = Wrapped.totals(Wrapped.range(@year))
    assert %{tracks: 1} = Wrapped.totals(Wrapped.range(@year - 1))
  end

  test "merged accounts count as one person", %{alice: alice, bob: bob} do
    people = Wrapped.person_stats(Wrapped.range(@year))

    assert [%{id: id, queued: 2, love_rx: 2, supers_rx: 1, given: 1}] =
             Enum.filter(people, &(&1.name == "Alice S"))

    assert id == alice.id
    assert %{queued: 1, love_rx: 1, given: 2} = Enum.find(people, &(&1.id == bob.id))
  end

  test "pairs and pair of the year", %{alice: alice, bob: bob} do
    pairs = Wrapped.pairs(Wrapped.range(@year))

    assert %{likes: 2, returned: 1} =
             Enum.find(pairs, &(&1.giver_id == bob.id and &1.receiver_id == alice.id))

    assert %{giver_id: g, receiver_id: r} = Wrapped.pair_of_the_year(pairs)
    assert Enum.sort([g, r]) == Enum.sort([alice.id, bob.id])
  end

  test "songs ranked by distinct queuers and novelty split" do
    range = Wrapped.range(@year)

    assert [%{plays: 2, queuers: 2} | _] = Wrapped.songs(range)
    # s1 first by Alice, again by Bob; s2 new
    assert %{true => %{plays: 2}, false => %{plays: 1}} = Wrapped.novelty_love(range)
  end

  test "all/2 renders the user's own year from a merged account", %{alice2: alice2, alice: alice} do
    assert %{you: %{me: %{id: id}}} = Wrapped.all(@year, alice2.id)
    assert id == alice.id
  end
end
