# two arguments
defmodule DecoratorTest.Fixture.ExceptionDecorator do
  use Decorator.Define, [test: 0]

  def test(body, _context) do
    {:ok, body}
  end

end

defmodule DecoratorTest.Fixture.ExceptionTestModule do
  use DecoratorTest.Fixture.ExceptionDecorator

  @decorate test()
  def result(a) do
    if a == :throw do
      raise RuntimeError, "text"
    end
    a
  rescue
    _ in RuntimeError ->
      :error
  end
end

defmodule DecoratorTest.Exception do
  use ExUnit.Case

  alias DecoratorTest.Fixture.ExceptionTestModule

  test "Functions which have a 'rescue' clause" do
    assert {:ok, 3} = ExceptionTestModule.result(3)
    assert {:ok, :error} = ExceptionTestModule.result(:throw)
  end
end
