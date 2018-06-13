defmodule EHealth.Parties.Address do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    country
    area
    region
    settlement_type
    settlement
    street_type
    street
    building
    apartment
    zip
  )a

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key false
  schema "addresses" do
    field(:type, :string)
    field(:country, :string)
    field(:area, :string)
    field(:region, :string)
    field(:settlement_type, :string)
    field(:settlement, :string)
    field(:street_type, :string)
    field(:street, :string)
    field(:building, :string)
    field(:apartment, :string)
    field(:zip, :string)
  end

  def changeset(%__MODULE__{} = addr, attrs) do
    addr
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
