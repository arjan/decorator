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

    @decorator some_decorator
    def square(a) do
      a * a
    end

    @decorator some_decorator
    def answer, do: 24

    @value 123
    def value123, do: @value

    @value 666
    def value666, do: @value

  end

  test "basic function decoration" do
    assert 4 == MyModule.square(2)
    assert 16 == MyModule.square(4)
  end

  test "decorate function with no argument list" do
    assert 24 == MyModule.answer
  end

  test "normal module attributes should still work" do
    assert 123 == MyModule.value123
    assert 666 == MyModule.value666
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

    @decorator function_result(:ok)
    def square(a) do
      a * a
    end

    @decorator function_result(:error)
    def square_error(a) do
      a * a
    end

    @decorator function_result(:a)
    @decorator function_result("b")
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

    @decorator function_result(:ok)
    def foo(n) when is_number(n), do: n

    @decorator function_result(:error)
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

    @decorator is_authorized
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

  defmodule PrivateDecorated do
    use FunctionResultDecorator

    def pub(x), do: foo(x)

    @decorator function_result(:foo)
    defp foo(x), do: x
  end

  test "private functions can be decorated" do
    assert {:foo, :bar} == PrivateDecorated.pub(:bar)
  end


  test "should throw error when defining an unknown decorator" do

    definition = quote do
      use FunctionResultDecorator

      @decorator nonexisting
      def foo do
      end
    end

    assert_raise CompileError, fn ->
      Module.create(NonExistingDecoratorModule, definition, [file: "test.ex"])
    end
  end


  test "should throw error when defining an invalid decorator" do

    assert_raise ArgumentError, fn ->
      defmodule InvalidDecoratorModule do
        use FunctionResultDecorator

        @bar 33

        @decorator 1111111111111
        def foo do
        end
      end
    end

  end


end
