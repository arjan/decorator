defmodule Decorators.Define do

  defmacro __using__(decorators) do
    decorator_module = __CALLER__.module

    decorator_macros = for decorator <- decorators do
      quote do
        defmacro unquote(decorator)() do
          Module.put_attribute(__CALLER__.module, :decorate, {__MODULE__, unquote(decorator)})
        end
      end
    end

    quote do

      @decorator_module unquote(decorator_module)
      @decorator_names unquote(decorators)

      unquote_splicing(decorator_macros)

      defmacro __using__(_) do

        imports = for decorator <- @decorator_names do
          quote do
            {unquote(decorator), 0}
          end
        end

        Module.register_attribute(__CALLER__.module, :decorate, accumulate: true)

        quote do
          import Kernel, except: [def: 2]
          import Decorators.Define, only: [def: 2]

          import unquote(@decorator_module), only: unquote(imports)
        end
      end

    end
  end

  defmacro def(fn_call_ast, fn_opts_ast \\ nil) do

    mod = __CALLER__.module
    IO.puts "mod: #{inspect mod}"

    {fn_name, _, _} = fn_call_ast
    decorator = Module.get_attribute(mod, :decorate)
    if decorator do
      IO.puts "Decorate function: #{mod}.#{fn_name} -- #{inspect decorator}"
    end

    Module.delete_attribute(mod, :decorate)

    quote do
      Kernel.def(
        unquote(fn_call_ast), unquote(fn_opts_ast))
    end
  end

end
