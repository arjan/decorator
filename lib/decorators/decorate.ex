defmodule Decorators.Decorate do

  defmodule Context do
    defstruct name: nil, arity: nil, module: nil
  end


  defmacro def(fn_call_ast, fn_opts_ast \\ nil) do

    decoratee_mod = __CALLER__.module

    [do: body] = fn_opts_ast

    {name, _, args_ast} = fn_call_ast
    context = %Context{name: name, arity: Enum.count(args_ast), module: decoratee_mod}

    decorators = Module.get_attribute(decoratee_mod, :decorate)
    body = if decorators do
      decorators
      |> Enum.reverse
      |> Enum.reduce(body, fn({module, name, args}, body) ->
        fun = String.to_atom("__decorator_#{name}")
        Kernel.apply(module, fun, args ++ [body, context])
      end)
    else
      body
    end

    Module.delete_attribute(decoratee_mod, :decorate)

    quote do
      Kernel.def(
        unquote(fn_call_ast), unquote([do: body]))
    end
  end

end
