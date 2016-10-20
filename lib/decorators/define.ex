defmodule Decorator.Define do

  defmacro __using__(decorators) do
    decorator_module = __CALLER__.module

    quote do
      @decorator_module unquote(decorator_module)
      @decorator_defs unquote(decorators)

      defmacro __using__(_) do
        sub = Module.concat(__CALLER__.module, Decorators)
        Module.create(sub, Decorator.Define.generate_at_macro(@decorator_defs |> Enum.into(%{}), __CALLER__.module, __MODULE__), __CALLER__)

        Module.register_attribute(__CALLER__.module, :decorators, accumulate: true)

        quote do
          import Kernel, except: [@: 1, def: 2]
          import Decorator.Decorate, only: [def: 2]
          import unquote(sub), only: [@: 1]
        end

      end
    end

  end

  def generate_at_macro(decorators, outer_module, inner_module) do
    quote do
      defmacro @({name, _, args}) do
        if Map.has_key?(unquote(Macro.escape(decorators)), name) do
          Module.put_attribute(unquote(outer_module), :decorators, {unquote(inner_module), name, args})
          #IO.puts("defining decorator: #{name} #{inspect args} in #{__CALLER__.module}")
        else
          Decorator.KernelAtOverride.handle_at(__CALLER__, name, args)
        end
      end
    end
  end

end
