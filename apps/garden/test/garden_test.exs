defmodule GardenTest do
  use ExUnit.Case
  doctest Garden

  test "greets the world" do
    assert Garden.hello() == :world
  end
end
