defmodule DecoratorTestTest do
  use ExUnit.Case
  doctest DecoratorTest


  # defmodule MyModule do
  #   use DecoratorTest

  #   decorate()
  #   def foo(bar) do
  #     bar + 1
  #   end

  #   def foo2(bar) do
  #     bar + 1
  #   end

  # end

  defmodule MyDecorator do
    use Decorators.Define, [:instrument, :private]

    defmacro __decorated(function) do
      function
    end
  end

  defmodule MyOtherDecorator do
    use Decorators.Define, [:other]

    defmacro __decorated(function) do
      function
    end
  end


  defmodule MyModule do
    use MyDecorator
    use MyOtherDecorator

    private()
    instrument()
    other()
    def hello() do
      IO.puts("Hello, world!")
    end

  end


  test "decoration" do
    MyModule.hello
    MyModule.hello
  end

end
