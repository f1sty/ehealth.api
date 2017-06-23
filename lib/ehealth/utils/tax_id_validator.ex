defmodule EHealth.Utils.TaxIDValidator do
  @moduledoc """
  Tax ID validator
  """

  @ratios [-1, 5, 7, 9, 4, 6, 10, 5, 7]

  def validate(tax_id) do
    {check_sum, i} =
      Enum.reduce(@ratios, {0, 0}, fn(x, {acc, i}) -> {acc + x * String.to_integer(String.at(tax_id, i)), i + 1} end)

    check_number =
      check_sum
      |> rem(11)
      |> rem(10)

    last_number =
      tax_id
      |> String.at(i)
      |> String.to_integer()

    last_number == check_number
  end
end
