defmodule Sip.Tree.TreeSet do
  alias Sip.Tree.TreeSet

  @empty nil

  defstruct size: 0, root: @empty

  @type path_length :: non_neg_integer()
  @type tree(item) :: { tree(item), item, path_length(), tree(item) } | nil
  @type t(item) :: %__MODULE__{size: non_neg_integer(), root: tree(item)}

  @spec wrap(tree(item)) :: t(item) when item: var
  def wrap(branch), do: %TreeSet{ size: size(branch), root: branch }

  @spec new :: t(term)
  def new, do: wrap(@empty)


  def new(enumerable), do: build(enumerable)

  def new(enumerable, transform), do: build(Enum.map(enumerable, transform))

  def branch(left, item, right), do: {left, item, 1 + size(left) + size(right), right}
  def leaf(item), do: branch(nil, item, nil)

  @doc """
  Inserts item into a TreeSet

  ## Examples
      iex> TreeSet.new() |> TreeSet.put(1) |> to_string()
      "#TreeSet<(1)>"

      iex> TreeSet.new |> TreeSet.put(2) |> TreeSet.put(1) |> TreeSet.put(3) |> to_string()
      "#TreeSet<((1)2(3))>"

      iex> Enum.reduce(1..7, TreeSet.new, &TreeSet.put(&2, &1)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
  """
  def put(%TreeSet{root: root}, item) do
    new_root = put_rec(item, root)
    %TreeSet{ size: size(new_root), root: new_root}
  end

  @spec put_rec(item, tree(item)) :: item when item: var
  defp put_rec(item, nil), do: branch(nil, item, nil)
  defp put_rec(item, {a, b, _w, c}) when item < b, do: branch(put_rec(item, a), b, c) |> check_right_rotate
  defp put_rec(item, {a, b, _w, c}) when item > b, do: branch(a, b, put_rec(item, c)) |> check_left_rotate
  defp put_rec(_, t), do: t

  @doc """
  Implement left and right rotations.
  Also implement conditional versions that only rotate if it improves the path length
       d            b
      / \   right  / \
     b   E  ===>  A   d
    / \     <===     / \
   A   C    left    C   E

   right rotate? size(left(left(t)))   > size(right(t))
    left rotate? size(right(right(t))) > size(left(t))

  ## Examples
      iex> t1 = TreeSet.branch(TreeSet.leaf("a"), "b", TreeSet.branch(TreeSet.leaf("c"), "d", TreeSet.leaf("e")))
      ...> t2 = TreeSet.branch(TreeSet.branch(TreeSet.leaf("a"), "b", TreeSet.leaf("c")), "d", TreeSet.leaf("e"))
      ...> TreeSet.left_rotate(t1) == t2
      true
      iex> TreeSet.right_rotate(t2) == t1
      true
  """

  @spec left_rotate(tree(item)) :: tree(item) when item: var
  def left_rotate(t), do: branch(branch(left(t), item(t), left(right(t))), item(right(t)), right(right(t)))

  @spec right_rotate(tree(item)) :: tree(item) when item: var
  def right_rotate(t), do: branch(left(left(t)), item(left(t)), branch(right(left(t)), item(t), right(t)))

  @spec check_left_rotate(tree(item)) :: tree(item) when item: var
  def check_left_rotate(t), do: if(size(right(right(t))) > size(left(t)), do: left_rotate(t), else: t)

  @spec check_right_rotate(tree(item)) :: tree(item) when item: var
  def check_right_rotate(t), do: if(size(left(left(t))) > size(right(t)), do: right_rotate(t), else: t)

  @doc """
  Iterates over a TreeSet

  ## Examples
      iex> iter = TreeSet.build(1..7, true) |> TreeSet.preorder
      ...> {item, iter} = iter.()
      ...> item
      1
      iex> {item, iter} = iter.()
      ...> item
      2
      iex> {item, iter} = iter.()
      ...> item
      3
      iex> {item, iter} = iter.()
      ...> item
      4
      iex> {item, iter} = iter.()
      ...> item
      5
      iex> {item, iter} = iter.()
      ...> item
      6
      iex> {item, iter} = iter.()
      ...> item
      7
      iex> iter.()
      :done

      iex> iter = TreeSet.build(1..7, true) |> TreeSet.postorder
      ...> {item, iter} = iter.()
      ...> item
      7
      iex> {item, iter} = iter.()
      ...> item
      6
      iex> {item, iter} = iter.()
      ...> item
      5
      iex> {item, iter} = iter.()
      ...> item
      4
      iex> {item, iter} = iter.()
      ...> item
      3
      iex> {item, iter} = iter.()
      ...> item
      2
      iex> {item, iter} = iter.()
      ...> item
      1
      iex> iter.()
      :done

      iex> iter = TreeSet.build(1..7, true) |> TreeSet.depthfirst
      ...> {item, iter} = iter.()
      ...> item
      4
      iex> {item, iter} = iter.()
      ...> item
      2
      iex> {item, iter} = iter.()
      ...> item
      6
      iex> {item, iter} = iter.()
      ...> item
      1
      iex> {item, iter} = iter.()
      ...> item
      3
      iex> {item, iter} = iter.()
      ...> item
      5
      iex> {item, iter} = iter.()
      ...> item
      7
      iex> iter.()
      :done
  """
  @type iterator(item) :: (-> iterator_result(item))
  @type iterator_result(item) :: :done | {item, iterator(item)}

  @spec preorder(t(item)) :: iterator(item) when item: var
  def preorder(%TreeSet{root: root}), do: fn -> preorder_next({root, []}) end

  def preorder_next({nil, []}), do: :done
  def preorder_next({nil, [{item, right} | stack]}), do: {item, fn -> preorder_next({right, stack}) end}
  def preorder_next({{left, item, _, right}, stack}), do: preorder_next({left, [{item, right} | stack]} )

  @spec postorder(t(item)) :: iterator(item) when item: var
  def postorder(%TreeSet{root: root}), do: fn -> postorder_next({root, []}) end

  def postorder_next({nil, []}), do: :done
  def postorder_next({nil, [{left, item} | stack]}), do: {item, fn -> postorder_next({left, stack}) end}
  def postorder_next({{left, item, _, right}, stack}), do: postorder_next({right, [{left, item} | stack]})

  @spec depthfirst(t(item)) :: iterator(item) when item: var
  def depthfirst(%TreeSet{root: root}), do: fn -> depthfirst_next({[root], []}) end

  def depthfirst_next({[], []}), do: :done
  def depthfirst_next({[], back}), do: depthfirst_next({Enum.reverse(back), []})
  def depthfirst_next({[{left, item, _, right} | front], back}), do: {item, fn -> depthfirst_next({front, back |> add_back(left) |> add_back(right)}) end}
  def add_back(queue, nil), do: queue
  def add_back(queue, tree), do: [tree | queue]

  @doc """
  Deletes item from a TreeSet

  ## Examples
      iex> t = TreeSet.new(1..7)
      ...> t |> to_string()
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> t |> TreeSet.delete(1) |> to_string
      "#TreeSet<((2(3))4((5)6(7)))>"
      iex> t |> TreeSet.delete(2) |> to_string
      "#TreeSet<(((1)3)4((5)6(7)))>"
      iex> t |> TreeSet.delete(3) |> to_string
      "#TreeSet<(((1)2)4((5)6(7)))>"
      iex> t |> TreeSet.delete(4) |> to_string
      "#TreeSet<(((1)2(3))5(6(7)))>"
      iex> t |> TreeSet.delete(5) |> to_string
      "#TreeSet<(((1)2(3))4(6(7)))>"
      iex> t |> TreeSet.delete(6) |> to_string
      "#TreeSet<(((1)2(3))4((5)7))>"
      iex> t |> TreeSet.delete(7) |> to_string
      "#TreeSet<(((1)2(3))4((5)6))>"
  """

  @spec delete(t(item), item) :: t(item) when item: var
  def delete(%TreeSet{root: root}, item), do: item |> delete_rec(root) |> wrap()

  @spec delete_rec(item, tree(item)) :: tree(item) when item: var
  defp delete_rec(_item, nil), do: nil
  defp delete_rec(item, {a, b, _w, c}) when item < b, do: branch(delete_rec(item, a), b, c) |> check_left_rotate
  defp delete_rec(item, {a, b, _w, c}) when item > b, do: branch(a, b, delete_rec(item, c)) |> check_right_rotate
  defp delete_rec(_, {a, _, _, nil}), do: a
  defp delete_rec(_, {nil, _, _, c}), do: c
  defp delete_rec(item, {left, item, _, right}) do
    if size(left) > size(right) do
      next = rightmost(left)
      branch(delete_rec(next, left), next, right)
    else
      next = leftmost(right)
      branch(left, next, delete_rec(next, right))
    end
  end

  def leftmost({nil, item, _, _}), do: item
  def leftmost({left, _, _, _}), do: leftmost(left)

  def rightmost({_, item, _, nil}), do: item
  def rightmost({_, _, _, right}), do: rightmost(right)

  @doc """
  Generate the difference of two sets

  ## Examples
      iex> TreeSet.difference(TreeSet.new(1..7), TreeSet.new(1..7)) |> to_string
      "#TreeSet<>"
      iex> TreeSet.difference(TreeSet.new(1..7), TreeSet.new(8..14)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> TreeSet.difference(TreeSet.new(1..7), TreeSet.new(1..8)) |> to_string
      "#TreeSet<>"
  """
  @spec difference(t(item), t(item)) :: t(item) when item: var
  def difference(tree1, tree2), do: difference_rec(postorder(tree1).(), postorder(tree2).(), [])

  def difference_rec(:done, _, items), do: build(items, true)
  def difference_rec(a, :done, items), do: finish(a, items)
  def difference_rec({a_item, a_iter}, {b_item, _} = b, items) when a_item > b_item, do: difference_rec(a_iter.(), b, [a_item | items])
  def difference_rec({a_item, _} = a, {b_item, b_iter}, items) when a_item < b_item, do: difference_rec(a, b_iter.(), items)
  def difference_rec({_, a_iter}, {_, b_iter}, items), do: difference_rec(a_iter.(), b_iter.(), items)

  @doc """
  Tests two sets have distinct members

  ## Examples
      iex> TreeSet.disjoint?(TreeSet.new(1..7), TreeSet.new(1..7))
      false
      iex> TreeSet.disjoint?(TreeSet.new(1..7), TreeSet.new(8..14))
      true
      iex> TreeSet.disjoint?(TreeSet.new(1..8), TreeSet.new(8..14))
      false
  """
  def disjoint?(tree1, tree2), do: disjoint_rec(preorder(tree1).(), preorder(tree2).())

  def disjoint_rec(:done, _), do: true
  def disjoint_rec(_, :done), do: true
  def disjoint_rec({a_item, a_iter}, {b_item, _} = b_state) when a_item < b_item, do: disjoint_rec(a_iter.(), b_state)
  def disjoint_rec({a_item, _} = a_state, {b_item, b_iter}) when a_item > b_item, do: disjoint_rec(a_state, b_iter.())
  def disjoint_rec(_, _), do: false

  @doc """
  Tests two sets have the same members

  ## Examples
      iex> TreeSet.equal?(TreeSet.new(1..7), TreeSet.new(1..7))
      true
      iex> TreeSet.equal?(TreeSet.new(1..7), TreeSet.new(8..14))
      false
      iex> TreeSet.equal?(TreeSet.new(1..7), TreeSet.new(1..8))
      false
  """
  def equal?(tree1, tree2), do: equal_rec(preorder(tree1).(), preorder(tree2).())

  def equal_rec(:done, :done), do: true
  def equal_rec(:done, _), do: false
  def equal_rec(_, :done), do: false
  def equal_rec({a_item, _}, {b_item, _}) when a_item != b_item, do: false
  def equal_rec({_, a_iter}, {_, b_iter}), do: equal_rec(a_iter.(), b_iter.())

  @doc """
  Generate the intersection of two sets

  ## Examples
      iex> TreeSet.intersection(TreeSet.new(1..7), TreeSet.new(1..7)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> TreeSet.intersection(TreeSet.new(1..7), TreeSet.new(8..14)) |> to_string
      "#TreeSet<>"
      iex> TreeSet.intersection(TreeSet.new(1..7), TreeSet.new(1..8)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
  """
  def intersection(tree1, tree2), do: intersection_rec(postorder(tree1).(), postorder(tree2).(), [])

  def intersection_rec(:done, _, items), do: build(items, true)
  def intersection_rec(_, :done, items), do: build(items, true)
  def intersection_rec({a_item, a_iter}, {b_item, _} = b, items) when a_item > b_item, do: intersection_rec(a_iter.(), b, items)
  def intersection_rec({a_item, _} = a, {b_item, b_iter}, items) when a_item < b_item, do: intersection_rec(a, b_iter.(), items)
  def intersection_rec({item, a_iter}, {_, b_iter}, items), do: intersection_rec(a_iter.(), b_iter.(), [item | items])

  @doc """
  Tests all the members of the first set is contained in the second set

  ## Examples
      iex> TreeSet.subset?(TreeSet.new(1..7), TreeSet.new(1..7))
      true
      iex> TreeSet.subset?(TreeSet.new(1..7), TreeSet.new(8..14))
      false
      iex> TreeSet.subset?(TreeSet.new(1..7), TreeSet.new(1..8))
      true
  """
  def subset?(tree1, tree2), do: subset_rec(preorder(tree1).(), preorder(tree2).())

  def subset_rec(:done, _), do: true
  def subset_rec(_, :done), do: false
  def subset_rec({a_item, _}, {b_item, _}) when a_item < b_item, do: false
  def subset_rec({a_item, _} = a, {b_item, b_iter}) when a_item > b_item, do: subset_rec(a, b_iter.())
  def subset_rec({_, a_iter}, {_, b_iter}), do: subset_rec(a_iter.(), b_iter.())

  @doc """
  Generate the union of two sets

  ## Examples
      iex> TreeSet.union(TreeSet.new(1..7), TreeSet.new(1..7)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> TreeSet.union(TreeSet.new(1..4), TreeSet.new(5..7)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> TreeSet.union(TreeSet.new(1..7), TreeSet.new()) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
  """
  def union(tree1, tree2), do: union_rec(postorder(tree1).(), postorder(tree2).(), [])

  def union_rec(:done, b, items), do: finish(b, items)
  def union_rec(a, :done, items), do: finish(a, items)
  def union_rec({a_item, a_iter}, {b_item, _} = b, items) when a_item > b_item, do: union_rec(a_iter.(), b, [a_item | items])
  def union_rec({a_item, _} = a, {b_item, b_iter}, items) when a_item < b_item, do: union_rec(a, b_iter.(), [b_item | items])
  def union_rec({item, a_iter}, {_, b_iter}, items), do: union_rec(a_iter.(), b_iter.(), [item | items])

  def finish(:done, items), do: build(items, true)
  def finish({item, iter}, items), do: finish(iter.(), [item | items])

  def size(%TreeSet{size: size}), do: size
  def size(nil), do: 0
  def size({_, _, size, _}), do: size

  def left({left, _item, _size, _right}), do: left
  def left(nil), do: nil

  def item({_left, item, _size, _right}), do: item

  def right({_left, _item, _size, right}), do: right
  def right(nil), do: nil

  def empty?(nil), do: true
  def empty?(_), do: false

  def member?(nil, _), do: false
  def member?({left, item, _right}, target) when target < item, do: member?(left, target)
  def member?({_left, item, right}, target) when target > item, do: member?(right, target)
  def member?(_, _), do: true

  @doc """
  Builds a TreeSet from a collection item

  ## Examples
      iex> TreeSet.build([]) |> to_string
      "#TreeSet<>"

      iex> TreeSet.build([2,1,3]) |> to_string
      "#TreeSet<((1)2(3))>"

      iex> TreeSet.build([4,2,6,1,3,5,7]) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"

      iex> TreeSet.build(1..7, sorted: true) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
  """
  def build(items, sorted \\ false) do
    if(sorted, do: items, else: Enum.sort(items))
    |> build_rec(Enum.count(items))
    |> wrap
  end
  def build_rec(_, 0), do: nil
  def build_rec(items, n) do
    left_n = div(n-1, 2)
    right_n = n - 1 - left_n
    [item | right] = Enum.drop(items, left_n)
    {build_rec(items, left_n), item, n, build_rec(right, right_n)}
  end
end

defimpl Enumerable, for: Sip.Tree.TreeSet do
  alias Sip.Tree.TreeSet

  def count(%TreeSet{root: _, size: size}), do: {:ok, size}

  def member?(%TreeSet{root: root, size: _}, target), do: {:ok, TreeSet.member?(root, target)}

  def reduce(%TreeSet{root: root}, state, fun) do
    reduce_rec({root, []}, state, fun)
  end
  def reduce_rec(_list, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce_rec(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce_rec(list, &1, fun)}
  def reduce_rec({nil, []}, {:cont, acc}, _fun), do: {:done, acc}
  def reduce_rec({nil, [{ _, item, _size, right} | as]}, {:cont, acc}, fun), do: reduce_rec({right, as}, fun.(item, acc), fun)
  def reduce_rec({{left, _, _, _} = node, as}, {:cont, acc}, fun), do: reduce_rec({left, [node | as]}, {:cont, acc}, fun)

  def slicer({_, _, acc}, 0, 0), do: acc |> Enum.reverse()
  def slicer({nil, [{item, right} | stack], acc}, 0, n), do: slicer({right, stack, [item | acc]}, 0, n-1)
  def slicer({{left, item, _, right}, stack, acc}, 0, n), do: slicer({left, [{item, right} | stack], acc}, 0, n)
  def slicer({nil, [{_item, right} | stack], acc}, m, n), do: slicer({right, stack, acc}, m-1, n)
  def slicer({{left, item, size, right}, stack, acc}, m, n) when size > m, do: slicer({left, [{item, right} | stack], acc}, m, n)
  def slicer({{_, _, size, _}, stack, acc}, m, n), do: slicer({nil, stack, acc}, m-size, n)

  def slice(%TreeSet{root: root, size: size}) do
    slicer = fn start, n -> slicer({root, [], []}, start, n) end
    {:ok, size, slicer}
  end
end

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

defimpl String.Chars, for: Sip.Tree.TreeSet do
  alias Sip.Tree.TreeSet

  def to_string(%TreeSet{ root: root}), do: ["#TreeSet<", tree_to_iodata(root), ">"] |> IO.iodata_to_binary

  defp tree_to_iodata(nil), do: []
  defp tree_to_iodata({left, item, _, right}), do: ["(", tree_to_iodata(left), Kernel.to_string(item), tree_to_iodata(right), ")"]
end
