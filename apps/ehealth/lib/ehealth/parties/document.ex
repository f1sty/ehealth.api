defmodule EHealth.Parties.Document do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    number
    issued_by
    issued_at
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "documents" do
    field(:type, :string)
    field(:number, :string)
    field(:issued_by, :string)
    field(:issued_at, :date)

    belongs_to(:party, EHealth.Parties.Party, type: Ecto.UUID)
  end

  def changeset(doc, attrs) do
    doc
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
