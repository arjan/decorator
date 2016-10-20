defmodule DecoratorTest do

  defmacro decorate() do
    Module.put_attribute(__CALLER__.module, :decorated, :true)
  end

  defmacro def(fn_call_ast, fn_opts_ast \\ nil) do

    mod = __CALLER__.module

    {fn_name, _, _} = fn_call_ast
    if Module.get_attribute(mod, :decorated) do
      IO.puts "Decorate function: #{mod}.#{fn_name}"
    end

    Module.delete_attribute(mod, :decorated)

    quote do
      Kernel.def(
        unquote(fn_call_ast), unquote(fn_opts_ast))
    end
  end

  defmacro __using__(_) do

    quote do
      import Kernel, except: [def: 2]
      import DecoratorTest, only: [def: 2, decorate: 0]
    end
  end

end
