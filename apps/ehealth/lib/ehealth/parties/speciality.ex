defmodule EHealth.Parties.Speciality do
  @moduledoc false

  use Ecto.Schema
 
  import Ecto.Changeset, warn: false


  @primary_key {:id, :binary_id, autogenerate: true}

  @required_fields ~w(
    speciality
    level
    order_number
    order_date
    order_institution_name
    attestation_results
    qualification_type
    attestation_date
    attestation_name
    valid_to_date
    certificate_number
  )a

  @optional_fields ~w(
    speciality_officio
  )a

  schema "specialities" do
    field(:speciality, :string)
    field(:level, :string)
    field(:order_date, :date)
    field(:order_number, :string)
    field(:order_institution_name, :string)
    field(:attestation_results, :string)
    field(:qualification_type, :string)
    field(:speciality_officio, :boolean)
    field(:attestation_date, :date)
    field(:attestation_name, :string)
    field(:valid_to_date, :date)
    field(:certificate_number, :string)

    timestamps()

    belongs_to(:party, EHealth.Parties.Party, type: Ecto.UUID)
  end

  def changeset(speciality, attrs) do
    speciality
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
