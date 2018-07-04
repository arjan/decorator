defmodule DecoratorTest.Fixture.DecorateAllDecorator do
  use Decorator.Define, [some_decorator: 1]

  def some_decorator(message, body, _context) do
    quote do
      send self(), unquote(message)
      unquote(body)
    end
  end
end

defmodule DecoratorTest.Fixture.DecorateAllTestModule do
  use DecoratorTest.Fixture.DecorateAllDecorator

  @decorate_all some_decorator(:we_did_it)

  def fun_one do
    :ok
  end

  def fun_two do
    :ok
  end

  def fun_two(_arg1, something \\ :default)
  def fun_two(_arg1, something) do
    something
  end

  def fun_three("test_one") do
    :ok
  end

  def fun_three("test_two") do
    :ok
  end
end

defmodule DecorateAllTest do
  use ExUnit.Case

  alias DecoratorTest.Fixture.DecorateAllTestModule

  test "@decorate_all decorates all functions" do
    DecorateAllTestModule.fun_one()
    assert_received :we_did_it

    DecorateAllTestModule.fun_two()
    assert_received :we_did_it

    DecorateAllTestModule.fun_two("test_one")
    assert_received :we_did_it

    DecorateAllTestModule.fun_three("test_one")
    assert_received :we_did_it

    DecorateAllTestModule.fun_three("test_two")
    assert_received :we_did_it
  end
end
