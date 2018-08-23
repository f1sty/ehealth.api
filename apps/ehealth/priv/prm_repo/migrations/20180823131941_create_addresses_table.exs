defmodule EHealth.PRMRepo.Migrations.CreateAddressesTable do
  use Ecto.Migration

  def change do
    create table(:addresses, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:country, :string)
      add(:area, :string)
      add(:region, :string)
      add(:settlement_type, :string)
      add(:settlement, :string)
      add(:settlement_id, :string)
      add(:street_type, :string)
      add(:street, :string)
      add(:building, :string)
      add(:apartment, :string)
      add(:zip, :string)

      add(:party_id, references(:parties, type: :uuid))
    end

    create(index(:addresses, [:party_id]))

  end
end
