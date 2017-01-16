defmodule Decorator.KernelAtOverride do

  if :application.get_key(:elixir, :vsn) |> elem(1) < '1.4.0' do

    # Elixir 1.3 and older

    # All of the below code is copied from Elixir kernel.ex, defmacro @.
    def handle_at(__CALLER__, name, _meta, args) do
      # Check for Module as it is compiled later than Kernel
      # assert_module_scope(__CALLER__, :@, 1)
      function? = __CALLER__.function != nil

      case not function? and __CALLER__.context == :match do
        false -> nil
        true  ->
          raise ArgumentError, "invalid write attribute syntax, you probably meant to use: @#{name} expression"
      end

      # Typespecs attributes are special cased by the compiler so far
      case is_list(args) and length(args) == 1 and typespec(name) do
        false ->
          do_at(args, name, function?, __CALLER__)
        macro ->
          quote do
            Kernel.Typespec.unquote(macro)(unquote(hd(args)))
          end
      end
    end

    # @attribute(value)
    defp do_at([arg], name, function?, env) do
      case function? do
        true ->
          raise ArgumentError, "cannot set attribute @#{name} inside function/macro"
        false ->
          cond do
            name == :behavior ->
              :elixir_errors.warn env.line, env.file,
                "@behavior attribute is not supported, please use @behaviour instead"
            :lists.member(name, [:moduledoc, :typedoc, :doc]) ->
              {stack, _} = :elixir_quote.escape(Macro.Env.stacktrace(env), false)
              arg = {env.line, arg}
              quote do: Module.put_attribute(__MODULE__, unquote(name), unquote(arg), unquote(stack))
            true ->
              quote do: Module.put_attribute(__MODULE__, unquote(name), unquote(arg))
          end
      end
    end

    # @attribute or @attribute()
    defp do_at(args, name, function?, env) when is_atom(args) or args == [] do
      stack = Macro.Env.stacktrace(env)

      doc_attr? = :lists.member(name, [:moduledoc, :typedoc, :doc])
      case function? do
        true ->
          value =
            with {_, doc} when doc_attr? <- Module.get_attribute(env.module, name, stack),
            do: doc
          try do
            :elixir_quote.escape(value, false)
          rescue
            ex in [ArgumentError] ->
              raise ArgumentError, "cannot inject attribute @#{name} into function/macro because " <> Exception.message(ex)
          else
            {val, _} -> val
          end
        false ->
          {escaped, _} = :elixir_quote.escape(stack, false)
          quote do
            with {_, doc} when unquote(doc_attr?) <- Module.get_attribute(__MODULE__, unquote(name), unquote(escaped)),
              do: doc
          end
      end
    end

    # All other cases
    defp do_at(args, name, _function?, _env) do
      raise ArgumentError, "expected 0 or 1 argument for @#{name}, got: #{length(args)}"
    end

  else

    # Elixir 1.4 and newer

    def bootstrapped?(_), do: true

    def handle_at(__CALLER__, name, meta, args) do
      function? = __CALLER__.function != nil

      cond do
        # Check for Module as it is compiled later than Kernel
        not bootstrapped?(Module) ->
          nil

        not function? and __CALLER__.context == :match ->
          raise ArgumentError, "invalid write attribute syntax, you probably meant to use: @#{name} expression"

          # Typespecs attributes are currently special cased by the compiler
          macro = is_list(args) and length(args) == 1 and typespec(name) ->
          case bootstrapped?(Kernel.Typespec) do
            false -> nil
            true  -> quote do: Kernel.Typespec.unquote(macro)(unquote(hd(args)))
          end

        true ->
          do_at(args, meta, name, function?, __CALLER__)
      end
    end

    # @attribute(value)
    defp do_at([arg], meta, name, function?, env) do
      line =
        case :lists.keymember(:context, 1, meta) do
          true -> nil
          false -> env.line
        end

      cond do
        function? ->
          raise ArgumentError, "cannot set attribute @#{name} inside function/macro"

        name == :behavior ->
          :elixir_errors.warn env.line, env.file,
            "@behavior attribute is not supported, please use @behaviour instead"

        :lists.member(name, [:moduledoc, :typedoc, :doc]) ->
          {stack, _} = :elixir_quote.escape(env_stacktrace(env), false)
          arg = {env.line, arg}
          quote do: Module.put_attribute(__MODULE__, unquote(name), unquote(arg),
                unquote(stack), unquote(line))

        true ->
          quote do: Module.put_attribute(__MODULE__, unquote(name), unquote(arg),
                nil, unquote(line))
      end
    end

    # @attribute or @attribute()
    defp do_at(args, _meta, name, function?, env) when is_atom(args) or args == [] do
      stack = env_stacktrace(env)
      doc_attr? = :lists.member(name, [:moduledoc, :typedoc, :doc])

      case function? do
        true ->
          value =
            with {_, doc} when doc_attr? <-
                 Module.get_attribute(env.module, name, stack),
                   do: doc
                 try do
                   :elixir_quote.escape(value, false)
                 rescue
                   ex in [ArgumentError] ->
                     raise ArgumentError, "cannot inject attribute @#{name} into function/macro because " <> Exception.message(ex)
                 else
                   {val, _} -> val
                 end

        false ->
          {escaped, _} = :elixir_quote.escape(stack, false)
          quote do
            with {_, doc} when unquote(doc_attr?) <-
                 Module.get_attribute(__MODULE__, unquote(name), unquote(escaped)),
                   do: doc
          end
      end
    end

    # All other cases
    defp do_at(args, _meta, name, _function?, _env) do
      raise ArgumentError, "expected 0 or 1 argument for @#{name}, got: #{length(args)}"
    end

    defp env_stacktrace(env) do
      case bootstrapped?(Path) do
        true  -> Macro.Env.stacktrace(env)
        false -> []
      end
    end

  end

  defp typespec(:type),               do: :deftype
  defp typespec(:typep),              do: :deftypep
  defp typespec(:opaque),             do: :defopaque
  defp typespec(:spec),               do: :defspec
  defp typespec(:callback),           do: :defcallback
  defp typespec(:macrocallback),      do: :defmacrocallback
  defp typespec(:optional_callbacks), do: :defoptional_callbacks
  defp typespec(_),                   do: false

end
