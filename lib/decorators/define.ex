defmodule Decorators.Define do


  defmacro __using__(decorators) do
    decorator_module = __CALLER__.module

    decorator_macros = for {decorator, arity} <- decorators do
      arglist = if arity > 0 do
        for n <- 1..arity, do: Macro.var(String.to_atom("arg#{n}"), nil)
      else
        []
      end

      quote do
        defmacro unquote(decorator)(unquote_splicing(arglist)) do
          Module.put_attribute(__CALLER__.module, :decorate, {__MODULE__, unquote(decorator), [unquote_splicing(arglist)]})
        end
      end
    end

    quote do

      @decorator_module unquote(decorator_module)
      @decorator_defs unquote(decorators)

      unquote_splicing(decorator_macros)

      defmacro __using__(_) do

        imports = for {decorator, arity} <- @decorator_defs do
          quote do
            {unquote(decorator), unquote(arity)}
          end
        end

        Module.register_attribute(__CALLER__.module, :decorate, accumulate: true)

        quote do
          import Kernel, except: [def: 2]
          import Decorators.Decorate, only: [def: 2]

          import unquote(@decorator_module), only: unquote(imports)
        end
      end

    end
  end

end
