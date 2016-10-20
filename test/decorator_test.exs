defmodule DecoratorTest do
  use ExUnit.Case

  defmodule MyDecorator do
    use Decorator.Define, [some_decorator: 0]

    def some_decorator(body, _context) do
      body
    end

  end

  defmodule MyModule do
    use MyDecorator

    @some_decorator
    def square(a) do
      a * a
    end
  end

  test "basic function decoration" do
    assert 4 == MyModule.square(2)
    assert 16 == MyModule.square(4)
  end



  # Example decorator which modifies the return value of the function
  # by wrapping it in a tuple.
  defmodule FunctionResultDecorator do
    use Decorator.Define, [function_result: 1]

    def function_result(add, body, _context) do
      quote do
        {unquote(add), unquote(body)}
      end
    end

  end

  defmodule MyFunctionResultModule do
    use FunctionResultDecorator

    @function_result(:ok)
    def square(a) do
      a * a
    end

    @function_result(:error)
    def square_error(a) do
      a * a
    end

    @function_result(:a)
    @function_result("b")
    def square_multiple(a) do
      a * a
    end
  end

  test "test function decoration with argument, modify return value, multiple decorators" do
    assert {:ok, 4} == MyFunctionResultModule.square(2)
    assert {:error, 4} == MyFunctionResultModule.square_error(2)
    assert {"b", {:a, 4}} == MyFunctionResultModule.square_multiple(2)
  end

  defmodule DecoratedFunctionClauses do
    use FunctionResultDecorator

    @function_result(:ok)
    def foo(n) when is_number(n), do: n

    @function_result(:error)
    def foo(x), do: x
  end

  test "decorating a function with many clauses" do
    assert {:ok, 22} == DecoratedFunctionClauses.foo(22)
    assert {:error, "string"} == DecoratedFunctionClauses.foo("string")
  end


  # Example decorator which uses one of the function arguments to
  # perform a precondition check.
  defmodule PreconditionDecorator do
    use Decorator.Define, [is_authorized: 0]

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

  defmodule MyIsAuthorizedModule do
    use PreconditionDecorator

    @is_authorized()
    def perform(conn) do
      :ok
    end
  end

  test "precondition decorator" do
    assert :ok == MyIsAuthorizedModule.perform(%{assigns: %{user: true}})
    assert_raise RuntimeError, fn ->
      MyIsAuthorizedModule.perform(%{assigns: %{user: false}})
    end

  end

end
