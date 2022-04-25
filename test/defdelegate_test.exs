defmodule DefdelegateTests.Fixture.MyDecorator do
  use Decorator.Define, plus_one: 0

  def plus_one(body, _context) do
    quote do
      unquote(body) + 1
    end
  end
end

defmodule DefdelegateTests.A do
  def value(x) do
    x
  end
end

defmodule DefdelegateTests.B do
  use DefdelegateTests.Fixture.MyDecorator

  @decorate plus_one()
  defdelegate value(x), to: DefdelegateTests.A
end

defmodule DefdelegateTests do
  use ExUnit.Case

  alias DefdelegateTests.B

  test "defdelegate should be decorated" do
    assert B.value(2) == 3
  end
end
