defmodule EHealth.Parties.Address do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

  @required_fields ~w(
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

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "addresses" do
    field(:party_id, Ecto.UUID)
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
  end

  def changeset(addr, attrs) do
    addr
    |> cast(attrs, @required_fields ++ [:settlement_id])
    |> validate_required(@required_fields)
  end
end
