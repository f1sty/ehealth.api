defmodule EHealth.Parties.Retirement do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    date
  )a

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key false
  embedded_schema do
    field(:type, :string)
    field(:date, :date)
  end

  def changeset(retirement, attrs) do
    retirement
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
