defmodule EHealth.PRMRepo.Migrations.AddBirthSettlementFieldToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add :birth_settlement, :string
    end
  end
end
