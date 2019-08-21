defmodule Decorator.Define do
  @moduledoc false

  defmacro __using__(decorators) do
    decorator_module = __CALLER__.module

    decorator_macros =
      for {decorator, arity} <- decorators do
        arglist = Decorator.Decorate.generate_args(arity, decorator_module)

        quote do
          defmacro unquote(decorator)(unquote_splicing(arglist)) do
            if Module.get_attribute(__CALLER__.module, :decorate) != nil do
              raise ArgumentError, "Decorator #{unquote(decorator)} used without @decorate"
            end

            Macro.escape({unquote(decorator_module), unquote(decorator), unquote(arglist)})
          end
        end
      end

    quote do
      @decorator_module unquote(decorator_module)
      @decorator_defs unquote(decorators)

      unquote_splicing(decorator_macros)

      defmacro __using__(_) do
        imports =
          for {decorator, arity} <- @decorator_defs do
            quote do
              {unquote(decorator), unquote(arity)}
            end
          end

        quote do
          import unquote(@decorator_module), only: unquote(imports)

          if is_nil(Module.get_attribute(__MODULE__, :has_been_decorated)) do
            Module.register_attribute(__MODULE__, :has_been_decorated, accumulate: false)
            Module.put_attribute(__MODULE__, :has_been_decorated, true)

            Module.register_attribute(__MODULE__, :decorate_all, accumulate: true)
            Module.register_attribute(__MODULE__, :decorate, accumulate: true)
            Module.register_attribute(__MODULE__, :decorated, accumulate: true)

            @on_definition {Decorator.Decorate, :on_definition}
            @before_compile {Decorator.Decorate, :before_compile}
          end
        end
      end
    end
  end
end
