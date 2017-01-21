defmodule Decorator.Decorate do

  defmodule Context do
    defstruct name: nil, arity: nil, module: nil, args: nil
  end

  def on_definition(env, kind, fun, args, guards, body) do
    decorators = Module.get_attribute(env.module, :decorate)
    decorated = {kind, fun, args, guards, body, decorators}
    Module.put_attribute(env.module, :decorated, decorated)
    Module.delete_attribute(env.module, :decorate)
  end

  defmacro before_compile(env) do
    decorated = Module.get_attribute(env.module, :decorated)

    decorated
    |> Enum.reverse
    |> Enum.reduce({nil, []}, fn(d, acc) -> decorate(env, d, acc) end)
    |> elem(1)
    |> Enum.reverse
  end


  defp decorate(env, {kind, fun, args, guard, body, decorators}, {prev_fun, all}) do
    arity = Enum.count(args)

    override_clause = quote do
      defoverridable [{unquote(fun), unquote(arity)}]
    end

    guard = case guard do
              [] -> [true]
              _ -> guard
            end

    context = %Context{
      name: fun,
      arity: Enum.count(args || []),
      args: args,
      module: env.module}

    body = decorators
    |> Enum.reverse
    |> Enum.reduce(body, fn(decorator, body) ->
      apply_decorator(context, decorator, body)
    end)

    def_clause = quote do
      Kernel.unquote(kind)(unquote(fun)(unquote_splicing(args)) when unquote_splicing(guard)) do
        unquote(body)
      end
    end

    if fun != prev_fun do
      {fun, [def_clause, override_clause | all]}
    else
      {fun, [def_clause | all]}
    end
  end

  defp apply_decorator(context, {module, fun, args}, body) do
    if Enum.member?(module.__info__(:exports), {fun, Enum.count(args) + 2}) do
      Kernel.apply(module, fun, (args || []) ++ [body, context])
    else
      raise ArgumentError, "Unknown decorator function: #{fun}/#{Enum.count(args)}"
    end
  end
  defp apply_decorator(_context, decorator, _body) do
    raise ArgumentError, "Invalid decorator: #{inspect decorator}"
  end

  def generate_args(0, _caller), do: []
  def generate_args(n, caller), do: for(i <- 1..n, do: Macro.var(:"var#{i}", caller))

end
