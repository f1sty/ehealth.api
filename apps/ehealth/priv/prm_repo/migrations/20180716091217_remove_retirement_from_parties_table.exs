defmodule EHealth.PRMRepo.Migrations.RemoveRetirementFromPartiesTable do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      remove(:retirement)
    end
  end
end
