defmodule EHealth.PRMRepo.Migrations.CreatePartyIdReferenceInEducations do
  use Ecto.Migration

  def change do
    alter table(:educations) do
      add(:party_id, references(:parties, type: :uuid, on_delete: :nothing))
    end

    create(index(:educations, [:party_id]))
  end
end
