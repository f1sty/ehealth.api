defmodule EHealth.PRMRepo.Migrations.CreatePhonesTable do
  use Ecto.Migration

  def change do
    create table(:phones, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:number, :string)
      add(:public, :boolean, default: false)

      add(:party_id, references(:parties, type: :uuid))
    end

    create(index(:phones, [:party_id]))

  end
end
