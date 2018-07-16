defmodule EHealth.PRMRepo.Migrations.ModifyEducationsTable do
  use Ecto.Migration

  def change do
    alter table(:educations) do
      add(:speciality_code, :string)
      add(:legalized, :boolean, default: false)
      add(:form, :string)
    end
  end
end
