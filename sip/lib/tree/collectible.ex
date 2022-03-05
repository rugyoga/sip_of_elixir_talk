defimpl Collectable, for: Sip.Tree.TreeSet do
  alias Sip.Tree.TreeSet

  def into(tree) do
    collector_fun = fn
      list, {:cont, elem} -> [elem | list]
      list, :done -> TreeSet.build(list)
      _list, :halt -> :ok
    end

    {Enum.to_list(tree), collector_fun}
  end
end
