defmodule EHealth.Parties.Legalization do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

  @fields ~w(
    education_id
    issued_date
    number
    institution_name
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "legalizations" do
    field(:education_id, Ecto.UUID)
    field(:issued_date, :date)
    field(:number, :string)
    field(:institution_name, :string)
  end

  def changeset(legal, attrs) do
    legal
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
