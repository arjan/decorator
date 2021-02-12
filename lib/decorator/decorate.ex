defmodule Decorator.Decorate do
  @moduledoc false

  defmodule Context do
    @moduledoc """
    Struct with information about the function that is being decorated.
    """

    defstruct name: nil, arity: nil, module: nil, args: nil
  end

  def on_definition(env, kind, fun, args, guards, body) do
    decorators =
      Module.get_attribute(env.module, :decorate) ++
        Module.get_attribute(env.module, :decorate_all)

    attrs = extract_attributes(env.module, body)
    decorated = {kind, fun, args, guards, body, decorators, attrs}

    Module.put_attribute(env.module, :decorated, decorated)
    Module.delete_attribute(env.module, :decorate)
  end

  defp extract_attributes(module, body) do
    Macro.postwalk(body, %{}, fn
      {:@, _, [{attr, _, nil}]} = n, attrs ->
        attrs = Map.put(attrs, attr, Module.get_attribute(module, attr))
        {n, attrs}

      n, acc ->
        {n, acc}
    end)
    |> elem(1)
  end

  defmacro before_compile(env) do
    decorated = Module.get_attribute(env.module, :decorated) |> Enum.reverse()
    Module.delete_attribute(env.module, :decorated)

    decorated_functions = decorated_functions(decorated)

    decorated
    |> filter_undecorated(decorated_functions)
    |> reject_empty_clauses()
    |> Enum.reduce({[], []}, fn d, acc ->
      decorate(env, d, decorated_functions, acc)
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp decorated_functions(all) do
    Enum.group_by(
      all,
      fn {_kind, fun, args, _guard, _body, _decorators, _attrs} ->
        {fun, Enum.count(args)}
      end,
      fn {_kind, _fun, _args, _guard, _body, decorators, _attrs} ->
        decorators
      end
    )
    |> Enum.filter(fn {_k, decorators_list} ->
      List.flatten(decorators_list) != []
    end)
    |> Enum.into(%{})
  end

  # Remove all defs which are not decorated -- these doesn't need to be redefined.
  defp filter_undecorated(all, decorated_functions) do
    all
    |> Enum.filter(fn {_kind, fun, args, _guard, _body, _decorators, _attrs} ->
      Map.has_key?(decorated_functions, {fun, Enum.count(args)})
    end)
  end

  defp reject_empty_clauses(all) do
    Enum.reject(all, fn {_kind, _fun, _args, _guards, body, _decorators, _attrs} ->
      body == nil
    end)
  end

  defp implied_arities(args) do
    arity = Enum.count(args)

    default_count =
      args
      |> Enum.filter(fn
        {:\\, _, _} -> true
        _ -> false
      end)
      |> Enum.count()

    :lists.seq(arity, arity - default_count, -1)
  end

  defp decorate(
         env,
         {kind, fun, args, guard, body, decorators, attrs},
         decorated_functions,
         {prev_funs, all}
       ) do
    override_clause =
      implied_arities(args)
      |> Enum.map(
        &quote do
          defoverridable [{unquote(fun), unquote(&1)}]
        end
      )

    attrs =
      attrs
      |> Enum.map(fn {attr, value} ->
        {:@, [], [{attr, [], [Macro.escape(value)]}]}
      end)

    arity = Enum.count(args || [])
    context = %Context{name: fun, arity: arity, args: args, module: env.module}

    applicable_decorators =
      case decorators do
        [] -> Map.get(decorated_functions, {fun, arity}) |> hd()
        _ -> decorators
      end

    body =
      applicable_decorators
      |> Enum.reverse()
      |> Enum.reduce(body, fn decorator, body ->
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
            Kernel.unquote(kind)(
              unquote(fun)(unquote_splicing(args)) when unquote_splicing(guard),
              unquote(body)
            )
          end
      end

    fun_and_arity = {fun, arity}

    if not Enum.member?(prev_funs, fun_and_arity) do
      {[fun_and_arity | prev_funs], [def_clause, override_clause] ++ attrs ++ all}
    else
      {prev_funs, [def_clause] ++ attrs ++ all}
    end
  end

  defp ensure_do([{:do, _} | _] = body), do: body
  defp ensure_do(body), do: [do: body]

  # a do-block will automatically be put in a `try do` by Elixir when one of the keywords
  # `rescue`, `catch` or `after` is present. hence `try_clauses`.
  defp apply_decorator(context, mfa, [{:do, body} | try_clauses]) do
    [do: apply_decorator(context, mfa, body)] ++
      apply_decorator_try_clauses(context, mfa, try_clauses)
  end

  defp apply_decorator(context, {module, fun, args}, body) do
    if Enum.member?(module.__info__(:functions), {fun, Enum.count(args) + 2}) do
      Kernel.apply(module, fun, (args || []) ++ [body, context])
    else
      raise ArgumentError, "Unknown decorator function: #{fun}/#{Enum.count(args)}"
    end
  end

  defp apply_decorator(_context, decorator, _body) do
    raise ArgumentError, "Invalid decorator: #{inspect(decorator)}"
  end

  defp apply_decorator_try_clauses(_, _, []), do: []

  defp apply_decorator_try_clauses(context, mfa, [{:after, after_block} | try_clauses]) do
    [after: apply_decorator(context, mfa, after_block)] ++
      apply_decorator_try_clauses(context, mfa, try_clauses)
  end

  defp apply_decorator_try_clauses(context, mfa, [{try_clause, try_match_block} | try_clauses])
       when try_clause in [:rescue, :catch] do
    [{try_clause, apply_decorator_to_try_clause_block(context, mfa, try_match_block)}] ++
      apply_decorator_try_clauses(context, mfa, try_clauses)
  end

  defp apply_decorator_to_try_clause_block(context, mfa, try_match_block) do
    try_match_block
    |> Enum.map(fn {:->, meta, [match, body]} ->
      {:->, meta, [match, apply_decorator(context, mfa, body)]}
    end)
  end

  def generate_args(0, _caller), do: []
  def generate_args(n, caller), do: for(i <- 1..n, do: Macro.var(:"var#{i}", caller))
end
