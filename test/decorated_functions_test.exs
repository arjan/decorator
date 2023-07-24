defmodule DecoratorTest.Fixture.NewDecorator do
  use Decorator.Define, new_decorator: 1

  def new_decorator(_arg, body, _context), do: body
end

defmodule DecoratorTest.Fixture.AnotherDecorator do
  use Decorator.Define, another_decorator: 2

  def another_decorator(_arg1, _arg2, body, _context), do: body
end

defmodule StructOne, do: defstruct([:a, :b])
defmodule StructTwo, do: defstruct([:c, :d])

defmodule DecoratorTest.Fixture.NewModule do
  use DecoratorTest.Fixture.NewDecorator
  use DecoratorTest.Fixture.AnotherDecorator

  @decorate new_decorator("one")
  def func(%StructOne{} = msg), do: msg.a

  @decorate new_decorator("two")
  @decorate another_decorator("a", "b")
  @decorate new_decorator("b")
  def func(%StructTwo{c: 2} = _msg), do: :ok
end

defmodule DecoratorTest.MyTest do
  use ExUnit.Case
  alias DecoratorTest.Fixture.NewModule

  test "Module with decorated functions are returned by `__decorated_functions__()" do
    assert %{
             {:func, ["%StructOne{} = msg"]} => [
               {DecoratorTest.Fixture.NewDecorator, :new_decorator, ["one"]}
             ],
             {:func, ["%StructTwo{c: 2} = _msg"]} => [
               {DecoratorTest.Fixture.NewDecorator, :new_decorator, ["two"]},
               {DecoratorTest.Fixture.AnotherDecorator, :another_decorator, ["a", "b"]},
               {DecoratorTest.Fixture.NewDecorator, :new_decorator, ["b"]}
             ]
           } == NewModule.__decorated_functions__()
  end
end
