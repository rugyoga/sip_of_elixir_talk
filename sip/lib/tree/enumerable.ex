defimpl Enumerable, for: Sip.Tree.TreeSet do
  @moduledoc """
  https://blog.brettbeatty.com/elixir/custom_data_structures/enumerable
  http://blog.plataformatec.com.br/2015/05/introducing-reducees/
  https://groups.google.com/g/elixir-lang-talk/c/zNMFKOA-I7c
  """
  @empty nil

  alias Sip.Tree.TreeSet

  @doc """
  Size

  ## Examples
      iex> TreeSet.new(1..7) |> Enum.count
      7
  """
  def count(%TreeSet{root: _, size: size}), do: {:ok, size}

  @doc """
  Test membership

  ## Examples
      iex> TreeSet.new([]) |> Enumerable.member?(2)
      {:ok, false}

      iex> TreeSet.new([2]) |> Enumerable.member?(2)
      {:ok, true}

      iex> TreeSet.new([3]) |> Enumerable.member?(2)
      {:ok, false}
  """
  def member?(%TreeSet{root: root}, target), do: {:ok, TreeSet.member_rec?(root, target)}

  @doc """
  Reducer

  ## Examples
      iex> TreeSet.new(1..7) |> Enum.map(fn i -> 2 * i end)
      [2, 4, 6, 8, 10, 12, 14]
      
      iex> TreeSet.new(1..7) |> Enum.take(4)
      [1, 2, 3, 4]

      iex> TreeSet.new(1..2) |> Enum.zip(11..13)
      [{1, 11}, {2, 12}]
      
      iex> 1..2 |> Enum.zip(TreeSet.new(11..13))
      [{1, 11}, {2, 12}]
  """

  def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(tree, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(tree, &1, fun)}
  def reduce(%TreeSet{root: root}, {:cont, _} = state, fun), do: reduce({root, []}, state, fun)

  def reduce({@empty, []}, {:cont, acc}, _fun), do: {:done, acc}

  def reduce({@empty, [{item, right} | as]}, {:cont, acc}, fun),
    do: reduce({right, as}, fun.(item, acc), fun)

  def reduce({{left, item, _, right}, as}, {:cont, acc}, fun),
    do: reduce({left, [{item, right} | as]}, {:cont, acc}, fun)

  @doc """
  Slicing

  ## Examples
      iex> {:ok, 7, slicer} = TreeSet.new(1..7) |> Enumerable.slice()
      ...> slicer.(2, 4)
      [3, 4, 5, 6]
  """
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
