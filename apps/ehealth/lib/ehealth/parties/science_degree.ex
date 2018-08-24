defmodule EHealth.Parties.ScienceDegree do

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

  @fields ~w(
    institution_name
    degree
    diploma_number
    speciality
    degree_country
    degree_city
    degree_institution_name
    science_domain
    speciality_group
    code
    degree_science_domain
    academic_status
    country
    city
    issued_date
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "science_degrees" do
    field(:party_id, Ecto.UUID)
    field(:institution_name, :string)
    field(:degree, :string)
    field(:diploma_number, :string)
    field(:speciality, :string)
    field(:degree_country, :string)
    field(:degree_city, :string)
    field(:degree_institution_name, :string)
    field(:science_domain, :string)
    field(:speciality_group, :string)
    field(:code, :string)
    field(:degree_science_domain, :string)
    field(:academic_status, :string)
    field(:country, :string)
    field(:city, :string)
    field(:issued_date, :date)

    timestamps()
  end

  def changeset(degree, attrs) do
    degree
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
