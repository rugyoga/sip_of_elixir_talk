defmodule Tree do
  def new(left, item, right), do: {left, item, weight(left) + weight(right) + 1, right}
  def empty, do: nil

  def weight(nil), do: 0
  def weight({_left, _item, size, _right}), do: size
  def left({l, _, _, _}), do: l
  def item({_, i, _, _}), do: i
  def right({_, _, _, r}), do: r

  def empty?(t), do: t == nil

  def insert(nil, item), do: new(empty(), item, empty())
  def insert({a, b, _w, c} = node, item) do
    cond do
      item < b -> new(insert(a, item), b, c) |> check_right_rotate
      item > b -> new(a, b, insert(c, item)) |> check_left_rotate
      true -> node
    end
  end

  def check_left_rotate({_, _, weight, c} = node) do
    if(2*weight(c) > weight(left(c)) + weight, do: left_rotate(node), else: node)
  end

  def check_right_rotate({a, _, weight, _} = node) do
    if(2*weight(a) > weight(right(a)) + weight, do: right_rotate(node), else: node)
  end

  def display(nil), do: "."
  def display(t), do: "(#{display(left(t))} #{item(t)} #{display(right(t))})"

  def left_rotate({a, b, _, {c, d, _, e}}), do: new(new(a, b, c), d, e)
  def right_rotate({{a, b, _, c}, d, _, e}), do: new(a, b, new(c, d, e))
end

Tree.empty
|> Tree.insert(4)
|> Tree.insert(2)
|> Tree.insert(6)
|> Tree.insert(1)
|> Tree.insert(3)
|> Tree.insert(5)
|> Tree.insert(7)
|> Tree.display
|> IO.inspect

Tree.empty
|> Tree.insert(1)
|> Tree.insert(2)
|> Tree.insert(3)
|> Tree.insert(4)
|> Tree.insert(5)
|> Tree.insert(6)
|> Tree.insert(7)
|> Tree.display
|> IO.inspect
