defmodule Decorator.Define do

  defmacro __using__(decorators) do
    decorator_module = __CALLER__.module

    quote do
      @decorator_module unquote(decorator_module)
      @decorator_defs unquote(decorators)

      defmacro __using__(_) do
        sub = Module.concat(__CALLER__.module, Decorators)
        Module.create(sub, Decorator.Define.generate_at_macro(__CALLER__.module, __MODULE__), __CALLER__)

        Module.register_attribute(__CALLER__.module, :decorators, accumulate: true)

        quote do
          import Kernel, except: [@: 1, def: 2, defp: 2]
          import Decorator.Decorate, only: [def: 2, defp: 2]
          import unquote(sub), only: [@: 1]
        end

      end
    end

  end

  def generate_at_macro(outer_module, inner_module) do
    quote do
      defmacro @({:decorator, _, [{name, _, args}]}) do
        decorator = {unquote(inner_module), name, args}
        Module.put_attribute(unquote(outer_module), :decorators, decorator)
      end
      defmacro @({:decorator, _, args}) do
        raise ArgumentError, "Invalid argument for decorator annotation: #{inspect args}"
      end
      defmacro @({name, _, args}=a) do
        Decorator.KernelAtOverride.handle_at(__CALLER__, name, args)
      end
    end
  end

end
