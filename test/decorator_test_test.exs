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
    use Decorators.Define, [instrument: 0]

    def __decorator_instrument(body, _context) do
      quote do
        IO.inspect("instrument!")
        unquote(body)
      end
    end

  end

  defmodule MyOtherDecorator do
    use Decorators.Define, [other: 1]

    def __decorator_other(name, body, _context) do
      IO.puts("other: #{name}")
      body
    end
  end


  defmodule MyModule do
    use MyDecorator
    use MyOtherDecorator

    instrument()
    other("meh")
    other("meh2")
    def hello() do
      IO.puts("Hello, world!")
    end

  end


  test "decoration" do
    MyModule.hello
    MyModule.hello
  end

end
