# A pretty meta-test that shows that decorators can be used inside
# ExUnit.

defmodule Decorator.TestFixture do
  use Decorator.Define, test_fixture: 0

  def test_fixture(body, _context) do
    quote do
      IO.puts("- before -")
      unquote(body)
      IO.puts("- after -")
    end
  end
end

defmodule DecorateExunitTests do
  use ExUnit.Case

  test "test decorating an exunit test" do
    # Let's compile a test module on the fly. We do this on the fly
    # because otherwise ExUnit runs the test case immediately. We need
    # to run it on-demand so we can that the decoration happened.

    Module.create(
      TheRealTestCase,
      quote do
        use ExUnit.Case
        use Decorator.TestFixture

        @decorate test_fixture()
        test "hello" do
          IO.puts("hi")
        end
      end,
      file: "nofile"
    )

    # ExUnit creates a function for each test case named "test " + the test case label.
    # The IO is captured, as the decorator (in this case) prints some stuff.

    output =
      ExUnit.CaptureIO.capture_io(fn ->
        assert :ok = apply(TheRealTestCase, :"test hello", [nil])
      end)

    # Verify that the decoration happened
    assert output == """
           - before -
           hi
           - after -
           """
  end
end
