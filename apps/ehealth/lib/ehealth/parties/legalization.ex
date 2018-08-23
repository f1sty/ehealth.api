defmodule EHealth.Parties.Legalization do

  use Ecto.Scema

  import Ecto.Changeset, warn: false

  @fields ~w(
    issued_date
    number
    institution_name
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "legalizations" do
    field(:issued_date, :date)
    field(:number, :string)
    field(:institution_name, :string)

    timestamps()

    belongs_to(:education, EHealth.Parties.Education, type: Ecto.UUID)
  end

  def changeset(legal, attrs) do
    legal
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
