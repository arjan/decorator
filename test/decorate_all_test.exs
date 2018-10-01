defmodule DecoratorDecorateAllTest.Fixture.MyDecorator do
  use Decorator.Define, some_decorator: 0

  def some_decorator(body, _context) do
    {:ok, body}
  end
end

defmodule DecoratorDecorateAllTest.Fixture.MyModule do
  use DecoratorDecorateAllTest.Fixture.MyDecorator

  @decorate_all some_decorator()

  def square(a) do
    a * a
  end

  def answer, do: 24

  def value123, do: 123

  def value666, do: 666


  def empty_body(a)

  def empty_body(10), do: 11
  def empty_body(n), do: n+2

end

defmodule DecoratorDecorateAllTest.Fixture.MyModuleWithAttribute do
  use DecoratorDecorateAllTest.Fixture.MyDecorator

  @decorate_all some_decorator()

  @custom_attr 15
  @custom_attr_map %{some_val: 3, other_val: 10}

  def fun1(x), do: x+2

  def fun2(x), do: x + @custom_attr

  def fun3(x), do: x + @custom_attr_map[:some_val]
end

defmodule DecoratorDecorateAllTest do
  use ExUnit.Case
  alias DecoratorDecorateAllTest.Fixture.MyModule
  alias DecoratorDecorateAllTest.Fixture.MyModuleWithAttribute

  test "decorate_all" do
    assert {:ok, 4} == MyModule.square(2)
    assert {:ok, 16} == MyModule.square(4)
    assert {:ok, 24} == MyModule.answer()
    assert {:ok, 123} == MyModule.value123()
    assert {:ok, 666} == MyModule.value666()
    assert {:ok, 11} == MyModule.empty_body(10)
    assert {:ok, 8} == MyModule.empty_body(6)
    assert {:ok, 10} == MyModuleWithAttribute.fun1(8)
    assert {:ok, 20} == MyModuleWithAttribute.fun2(5)
    assert {:ok, 8} == MyModuleWithAttribute.fun3(5)
  end
end
