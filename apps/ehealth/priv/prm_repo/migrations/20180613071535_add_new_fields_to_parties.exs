defmodule EHealth.PRMRepo.Migrations.AddNewFieldsToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:birth_settlement_type, :string)
      add(:citizenship, :string)
      add(:citizenship_at_birth, :string)
      add(:language_skills, :jsonb)
      add(:photo, :string)
      add(:addresses, :jsonb)
      add(:personal_email, :string)
      add(:legalization, :jsonb)
      add(:retirement, :jsonb)
    end
  end
end
