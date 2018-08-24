defmodule EHealth.Employees.ProvidedService do

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    type
    sub_types
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "provided_services" do
    field(:type, :string)
    field(:sub_types, {:array, :map})
    field(:employee_id, Ecto.UUID)
  end

  def changeset(ps, attrs) do
    ps
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
