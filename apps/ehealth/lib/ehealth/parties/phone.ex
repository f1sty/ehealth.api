defmodule EHealth.Parties.Phone do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    number
    public
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "phones" do
    field(:type, :string)
    field(:number, :string)
    field(:public, :boolean, default: false)

    belongs_to(:party, EHealth.Parties.Party, type: Ecto.UUID)
  end

  def changeset(phone, attrs) do
    phone
    |> cast(attrs, @fields)
    |> validate_required([:type, :number])
  end
end
