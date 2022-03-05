defimpl String.Chars, for: Sip.Tree.TreeSet do
  @empty nil

  alias Sip.Tree.TreeSet

  def to_string(%TreeSet{root: root}),
    do: ["#TreeSet<", tree_to_iodata(root), ">"] |> IO.iodata_to_binary()

  defp tree_to_iodata(@empty), do: []

  defp tree_to_iodata({left, item, _, right}),
    do: ["(", tree_to_iodata(left), Kernel.to_string(item), tree_to_iodata(right), ")"]
end
