defmodule EHealth.Parties.Qualification do

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @derive {Jason.Encoder, except: [:__meta__]}

  @required_fields ~w(
    type
    institution_name
    related_to
    course_name
    form
    speciality
  )a

  @optional_fields ~w(
    duration
    start_date
    end_date
    certification_number
    issued_date
    additional_info
    duration_units
    results
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "qualifications" do
    field(:party_id, Ecto.UUID)
    field(:type, :string)
    field(:institution_name, :string)
    field(:related_to, :map)
    field(:course_name, :string)
    field(:form, :string)
    field(:duration, :string)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:speciality, :string)
    field(:certification_number, :string)
    field(:issued_date, :date)
    field(:additional_info, :string)
    field(:duration_units, :string)
    field(:results, :float)

    timestamps()
  end

  def changeset(qualification, attrs) do
    qualification
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
