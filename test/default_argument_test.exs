defmodule DecoratorTest.Fixture.OptionalArgsTestDecorator do
  use Decorator.Define, test: 0

  def test(body, _context) do
    body
  end
end

defmodule DecoratorTest.Fixture.OptionalArgsTestModule do
  use DecoratorTest.Fixture.OptionalArgsTestDecorator

  @decorate test()
  def result(_aa, arg \\ nil) do
    {:ok, arg}
  end
end

defmodule DecoratorTest.DefaultArguments do
  use ExUnit.Case
  alias DecoratorTest.Fixture.OptionalArgsTestModule

  test "decorated function with optional args" do
    assert {:ok, nil} == OptionalArgsTestModule.result(1)
    assert {:ok, 1} == OptionalArgsTestModule.result(2, 1)
  end
end
