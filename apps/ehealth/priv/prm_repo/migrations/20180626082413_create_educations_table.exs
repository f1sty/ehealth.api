defmodule EHealth.PRMRepo.Migrations.CreateEducationsTable do
  use Ecto.Migration

  def change do
    create table(:educations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:institution_name, :string)
      add(:degree, :string)
      add(:speciality, :string)
      add(:speciality_code, :string)
      add(:legalized, :boolean, default: false)
      add(:country, :string)
      add(:city, :string)
      add(:issued_date, :date)
      add(:diploma_number, :string)
      add(:form, :string)

      add(:party_id, references(:parties, type: :uuid)

      timestamps()
    end

    create(index(:educations, [:party_id]))

  end
end
