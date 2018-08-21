defmodule EHealth.PRMRepo.Migrations.CreateQualificationsTable do
  use Ecto.Migration

  def change do
    create table(:qualifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:related_to, :map)
      add(:course_name, :string)
      add(:duration, :string)
      add(:duration_units, :string)
      add(:results, :float)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:institution_name, :string)
      add(:issued_date, :date)
      add(:certificate_number, :string)
      add(:speciality, :string)
      add(:form, :string)
      add(:valid_to, :date)
      add(:party_id, references(:parties, type: :uuid, on_deleete: :nothing))
    end
    create(index(:qualifications, [:party_id]))
  end
end
