defmodule DecoratorTest.Fixture.MultipleClausesTestDecorator do
  use Decorator.Define, [test: 0]

  def test(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorTest.Fixture.MultipleClausesTestModule do
  use DecoratorTest.Fixture.MultipleClausesTestDecorator

  @decorate test()
  def result(1) do
    1
  end

  def result(2) do
    2
  end

  def result(n) do
    n*n
  end


end

defmodule DecoratorTest.MultipleClauses do
  use ExUnit.Case
  alias DecoratorTest.Fixture.MultipleClausesTestModule

  test "decorated function with multiple clauses" do
    assert {:ok, 1} == MultipleClausesTestModule.result(1)
    assert {:ok, 2} == MultipleClausesTestModule.result(2)
    assert {:ok, 25} == MultipleClausesTestModule.result(5)

  end

end
