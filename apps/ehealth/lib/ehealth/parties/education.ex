defmodule EHealth.Parties.Education do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @required_fields ~w(
    country
    city
    degree
    speciality
    speciality_code
    diploma_number
    institution_name
    issued_date
    form
  )a

  schema "educations" do
    field(:country, :string)
    field(:city, :string)
    field(:degree, :string)
    field(:speciality, :string)
    field(:speciality_code, :string)
    field(:legalized, :boolean)
    field(:form, :string)
    field(:diploma_number, :string)
    field(:institution_name, :string)
    field(:issued_date, :date)

    timestamps()

    belongs_to(:party, EHealth.Parties.Party, type: Ecto.UUID)
  end

  def changeset(education, attrs) do
    education
    |> Changeset.cast(attrs, @required_fields)
    |> Changeset.validate_required(@required_fields)
  end
end
