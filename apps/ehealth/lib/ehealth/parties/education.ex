defmodule EHealth.Parties.Education do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "educations" do
    field(:country, :string)
    field(:city, :string)
    field(:degree, :string)
    field(:speciality, :string)
    field(:diploma_number, :string)
    field(:institution_name, :string)
    field(:issued_date, :date)

    timestamps()

    belongs_to(:party, EHealth.Parties.Party, type: Ecto.UUID)
  end

  def changeset(education, attrs) do
    education
    |> Changeset.cast(attrs, [:country, :city, :degree, :speciality, :diploma_number, :institution_name, :issued_date])
    |> Changeset.validate_required([:country])
  end
end
