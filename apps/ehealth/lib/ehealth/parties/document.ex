defmodule EHealth.Parties.Document do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

  @fields ~w(
    type
    number
    issued_by
    issued_at
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "documents" do
    field(:party_id, Ecto.UUID)
    field(:type, :string)
    field(:number, :string)
    field(:issued_by, :string)
    field(:issued_at, :date)
  end

  def changeset(doc, attrs) do
    doc
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
