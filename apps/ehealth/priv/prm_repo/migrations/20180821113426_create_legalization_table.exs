defmodule EHealth.PRMRepo.Migrations.CreateLegalizationTable do
  use Ecto.Migration

  def change do
    create table(:legalizations, primary_key: true) do
      add(:id, :uuid, primary_key: true)
      add(:issued_date, :date)
      add(:number, :string)
      add(:legalization_name, :string)
      add(:education_id, references(:educations, type: :uuid, on_delete: :nothing))
    end

    create(index(:legalizations, [:education_id]))
  end
end
