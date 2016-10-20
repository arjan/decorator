# Elixir function decorators

[![Build Status](https://travis-ci.org/arjan/decorator.png?branch=master)](https://travis-ci.org/arjan/decorator)
[![Hex pm](http://img.shields.io/hexpm/v/decorator.svg?style=flat)](https://hex.pm/packages/decorator)

A function decorator is an "`@`" annotation that sits in front
of a function definition.  It can be used to add extra functionality
to Elixir functions. The runtime overhead of a function decorator is
zero, as it is executed on compile time.

Examples of function decorators include: loggers, instrumentation
(timing), precondition checks, et cetera.


## Some remarks in advance

Some people think function decorators are a bad idea, as they can
perform magic stuff on your functions (side effects!). Personally, I
think they are just another form of metaprogramming, one of Elixir's
selling points. But use decorators wisely, and always study the
decorator code itself, so you know what it is doing.

**Note** When using decorators without arguments, Elixir warns you
with a message *warning: module attribute @some_decorator in code
block has no effect as it is never returned*. This is unfortunate but
cannot be prevented, as this warning is emitted in a very early stage
of compilation.


## Installation

Add `decorator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:decorator, "~> 0.0"}]
end
```

You can now define your function decorators.

## Usage

Function decorators are macros which you put just before defining a
function. It looks like this:

```elixir
defmodule MyModule do
  use PrintDecorator

  @print()
  def square(a) do
    a * a
  end
end
```

Now whenever you call `MyModule.square()`, you'll see the message: `Function called: square` in the console.

Defining the decorator is pretty easy. Create a module in which you
*use* the `Decorator.Define` module, passing in the decorator name and
arity, or more than one if you want.

The following declares the above `@print` decorator which prints a
message every time the decorated function is called:

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

The arguments to the decorator function (the `def print(...)`) are the
function's body (the AST), as well as a `context` argument which holds
information like the function's name, defining module, arity and the
arguments AST.


### Compile-time arguments

Decorators can have compile-time arguments passed into the decorator
macros.

For instance, you could let the print function only print when a
certain logging level has been set:

```elixir
@print(:debug)
def foo() do
...
```

In this case, you specify the arity 1 for the decorator:

```elixir
defmodule PrintDecorator do
  use Decorator.Define, [print: 1]
```

And then your `print()` decorator function gets the level passed in as
the first argument:

```elixir
def print(level, body, context) do
# ...
end
```
