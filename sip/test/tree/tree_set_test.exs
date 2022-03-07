defmodule Sip.Tree.TreeSetTest do
  use ExUnit.Case, async: true

  alias Sip.Tree.TreeSet
  doctest TreeSet

  doctest Enumerable.Sip.Tree.TreeSet

  doctest Collectable.Sip.Tree.TreeSet
end
