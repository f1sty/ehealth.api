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
    settlement_id
    street_type
    street
    building
    apartment
    zip
  )a

  @primary_key false
  schema "addresses" do
    field(:type, :string)
    field(:country, :string)
    field(:area, :string)
    field(:region, :string)
    field(:settlement_type, :string)
    field(:settlement, :string)
    field(:settlement_id, Ecto.UUID)
    field(:street_type, :string)
    field(:street, :string)
    field(:building, :string)
    field(:apartment, :string)
    field(:zip, :string)

    belongs_to(:party, EHealth.Parties.Party, type: Ecto.UUID)
  end

  def changeset(addr, attrs) do
    addr
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
