defmodule EHealth.PRMRepo.Migrations.AddNewaddsToEmployeesTable do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add(:employment_status, :map)
      add(:employee_category, :string)
      add(:position_level, :string)
      add(:speciality_nomenclature, :string)
      add(:dk_code, :string)
    end
  end
end
