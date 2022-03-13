defmodule Sip.Tree.TreeSet do
  @moduledoc """
  TreeSet is a Set implemented using balanced binary trees - path length trees specifically.
  It implements the following protocols: Enumerable, Collectable and String.Chars.
  Conssequently you have access to every function in the Enum module.

  TODO implement range functions that leverage the ordered tree structure
  e.g. range(treeset, from, to) - iterate over elements of treeset from <= element <= to
  within?
  """
  alias Sip.Tree.TreeSet

  @empty nil

  defstruct size: 0, root: @empty

  @type size :: non_neg_integer()
  @type tree(item) :: {tree(item), item, size(), tree(item)} | nil
  @type t(item) :: %__MODULE__{size: non_neg_integer(), root: tree(item)}

  @spec wrap(tree(item)) :: t(item) when item: var
  def wrap(branch), do: %TreeSet{size: size(branch), root: branch}

  @spec new :: t(term)
  def new, do: wrap(@empty)

  def new(enumerable), do: build(enumerable)

  @doc """
  Creates TreeSet from an Enumerable by applying a transfrom first

  ## Examples
      iex> TreeSet.new(1..7, fn x -> 2 * x end) |> to_string()
      "#TreeSet<(((2)4(6))8((10)12(14)))>"
  """
  def new(enumerable, transform), do: build(Enum.map(enumerable, transform))

  def branch(left, item, right), do: {left, item, 1 + size(left) + size(right), right}
  def leaf(item), do: branch(@empty, item, @empty)

  @doc """
  Inserts item into a TreeSet

  ## Examples
      iex> TreeSet.new() |> TreeSet.put(1) |> to_string()
      "#TreeSet<(1)>"

      iex> TreeSet.new |> TreeSet.put(2) |> TreeSet.put(1) |> TreeSet.put(3) |> to_string()
      "#TreeSet<((1)2(3))>"

      iex> Enum.reduce(1..7, TreeSet.new, &TreeSet.put(&2, &1)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"

      iex> TreeSet.new() |> TreeSet.put(1) |> TreeSet.put(1) |> to_string()
      "#TreeSet<(1)>"
  """
  def put(%TreeSet{root: root}, item), do: item |> put_rec(root) |> wrap

  @spec put_rec(item, tree(item)) :: item when item: var
  defp put_rec(item, @empty), do: leaf(item)

  defp put_rec(item, {a, b, _w, c}) when item < b,
    do: branch(put_rec(item, a), b, c) |> check_right_rotate

  defp put_rec(item, {a, b, _w, c}) when item > b,
    do: branch(a, b, put_rec(item, c)) |> check_left_rotate

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
  def left_rotate(t),
    do: branch(branch(left(t), item(t), left(right(t))), item(right(t)), right(right(t)))

  @spec right_rotate(tree(item)) :: tree(item) when item: var
  def right_rotate(t),
    do: branch(left(left(t)), item(left(t)), branch(right(left(t)), item(t), right(t)))

  @spec check_left_rotate(tree(item)) :: tree(item) when item: var
  def check_left_rotate(t),
    do: if(size(right(right(t))) > size(left(t)), do: left_rotate(t), else: t)

  @spec check_right_rotate(tree(item)) :: tree(item) when item: var
  def check_right_rotate(t),
    do: if(size(left(left(t))) > size(right(t)), do: right_rotate(t), else: t)

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
  @type iterator(item) :: (() -> iterator_result(item))
  @type iterator_result(item) :: :done | {item, iterator(item)}

  @spec preorder(t(item)) :: iterator(item) when item: var
  def preorder(%TreeSet{root: root}), do: fn -> preorder_next({root, []}) end

  def preorder_next({@empty, []}), do: :done

  def preorder_next({@empty, [{item, right} | stack]}),
    do: {item, fn -> preorder_next({right, stack}) end}

  def preorder_next({{left, item, _, right}, stack}),
    do: preorder_next({left, [{item, right} | stack]})

  @spec postorder(t(item)) :: iterator(item) when item: var
  def postorder(%TreeSet{root: root}), do: fn -> postorder_next({root, []}) end

  def postorder_next({@empty, []}), do: :done

  def postorder_next({@empty, [{left, item} | stack]}),
    do: {item, fn -> postorder_next({left, stack}) end}

  def postorder_next({{left, item, _, right}, stack}),
    do: postorder_next({right, [{left, item} | stack]})

  @spec depthfirst(t(item)) :: iterator(item) when item: var
  def depthfirst(%TreeSet{root: root}), do: fn -> depthfirst_next({[root], []}) end

  def depthfirst_next({[], []}), do: :done
  def depthfirst_next({[], back}), do: depthfirst_next({Enum.reverse(back), []})

  def depthfirst_next({[{left, item, _, right} | front], back}),
    do: {item, fn -> depthfirst_next({front, back |> add_back(left) |> add_back(right)}) end}

  def add_back(queue, @empty), do: queue
  def add_back(queue, tree), do: [tree | queue]

  @doc """
  Deletes item from a TreeSet

  ## Examples
      iex> t = TreeSet.new(1..9)
      ...> t |> to_string()
      "#TreeSet<(((1)2(3(4)))5((6)7(8(9))))>"
      iex> t = t |> TreeSet.delete(7)
      ...> t |> to_string
      "#TreeSet<(((1)2(3(4)))5((6)8(9)))>"
      iex> t = t |> TreeSet.delete(5)
      ...> t |> to_string
      "#TreeSet<(((1)2(3))4((6)8(9)))>"

      iex> TreeSet.new |> TreeSet.delete(1) |> to_string
      "#TreeSet<>"

      iex> TreeSet.delete_rec(1, nil)
      nil

      iex> TreeSet.delete_rec(1, TreeSet.branch(TreeSet.leaf(1), 2, TreeSet.leaf(3)))
      {nil, 2, 2, {nil, 3, 1, nil}}

      iex> TreeSet.delete_rec(3, TreeSet.branch(TreeSet.leaf(1), 2, TreeSet.leaf(3)))
      {{nil, 1, 1, nil}, 2, 2, nil}
  """

  @spec delete(t(item), item) :: t(item) when item: var
  def delete(%TreeSet{root: root}, item), do: item |> delete_rec(root) |> wrap()

  @spec delete_rec(item, tree(item)) :: tree(item) when item: var
  def delete_rec(_item, @empty), do: @empty

  def delete_rec(item, {a, b, _w, c}) when item < b,
    do: branch(delete_rec(item, a), b, c) |> check_left_rotate

  def delete_rec(item, {a, b, _w, c}) when item > b,
    do: branch(a, b, delete_rec(item, c)) |> check_right_rotate

  def delete_rec(_, {a, _, _, @empty}), do: a
  def delete_rec(_, {@empty, _, _, c}), do: c

  def delete_rec(item, {left, item, _, right}) do
    if size(left) > size(right) do
      next = max(left)
      branch(delete_rec(next, left), next, right)
    else
      next = min(right)
      branch(left, next, delete_rec(next, right))
    end
  end

  @doc """
  Find the min

  ## Examples
      iex> TreeSet.min(TreeSet.branch(TreeSet.leaf(1), 2, TreeSet.leaf(3)))
      1
      iex> TreeSet.min(nil)
      nil
  """
  def min({@empty, item, _, _}), do: item
  def min({left, _, _, _}), do: min(left)
  def min(nil), do: nil

  @doc """
  Find the max

  ## Examples
      iex> TreeSet.max(TreeSet.branch(TreeSet.leaf(1), 2, TreeSet.leaf(3)))
      3
      iex> TreeSet.max(nil)
      nil
  """
  def max({_, item, _, @empty}), do: item
  def max({_, _, _, right}), do: max(right)
  def max(nil), do: nil

  @doc """
  Generate the difference of two sets

  ## Examples
      iex> TreeSet.difference(TreeSet.new(1..7), TreeSet.new(1..7)) |> to_string
      "#TreeSet<>"
      iex> TreeSet.difference(TreeSet.new(1..7), TreeSet.new(8..14)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> TreeSet.difference(TreeSet.new(8..14), TreeSet.new(1..7)) |> to_string
      "#TreeSet<(((8)9(10))11((12)13(14)))>"
      iex> TreeSet.difference(TreeSet.new(1..7), TreeSet.new(1..8)) |> to_string
      "#TreeSet<>"
  """
  @spec difference(t(item), t(item)) :: t(item) when item: var
  def difference(tree1, tree2), do: difference_rec(postorder(tree1).(), postorder(tree2).(), [])

  def difference_rec(:done, _, items), do: build(items, true)
  def difference_rec(a, :done, items), do: finish(a, items)

  def difference_rec({a_item, a_iter}, {b_item, _} = b, items) when a_item > b_item,
    do: difference_rec(a_iter.(), b, [a_item | items])

  def difference_rec({a_item, _} = a, {b_item, b_iter}, items) when a_item < b_item,
    do: difference_rec(a, b_iter.(), items)

  def difference_rec({_, a_iter}, {_, b_iter}, items),
    do: difference_rec(a_iter.(), b_iter.(), items)

  @doc """
  Tests two sets have distinct members

  ## Examples
      iex> TreeSet.disjoint?(TreeSet.new(1..7), TreeSet.new(1..7))
      false
      iex> TreeSet.disjoint?(TreeSet.new(1..7), TreeSet.new(8..14))
      true
      iex> TreeSet.disjoint?(TreeSet.new(8..14), TreeSet.new(1..7))
      true
      iex> TreeSet.disjoint?(TreeSet.new(1..8), TreeSet.new(8..14))
      false
  """
  def disjoint?(tree1, tree2), do: disjoint_rec(preorder(tree1).(), preorder(tree2).())

  def disjoint_rec(:done, _), do: true
  def disjoint_rec(_, :done), do: true

  def disjoint_rec({a_item, a_iter}, {b_item, _} = b_state) when a_item < b_item,
    do: disjoint_rec(a_iter.(), b_state)

  def disjoint_rec({a_item, _} = a_state, {b_item, b_iter}) when a_item > b_item,
    do: disjoint_rec(a_state, b_iter.())

  def disjoint_rec(_, _), do: false

  @doc """
  Tests two sets have the same members

  ## Examples
      iex> TreeSet.equal?(TreeSet.new([1]), TreeSet.new([1]))
      true
      iex> TreeSet.equal?(TreeSet.new([]), TreeSet.new([1]))
      false
      iex> TreeSet.equal?(TreeSet.new([1]), TreeSet.new([]))
      false
      iex> TreeSet.equal?(TreeSet.new([1]), TreeSet.new([2]))
      false
      iex> TreeSet.equal?(TreeSet.new(1..7), TreeSet.new(1..7))
      true
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
      iex> TreeSet.intersection(TreeSet.new([1]), TreeSet.new([1])) |> to_string
      "#TreeSet<(1)>"
      iex> TreeSet.intersection(TreeSet.new([1]), TreeSet.new([2])) |> to_string
      "#TreeSet<>"
      iex> TreeSet.intersection(TreeSet.new([2]), TreeSet.new([1])) |> to_string
      "#TreeSet<>"
      iex> TreeSet.intersection(TreeSet.new(1..7), TreeSet.new(1..8)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
      iex> TreeSet.intersection(TreeSet.new(1..8), TreeSet.new(1..7)) |> to_string
      "#TreeSet<(((1)2(3))4((5)6(7)))>"
  """
  def intersection(tree1, tree2),
    do: intersection_rec(postorder(tree1).(), postorder(tree2).(), [])

  def intersection_rec(:done, _, items), do: build(items, true)
  def intersection_rec(_, :done, items), do: build(items, true)

  def intersection_rec({a_item, a_iter}, {b_item, _} = b, items) when a_item > b_item,
    do: intersection_rec(a_iter.(), b, items)

  def intersection_rec({a_item, _} = a, {b_item, b_iter}, items) when a_item < b_item,
    do: intersection_rec(a, b_iter.(), items)

  def intersection_rec({item, a_iter}, {_, b_iter}, items),
    do: intersection_rec(a_iter.(), b_iter.(), [item | items])

  @doc """
  Tests all the members of the first set is contained in the second set

  ## Examples
      iex> TreeSet.subset?(TreeSet.new([1]), TreeSet.new([1]))
      true
      iex> TreeSet.subset?(TreeSet.new([1]), TreeSet.new([2]))
      false
      iex> TreeSet.subset?(TreeSet.new([2]), TreeSet.new([1]))
      false
      iex> TreeSet.subset?(TreeSet.new([]), TreeSet.new([1]))
      true
      iex> TreeSet.subset?(TreeSet.new([1]), TreeSet.new([]))
      false
  """
  def subset?(tree1, tree2), do: subset_rec(preorder(tree1).(), preorder(tree2).())

  def subset_rec(:done, _), do: true
  def subset_rec(_, :done), do: false
  def subset_rec({a_item, _}, {b_item, _}) when a_item < b_item, do: false

  def subset_rec({a_item, _} = a, {b_item, b_iter}) when a_item > b_item,
    do: subset_rec(a, b_iter.())

  def subset_rec({_, a_iter}, {_, b_iter}), do: subset_rec(a_iter.(), b_iter.())

  @doc """
  Generate the union of two sets

  ## Examples
      iex> TreeSet.union(TreeSet.new([1,2]), TreeSet.new([3])) |> to_string
      "#TreeSet<((1)2(3))>"
      iex> TreeSet.union(TreeSet.new([3]), TreeSet.new([1,2])) |> to_string
      "#TreeSet<((1)2(3))>"
      iex> TreeSet.union(TreeSet.new([2,3]), TreeSet.new([1,2])) |> to_string
      "#TreeSet<((1)2(3))>"
      iex> TreeSet.union(TreeSet.new([1,2]), TreeSet.new([2,3])) |> to_string
      "#TreeSet<((1)2(3))>"
  """
  def union(tree1, tree2), do: union_rec(postorder(tree1).(), postorder(tree2).(), [])

  def union_rec(:done, b, items), do: finish(b, items)
  def union_rec(a, :done, items), do: finish(a, items)

  def union_rec({a_item, a_iter}, {b_item, _} = b, items) when a_item > b_item,
    do: union_rec(a_iter.(), b, [a_item | items])

  def union_rec({a_item, _} = a, {b_item, b_iter}, items) when a_item < b_item,
    do: union_rec(a, b_iter.(), [b_item | items])

  def union_rec({item, a_iter}, {_, b_iter}, items),
    do: union_rec(a_iter.(), b_iter.(), [item | items])

  def finish(:done, items), do: build(items, true)
  def finish({item, iter}, items), do: finish(iter.(), [item | items])

  @doc """
  Size of set

  ## Examples
      iex> TreeSet.size(TreeSet.new(1..3))
      3
      iex> TreeSet.size(TreeSet.new)
      0
  """
  def size(%TreeSet{size: size}), do: size
  def size(@empty), do: 0
  def size({_, _, size, _}), do: size

  @doc """
  Left branch

  ## Examples
      iex> TreeSet.left(nil)
      nil
      iex> TreeSet.left({nil, 1, 1, nil})
      nil
      iex> TreeSet.left({{nil, 1, 1, nil}, 2, 3, {nil, 3, 1, nil}})
      {nil, 1, 1, nil}
  """
  def left({l, _item, _size, _right}), do: l
  def left(nil), do: @empty

  def item({_left, item, _size, _right}), do: item

  @doc """
  Right branch

  ## Examples
      iex> TreeSet.right(nil)
      nil
      iex> TreeSet.right({nil, 1, 1, nil})
      nil
      iex> TreeSet.right({{nil, 1, 1, nil}, 2, 3, {nil, 3, 1, nil}})
      {nil, 3, 1, nil}
  """
  def right({_left, _item, _size, r}), do: r
  def right(@empty), do: @empty

  @doc """
  Check for empty node

  ## Examples
      iex> TreeSet.empty?(TreeSet.new)
      true
      iex> TreeSet.empty?(TreeSet.new([1]))
      false
  """
  def empty?(%TreeSet{root: root}), do: root == @empty

  @doc """
  Tests membership

  ## Examples
      iex> TreeSet.member_rec?(TreeSet.leaf(2), 1)
      false
      iex> TreeSet.member_rec?(TreeSet.leaf(2), 2)
      true
      iex> TreeSet.member_rec?(TreeSet.leaf(2), 3)
      false
      iex> TreeSet.member_rec?(nil, 1)
      false
  """
  def member_rec?(@empty, _), do: false
  def member_rec?({left, item, _, _}, target) when target < item, do: member_rec?(left, target)
  def member_rec?({_, item, _, right}, target) when target > item, do: member_rec?(right, target)
  def member_rec?({_, item, _, _}, target) when target == item, do: true

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
    if(sorted, do: items, else: items |> Enum.uniq() |> Enum.sort())
    |> build_rec
    |> wrap
  end

  def build_rec(items), do: build_rec(items, Enum.count(items))
  def build_rec(_, 0), do: @empty

  def build_rec(items, n) do
    left_n = div(n - 1, 2)
    right_n = n - 1 - left_n
    [item | right] = Enum.drop(items, left_n)
    {build_rec(items, left_n), item, n, build_rec(right, right_n)}
  end
end
