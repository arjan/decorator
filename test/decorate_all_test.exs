defmodule DecoratorDecorateAllTest.Fixture.MyDecorator do
  use Decorator.Define, some_decorator: 0

  def some_decorator(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorDecorateAllTest.Fixture.MyModule do
  use DecoratorDecorateAllTest.Fixture.MyDecorator

  @decorate_all some_decorator()

  def square(a) do
    a * a
  end

  def answer, do: 24

  def value123, do: 123

  def value666, do: 666
end

defmodule DecoratorDecorateAllTest do
  use ExUnit.Case
  alias DecoratorDecorateAllTest.Fixture.MyModule

  test "decorate_all" do
    assert {:ok, 4} == MyModule.square(2)
    assert {:ok, 16} == MyModule.square(4)
    assert {:ok, 24} == MyModule.answer()
    assert {:ok, 123} == MyModule.value123()
    assert {:ok, 666} == MyModule.value666()
  end
end
