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
    Module.delete_attribute(env.module, :decorated)

    decorated
    |> Enum.reverse
    |> filter_undecorated()
    |> Enum.reduce({nil, []}, fn(d, acc) -> decorate(env, d, acc) end)
    |> elem(1)
    |> Enum.reverse
  end

  # Remove all defs which are not decorated -- these doesn't need to be redefined.
  defp filter_undecorated(all) do
    decorated = all
    |> Enum.group_by(
    fn({_kind, fun, args, _guard, _body, _decorators}) ->
      {fun, Enum.count(args)}
    end,
    fn({_kind, _fun, _args, _guard, _body, decorators}) ->
      decorators
    end)
    |> Enum.filter_map(
    fn({_k, decorators_list}) ->
      List.flatten(decorators_list) != []
    end,
    fn({k, _decorators_list}) -> k end)

    all |> Enum.filter(
      fn({_kind, fun, args, _guard, _body, _decorators}) ->
        Enum.member?(decorated, {fun, Enum.count(args)})
      end)
  end


  defp decorate(env, {kind, fun, args, guard, body, decorators}, {prev_fun, all}) do
    arity = Enum.count(args)

    override_clause = quote do
      defoverridable [{unquote(fun), unquote(arity)}]
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

    def_clause =
      case guard do
        [] ->
          quote do
            Kernel.unquote(kind)(unquote(fun)(unquote_splicing(args))) do
              unquote(body)
            end
          end
        _ ->
          quote do
            Kernel.unquote(kind)(unquote(fun)(unquote_splicing(args)) when unquote_splicing(guard)) do
              unquote(body)
            end
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
