defmodule DecoratorTest.Fixture.MonitoringDecorator do
  use Decorator.Define, some_decorator: 0

  def some_decorator(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorTest.Fixture.LoggingDecorator do
  use Decorator.Define, test_log: 0

  def test_log(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorTest.Fixture.TwoDecoratorsUsed do
  use DecoratorTest.Fixture.LoggingDecorator
  use DecoratorTest.Fixture.MonitoringDecorator

  @decorate some_decorator()
  def result(default \\ nil) do
    default
  end
end

defmodule DecoratorTest.MultipleDecoratorModules do
  use ExUnit.Case
  alias DecoratorTest.Fixture.TwoDecoratorsUsed

  test "module compiles and is not redefined" do
    assert {:ok, "tested"} == TwoDecoratorsUsed.result("tested")
    assert {:ok, nil} == TwoDecoratorsUsed.result()
  end
end
