defmodule EHealth.PRMRepo.Migrations.CreateProvidedServicesTable do
  use Ecto.Migration

  def change do
    create table(:provided_services, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string, null: false)
      add(:sub_types, :string, null: false)
      add(:employee_id, references(:employees, type: :uuid, on_delete: :nothing))
    end

    create(index(:provided_services, [:employee_id]))

  end
end
