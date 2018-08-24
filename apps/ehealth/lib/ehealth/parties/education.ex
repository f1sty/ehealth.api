defmodule EHealth.Parties.Education do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

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

  @optional_fields ~w(
    legalized
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "educations" do
    field(:party_id, Ecto.UUID)
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

    has_many(:legalizations, EHealth.Parties.Legalization, foreign_key: :education_id)
  end

  def changeset(education, attrs) do
    education
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
