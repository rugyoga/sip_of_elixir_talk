#### EMPEX Abstract submission

## Elevator Pitch

We describe an efficient and novel implementation of Set based on balanced binary trees. The use of a binary tree allows for efficient implementation of range queries that are not natural or efficient for MapSet.

## Description

Maps provide very fast access but they do not retain order information.
Binary trees do not provide access as fast as a Map but they do retain order information.
So for range queries binary trees are a much better fit.
But Elixir doesn't have an Enum implementation of Set based on trees.
This talk describes such a class.
Code is available at:

https://github.com/rugyoga/sip_of_elixir_talk/blob/main/sip/lib/tree/tree_set.ex

## Notes

This implementation contains a novel, concise and elegant formulation of balanced binary trees in Elixir.
The key insight is that the fundamental building block of balanced tree algorithms is the rotation.
 
 ```
       d              b
      / \   right    / \
     b   E  ===>    A   d
    / \     <===       / \
   A   C    left      C   E
```

If we store the size of the sub tree as a field, it is easy to test whether a rotation is fruitful.
The path length of a tree is defined as the sum of the distance to the root  for every node.
So in the case of the left rotation, we are lifting subtree E up one level and lowering subtree A down by one level.
Thus if the size of E > size of A then we improve the path length of the overall tree.
This leads to the following sample code:

```elixir
  @type path_length :: non_neg_integer()
  @type tree(item) :: {tree(item), item, path_length(), tree(item)} | nil
  
  def size(@empty), do: 0
  def size({_, _, size, _}), do: size

  def left({l, _item, _size, _right}), do: l
  def left(nil), do: @empty
  
  def right({_left, _item, _size, r}), do: r
  def right(@empty), do: @empty

  def branch(left, item, right), do: {left, item, 1 + size(left) + size(right), right}
  def leaf(item), do: branch(@empty, item, @empty)

  @doc """
  Implement left and right rotations.
  Also implement conditional versions that only rotate if it improves the path length
(the following diagram needs a monospaced font to line up)

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

  def put(%TreeSet{root: root}, item), do: item |> put_rec(root) |> wrap

  @spec put_rec(item, tree(item)) :: item when item: var
  defp put_rec(item, @empty), do: leaf(item)

  defp put_rec(item, {a, b, _w, c}) when item < b,
    do: branch(put_rec(item, a), b, c) |> check_right_rotate

  defp put_rec(item, {a, b, _w, c}) when item > b,
    do: branch(a, b, put_rec(item, c)) |> check_left_rotate

  defp put_rec(_, t), do: t
```