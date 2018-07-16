defmodule EHealth.PRMRepo.Migrations.AddPartyIdToSpecialitiesTable do
  use Ecto.Migration

  def change do
    alter table(:specialities) do
      add(:party_id, references(:parties, type: :uuid, on_delete: :nothing))
    end

    create(index(:specialities, [:party_id]))
  end

end
