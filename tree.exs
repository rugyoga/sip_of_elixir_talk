defmodule Tree do
  def new(left, item, right), do: {left, item, right}
  def empty, do: nil

  def size(nil), do: 0
  def size({_left, _item, size, _right}), do: size
  def empty?(t), do: t == nil

  def insert(nil, item), do: new(empty(), item, empty())
  def insert({a, b, c}, item) when item < b, do: new(insert(a, item), b, c)
  def insert({a, b, c}, item) when item > b, do: new(a, b, insert(c, item))
  def insert(node, _item), do: node

  def display(nil), do: "."
  def display({a, b, c}), do: "(#{display(a)} #{b} #{display(c)})"
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
