defmodule DecoratorTest.Fixture.ContextDecorator do
  use Decorator.Define, expose: 0
  alias Decorator.Decorate.Context

  def expose(body, %Context{arity: arity, module: module, name: name, kind: kind}) do
    quote do
      {%{
         arity: unquote(arity),
         module: unquote(module),
         name: unquote(name),
         kind: unquote(kind)
       }, unquote(body)}
    end
  end
end

defmodule DecoratorTest.Fixture.ContextModule do
  use DecoratorTest.Fixture.ContextDecorator

  @decorate expose()
  def result(a) do
    a
  end

  def public_sum(a, b) do
    private_sum(a, b)
  end

  @decorate expose()
  defp private_sum(a, b) do
    a + b
  end
end

defmodule DecoratorTest.Context do
  use ExUnit.Case, async: true
  alias DecoratorTest.Fixture.ContextModule

  test "exposes public function context" do
    assert {context, 3} = ContextModule.result(3)
    assert context == %{arity: 1, kind: :def, module: ContextModule, name: :result}
  end

  test "exposes private function context" do
    assert {context, 3} = ContextModule.public_sum(1, 2)
    assert context == %{arity: 2, kind: :defp, module: ContextModule, name: :private_sum}
  end
end
