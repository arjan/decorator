# two arguments
defmodule DecoratorTest.Fixture.TwoArgumentDecorator do
  use Decorator.Define, [two: 2]

  def two(one, two, body, _context) do
    quote do
      {unquote(one), unquote(two), unquote(body)}
    end
  end

end

defmodule DecoratorTest.Fixture.MyTwoFunctionTestModule do
  use DecoratorTest.Fixture.TwoArgumentDecorator

  @decorate two(1, 2)
  def result(a) do
    a
  end
end

defmodule DecoratorTest.Fixture.FunctionDocTestModule do
  use DecoratorTest.Fixture.TwoArgumentDecorator

  @doc "result function which does some things"
  def result(a) do
    a
  end

  @doc "result function which does some things"
  @decorate two(1, 2)
  def result2(a) do
    a
  end
end

defmodule DecoratorTest.TwoArgument do
  use ExUnit.Case
  alias DecoratorTest.Fixture.{
    MyTwoFunctionTestModule,
    FunctionDocTestModule
  }

  test "Two arguments" do
    assert {1, 2, 3} == MyTwoFunctionTestModule.result(3)
  end

  test "Functions with module doc" do
    assert 3 == FunctionDocTestModule.result(3)
    assert {1, 2, 3} == FunctionDocTestModule.result2(3)
  end
end
