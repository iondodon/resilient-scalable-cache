defmodule Utils do
    def type_and_value(value) do
        value = internal_type(value)

        cond do
            is_float(value)    ->
                "(float) #{value}"
            is_integer(value)  ->
                "(integer) #{value}"
            is_boolean(value)  ->
                "(boolean) #{value}"
            is_atom(value)     ->
                "(atom) #{value}"
            is_binary(value)   ->
                "(binary) #{value}"
            is_function(value) ->
                "(function) #{value}"
            is_list(value)     ->
                value_str = Enum.reduce(value, "", fn item, str -> str <> " " <> item end)
                "(list) #{value_str}"
            is_tuple(value)    ->
                "(tuple) #{value}"
            is_map(value)      ->
                {:ok, value} = Poison.encode(value)
                "(map) #{value}"
            true              ->
                "(idunno) #{value}"
        end
    end

    def internal_type(value) do
        if is_binary(value) do
            case Integer.parse(value) do
                {val, rem} -> if String.equivalent?(rem,"") do val else
                    {val, _rem} = Float.parse(value)
                    val
                end
                :error -> cond do
                    String.equivalent?(value, "true") -> true
                    String.equivalent?(value, "false") -> false
                    true -> value
                end
            end
        else
            value
        end
    end
end
