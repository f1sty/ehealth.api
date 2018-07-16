defmodule EHealth.PRMRepo.Migrations.RemoveLegalizationFromPartiesTable do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      remove(:legalization)
    end
  end
end
