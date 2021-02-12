# two arguments
defmodule DecoratorTest.Fixture.TryWrapperDecorator do
  use Decorator.Define, test: 0

  def test(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorTest.Fixture.TryWrapperTestModule do
  use DecoratorTest.Fixture.TryWrapperDecorator

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
  def try_after(a) do
    a
  after
    IO.write("after")
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

defmodule DecoratorTest.TryWrapper do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias DecoratorTest.Fixture.TryWrapperTestModule

  test "Functions which have a 'rescue' clause" do
    assert {:ok, 3} = TryWrapperTestModule.rescued(3)
    assert {:ok, :error} = TryWrapperTestModule.rescued(:raise)
  end

  test "Functions which have a 'catch' clause" do
    assert {:ok, 3} = TryWrapperTestModule.catched(3)
    assert {:ok, :thrown} = TryWrapperTestModule.catched(:throw)
  end

  test "Functions which have an 'after' clause" do
    assert capture_io(fn ->
             send(self(), TryWrapperTestModule.try_after(3))
           end) == "after"

    assert_received {:ok, 3}
  end

  test "Functions which have a 'rescue' and a 'catch' clause" do
    assert {:ok, 3} = TryWrapperTestModule.rescued_and_catched(3)
    assert {:ok, :thrown} = TryWrapperTestModule.rescued_and_catched(:throw)
    assert {:ok, :error} = TryWrapperTestModule.rescued_and_catched(:raise)
  end
end
