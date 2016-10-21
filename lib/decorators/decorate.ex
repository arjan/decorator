defmodule Decorator.Decorate do

  defmodule Context do
    defstruct name: nil, arity: nil, module: nil, args: nil
  end

  defmacro def(fn_call_ast, fn_opts_ast \\ nil) do
    {fn_call_ast, body} = decorated_fn_body(fn_call_ast, fn_opts_ast, __CALLER__)
    quote do
      Kernel.def(unquote(fn_call_ast), unquote([do: body]))
    end
  end

  defmacro defp(fn_call_ast, fn_opts_ast \\ nil) do
    {fn_call_ast, body} = decorated_fn_body(fn_call_ast, fn_opts_ast, __CALLER__)
    quote do
      Kernel.defp(unquote(fn_call_ast), unquote([do: body]))
    end
  end

  defp decorated_fn_body(fn_call_ast, fn_opts_ast, __CALLER__) do
    decoratee_mod = __CALLER__.module
    [do: body] = fn_opts_ast

    {name, _, args_ast} = fn_call_ast
    context = %Context{
      name: name,
      arity: Enum.count(args_ast),
      args: args_ast,
      module: decoratee_mod}

    decorators = Module.get_attribute(decoratee_mod, :decorators)
    body = if decorators do
      decorators
      |> Enum.reverse
      |> Enum.reduce(body, fn({module, fun, args}, body) ->
        Kernel.apply(module, fun, (args || []) ++ [body, context])
      end)
    else
      body
    end

    Module.delete_attribute(decoratee_mod, :decorators)

    {fn_call_ast, body}
  end

end
