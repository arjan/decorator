# Elixir function decorators

A decorator is a macro which is executed while the function is
defined. It can be used to add extra functionality to Elixir
functions. The runtime overhead of a function decorator is zero, as it
is executed on compile time.

Examples of function decorators include: loggers, instrumentation
(timing), precondition checks, et cetera.


## Installation

Add `decorator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:decorator, "~> 0.0"}]
end
```

You can now define your function decorators.

## Usage

Function decorators are macros which you call just before defining a
function. It looks like this:

```elixir
decorator()
def my_function do
  # ...
end
```

Defining a decorator is pretty easy. Create a module in which you
*use* the `Decorator.Define` module, passing in the decorator name and
arity, or more than one if you want.

The following defines a print() decorator which prints a message every time the function is called:

```elixir
defmodule PrintDecorator do
  use Decorator.Define, [print: 0]

  def print(body, context) do
    quote do
      IO.puts("Function called: " <> Atom.to_string(unquote(context.name)))
      unquote(body)
    end
  end

end
```

Now, to use the `print()` decorator, you just `use PrintDecorator`:

```elixir
defmodule MyModule do
  use PrintDecorator

  print()
  def square(a) do
    a * a
  end
end
```

Now whenever you call `MyModule.square()`, you'll see the message: `Function called: square` in the console.
