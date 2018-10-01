# Example decorator which uses one of the function arguments to
# perform a precondition check.
defmodule DecoratorTest.Fixture.PreconditionDecorator do
  use Decorator.Define, is_authorized: 0

  def is_authorized(body, %{args: [conn]}) do
    quote do
      if unquote(conn).assigns.user do
        unquote(body)
      else
        raise RuntimeError, "Not authorized!"
      end
    end
  end
end

defmodule DecoratorTest.Fixture.MyIsAuthorizedModule do
  use DecoratorTest.Fixture.PreconditionDecorator

  @decorate is_authorized()
  def perform(conn) do
    {:ok, conn}
  end
end

defmodule DecoratorTest.Precondition do
  use ExUnit.Case
  alias DecoratorTest.Fixture.MyIsAuthorizedModule

  test "precondition decorator" do
    assert {:ok, _} = MyIsAuthorizedModule.perform(%{assigns: %{user: true}})

    assert_raise RuntimeError, fn ->
      MyIsAuthorizedModule.perform(%{assigns: %{user: false}})
    end
  end
end
