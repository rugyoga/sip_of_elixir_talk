defmodule SipTest do
  use ExUnit.Case
  doctest Sip

  test "greets the world" do
    assert Sip.hello() == :world
  end
end
