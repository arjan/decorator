defmodule Decorator.Define do

  defmacro __using__(decorators) do
    decorator_module = __CALLER__.module


    decorator_macros = for {decorator, arity} <- decorators do
      arglist = if arity > 0 do
        for _ <- 1..arity, do: Macro.var(:_, nil)
      else
        []
      end

      quote do
        defmacro unquote(decorator)(unquote_splicing(arglist)) do
          raise ArgumentError, "Decorator #{inspect unquote(decorator)} can only be used with the @decorate syntax"
        end
      end
    end

    quote do
      @decorator_module unquote(decorator_module)
      @decorator_defs unquote(decorators)

      unquote_splicing(decorator_macros)

      defmacro __using__(_) do
        sub = Module.concat(__CALLER__.module, Decorators)
        Module.create(sub, Decorator.Define.generate_at_macro(__CALLER__.module, __MODULE__), __CALLER__)

        Module.register_attribute(__CALLER__.module, :decorators, accumulate: true)


        imports = for {decorator, arity} <- @decorator_defs do
          quote do
            {unquote(decorator), unquote(arity)}
          end
        end

        quote do
          import Kernel, except: [@: 1, def: 2, defp: 2]
          import Decorator.Decorate, only: [def: 2, defp: 2]
          import unquote(sub), only: [@: 1]
          import unquote(@decorator_module), only: unquote(imports)
        end

      end
    end

  end

  def generate_at_macro(outer_module, inner_module) do
    quote do
      defmacro @({:decorate, _, [{name, _, args}]}) do
        decorator = {unquote(inner_module), name, args}
        Module.put_attribute(unquote(outer_module), :decorators, decorator)
      end
      defmacro @({:decorate, _, args}) do
        raise ArgumentError, "Invalid argument for decorator annotation: #{inspect args}"
      end
      defmacro @({name, _, args}=a) do
        Decorator.KernelAtOverride.handle_at(__CALLER__, name, args)
      end
    end
  end

end
