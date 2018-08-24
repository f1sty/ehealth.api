defmodule EHealth.PRMRepo.Migrations.CreateDocumentsTable do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:number, :string)
      add(:issued_by, :string)
      add(:issued_at, :date)

      add(:party_id, references(:parties, type: :uuid))
    end

    create(index(:documents, [:party_id]))

  end
end
