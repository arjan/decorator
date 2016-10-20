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
function.

    ```elixir
    decorator()
    def my_function do
      # some expensive calculation...
    end
    ```
