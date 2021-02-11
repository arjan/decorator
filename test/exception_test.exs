# two arguments
defmodule DecoratorTest.Fixture.ExceptionDecorator do
  use Decorator.Define, test: 0

  def test(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorTest.Fixture.ExceptionTestModule do
  use DecoratorTest.Fixture.ExceptionDecorator

  @decorate test()
  def rescued(a) do
    if a == :raise do
      raise RuntimeError, "text"
    end

    a
  rescue
    _ in RuntimeError -> :error
  end

  @decorate test()
  def catched(a) do
    if a == :throw do
      throw(a)
    end

    a
  catch
    _ -> :thrown
  end

  @decorate test()
  def rescued_and_catched(a) do
    case a do
      :throw -> throw(a)
      :raise -> raise RuntimeError, "text"
      a -> a
    end
  rescue
    _ in RuntimeError -> :error
  catch
    _ -> :thrown
  end
end

defmodule DecoratorTest.Exception do
  use ExUnit.Case

  alias DecoratorTest.Fixture.ExceptionTestModule

  test "Functions which have a 'rescue' clause" do
    assert {:ok, 3} = ExceptionTestModule.rescued(3)
    assert {:ok, :error} = ExceptionTestModule.rescued(:raise)
  end

  test "Functions which have a 'catch' clause" do
    assert {:ok, 3} = ExceptionTestModule.catched(3)
    assert {:ok, :thrown} = ExceptionTestModule.catched(:throw)
  end

  test "Functions which have a 'rescue' and a 'catch' clause" do
    assert {:ok, 3} = ExceptionTestModule.rescued_and_catched(3)
    assert {:ok, :thrown} = ExceptionTestModule.rescued_and_catched(:throw)
    assert {:ok, :error} = ExceptionTestModule.rescued_and_catched(:raise)
  end
end
