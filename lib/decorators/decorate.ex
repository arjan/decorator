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
    decorated = Module.get_attribute(env.module, :decorated) |> Enum.reverse()
    Module.delete_attribute(env.module, :decorated)

    decorated_functions = decorated_functions(decorated)

    decorated
    |> filter_undecorated(decorated_functions)
    |> reject_empty_clauses()
    |> Enum.reduce({nil, []}, fn(d, acc) ->
      decorate(env, d, decorated_functions, acc)
    end)
    |> elem(1)
    |> Enum.reverse
  end

  defp reject_empty_clauses(all) do
    Enum.reject(all, fn {_kind, _fun, _args, _guards, body, _decorators} -> body == nil end)
  end

  defp decorated_functions(all) do
    Enum.group_by(all,
      fn({_kind, fun, args, _guard, _body, _decorators}) ->
        {fun, Enum.count(args)}
      end,
      fn({_kind, _fun, _args, _guard, _body, decorators}) ->
        decorators
      end)
    |> Enum.filter(fn({_k, decorators_list}) ->
      List.flatten(decorators_list) != []
    end)
    |> Enum.into(%{})
  end

  # Remove all defs which are not decorated -- these doesn't need to be redefined.
  defp filter_undecorated(all, decorated_functions) do
    all |> Enum.filter(
      fn({_kind, fun, args, _guard, _body, _decorators}) ->
        Map.has_key?(decorated_functions, {fun, Enum.count(args)})
      end)
  end

  defp implied_arities(args) do
    arity = Enum.count(args)
    default_count =
      args
      |> Enum.filter(fn({:\\, _, _}) -> true; (_) -> false end)
      |> Enum.count
    :lists.seq(arity, arity - default_count, -1)
  end

  defp decorate(env, {kind, fun, args, guard, body, decorators},
    decorated_functions, {prev_fun, all}) do
    override_clause =
      implied_arities(args)
      |> Enum.map(&(quote do
                     defoverridable [{unquote(fun), unquote(&1)}]
        end))

    arity = Enum.count(args || [])
    context = %Context{
      name: fun,
      arity: arity,
      args: args,
      module: env.module}

    applicable_decorators = case decorators do
      [] -> Map.get(decorated_functions, {fun, arity}) |> hd()
      _ -> decorators
    end

    body = applicable_decorators
    |> Enum.reverse
    |> Enum.reduce(body, fn(decorator, body) ->
      apply_decorator(context, decorator, body)
    end)
    |> ensure_do()

    def_clause =
      case guard do
        [] ->
          quote do
            Kernel.unquote(kind)(unquote(fun)(unquote_splicing(args)), unquote(body))
          end
        _ ->
          quote do
            Kernel.unquote(kind)(unquote(fun)(unquote_splicing(args)) when unquote_splicing(guard), unquote(body))
          end
      end

    if {fun, arity} != prev_fun do
      {{fun, arity}, [def_clause, override_clause | all]}
    else
      {{fun, arity}, [def_clause | all]}
    end
  end

  defp ensure_do([{:do, _} | _] = body), do: body
  defp ensure_do(body), do: [do: body]

  defp apply_decorator(context, mfa, [do: body]) do
    [do: apply_decorator(context, mfa, body)]
  end
  defp apply_decorator(context, mfa, [do: body, rescue: rescue_block]) do
    [do: apply_decorator(context, mfa, body), rescue: apply_decorator_to_rescue(context, mfa, rescue_block)]
  end
  defp apply_decorator(context, {module, fun, args}, body) do
    if Enum.member?(module.__info__(:functions), {fun, Enum.count(args) + 2}) do
      Kernel.apply(module, fun, (args || []) ++ [body, context])
    else
      raise ArgumentError, "Unknown decorator function: #{fun}/#{Enum.count(args)}"
    end
  end
  defp apply_decorator(_context, decorator, _body) do
    raise ArgumentError, "Invalid decorator: #{inspect decorator}"
  end

  defp apply_decorator_to_rescue(context, mfa, rescue_block) do
    rescue_block
    |> Enum.map(fn({:->, meta, [match, body]}) ->
      {:->, meta, [match, apply_decorator(context, mfa, body)]}
    end)
  end

  def generate_args(0, _caller), do: []
  def generate_args(n, caller), do: for(i <- 1..n, do: Macro.var(:"var#{i}", caller))

end
