defmodule EHealth.PRMRepo.Migrations.AddNewFieldsToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:birth_settlement_type, :string)
      add(:citizenship, :string)
      add(:citizenship_at_birth, :string)
      add(:language_skills, :map)
      add(:photo, :string)
      add(:addresses, :map)
      add(:personal_email, :string)
      add(:legalization, :map)
      add(:retirement, :map)
    end
  end
end
