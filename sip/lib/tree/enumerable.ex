defimpl Enumerable, for: Sip.Tree.TreeSet do
  @empty nil

  alias Sip.Tree.TreeSet

  def count(%TreeSet{root: _, size: size}), do: {:ok, size}

  def member?(%TreeSet{root: root}, target), do: {:ok, TreeSet.member_rec?(root, target)}

  def reduce(%TreeSet{root: root}, state, fun), do: reduce_rec({root, []}, state, fun)

  def reduce_rec(_state, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce_rec(state, {:suspend, acc}, fun), do: {:suspended, acc, &reduce_rec(state, &1, fun)}
  def reduce_rec({@empty, []}, {:cont, acc}, _fun), do: {:done, acc}

  def reduce_rec({@empty, [{item, right} | as]}, {:cont, acc}, fun),
    do: reduce_rec({right, as}, fun.(item, acc), fun)

  def reduce_rec({{left, item, _, right}, as}, {:cont, acc}, fun),
    do: reduce_rec({left, [{item, right} | as]}, {:cont, acc}, fun)

  def slicer({_, _, acc}, 0, 0), do: acc |> Enum.reverse()

  def slicer({@empty, [{item, right} | stack], acc}, 0, n),
    do: slicer({right, stack, [item | acc]}, 0, n - 1)

  def slicer({{left, item, _, right}, stack, acc}, 0, n),
    do: slicer({left, [{item, right} | stack], acc}, 0, n)

  def slicer({@empty, [{_item, right} | stack], acc}, m, n),
    do: slicer({right, stack, acc}, m - 1, n)

  def slicer({{left, item, size, right}, stack, acc}, m, n) when size > m,
    do: slicer({left, [{item, right} | stack], acc}, m, n)

  def slicer({{_, _, size, _}, stack, acc}, m, n), do: slicer({@empty, stack, acc}, m - size, n)

  def slice(%TreeSet{root: root, size: size}) do
    slicer = fn start, n -> slicer({root, [], []}, start, n) end
    {:ok, size, slicer}
  end
end
