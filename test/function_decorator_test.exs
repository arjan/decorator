# Example decorator which modifies the return value of the function
# by wrapping it in a tuple.
defmodule DecoratorTest.Fixture.FunctionResultDecorator do
  use Decorator.Define, [function_result: 1]

  def function_result(add, body, _context) do
    quote do
      {unquote(add), unquote(body)}
    end
  end
end

defmodule DecoratorTest.Fixture.MyFunctionResultModule do
  use DecoratorTest.Fixture.FunctionResultDecorator

  @decorate function_result(:ok)
  def square(a) do
    a * a
  end

  @decorate function_result(:error)
  def square_error(a) do
    a * a
  end

  @decorate function_result(:a)
  @decorate function_result("b")
  def square_multiple(a) do
    a * a
  end
end

defmodule DecoratorTest.Fixture.DecoratedFunctionClauses do
  use DecoratorTest.Fixture.FunctionResultDecorator

  @decorate function_result(:ok)
  def foo(n) when is_number(n), do: n

  @decorate function_result(:error)
  def foo(x), do: x
end

defmodule DecoratorTest.Fixture.DecoratedFunctionWithDifferentArities do
  use DecoratorTest.Fixture.FunctionResultDecorator

  @decorate function_result(:ok)
  def testfun(a,b) do a + b end
  @decorate function_result(:ok)
  def testfun(a) do a end

end

defmodule DecoratorTest.Fixture.DecoratedFunctionWithEmptyClause do
  use DecoratorTest.Fixture.FunctionResultDecorator

  @decorate function_result(:ok)
  def multiply(x, y \\ 1)

  def multiply(1, y) do y end
  def multiply(x, y) do x * y end
 end


defmodule DecoratorTest.Fixture.PrivateDecorated do
  use DecoratorTest.Fixture.FunctionResultDecorator

  def pub(x), do: foo(x)

  @decorate function_result(:foo)
  defp foo(x), do: x
end

# Tests itself
defmodule DecoratorTest.FunctionDecorator do
  use ExUnit.Case
  alias DecoratorTest.Fixture.{
    MyFunctionResultModule, 
    DecoratedFunctionClauses,
    DecoratedFunctionWithEmptyClause,
    DecoratedFunctionWithDifferentArities,
    FunctionResultDecorator,
    PrivateDecorated
  }

  test "test function decoration with argument, modify return value, multiple decorators" do
    assert {:ok, 4} == MyFunctionResultModule.square(2)
    assert {:error, 4} == MyFunctionResultModule.square_error(2)
    assert {"b", {:a, 4}} == MyFunctionResultModule.square_multiple(2)
  end

  test "decorating a function with many clauses" do
    assert {:ok, 22} == DecoratedFunctionClauses.foo(22)
    assert {:error, "string"} == DecoratedFunctionClauses.foo("string")
  end


  test "decorating a function with different arity heads" do
      assert {:ok, 3} == DecoratedFunctionWithDifferentArities.testfun(1,2)
      assert {:ok, 5} == DecoratedFunctionWithDifferentArities.testfun(5)

    end

  test "decorating a function with an empty clause" do
    assert {:ok, 11} == DecoratedFunctionWithEmptyClause.multiply(11)
    assert {:ok, 24} == DecoratedFunctionWithEmptyClause.multiply(6,4)
    assert {:ok, 5} == DecoratedFunctionWithEmptyClause.multiply(1,5)
  end


  test "should throw error when defining an unknown decorator" do
    definition = quote do
      use FunctionResultDecorator

      @decorate nonexisting()
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

        @decorate 1111111111111
        def foo do
        end
      end
    end
  end

  test "should throw error when using decorator macro outside @decorate" do
    assert_raise ArgumentError, fn ->
      defmodule InvalidDecoratorUseModule do
        use FunctionResultDecorator

        def foo do
          function_result(:bar)
        end
      end
    end
  end

  test "should throw error when using decorator wrong arity" do
    assert_raise CompileError, fn ->
      defmodule InvalidDecoratorArityUseModule do
        use FunctionResultDecorator

        @decorate function_result()
        def foo do
        end
      end
    end
  end

  test "private functions can be decorated" do
    assert {:foo, :bar} == PrivateDecorated.pub(:bar)
  end
end
