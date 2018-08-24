defmodule EHealth.Parties.Phone do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

  @fields ~w(
    type
    number
    public
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "phones" do
    field(:party_id, Ecto.UUID)
    field(:type, :string)
    field(:number, :string)
    field(:public, :boolean, default: false)
  end

  def changeset(phone, attrs) do
    phone
    |> cast(attrs, @fields)
    |> validate_required([:type, :number])
  end
end
