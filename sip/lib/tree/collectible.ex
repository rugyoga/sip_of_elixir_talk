defimpl Collectable, for: Sip.Tree.TreeSet do
  alias Sip.Tree.TreeSet

  @doc """
  Test membership

  ## Examples
      iex> Enum.into([1, 3, 5, 7], TreeSet.build([2, 4, 6])) |> to_string()
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
  """
  def into(tree) do
    collector_fun = fn
      tree, {:cont, elem} -> TreeSet.put(tree, elem)
      tree, :done -> tree
      _list, :halt -> :ok
    end

    {tree, collector_fun}
  end
end
