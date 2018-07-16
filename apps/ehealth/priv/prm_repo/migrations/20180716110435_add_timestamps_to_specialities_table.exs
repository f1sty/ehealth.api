defmodule EHealth.PRMRepo.Migrations.AddTimestampsToSpecialitiesTable do
  use Ecto.Migration

  def change do
    alter table(:specialities) do
      timestamps()
    end
  end
end
