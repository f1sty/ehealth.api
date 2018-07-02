defmodule EHealth.PRMRepo.Migrations.CreateEducationsTable do
  use Ecto.Migration

  def change do
    create table(:educations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:country, :string)
      add(:city, :string)
      add(:speciality, :string)
      add(:degree, :string)
      add(:diploma_number, :string)
      add(:institution_name, :string)
      add(:issued_date, :date)

      timestamps()
    end
  end
end
