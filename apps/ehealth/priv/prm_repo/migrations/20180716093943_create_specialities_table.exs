defmodule EHealth.PRMRepo.Migrations.CreateSpecialitiesTable do
  use Ecto.Migration

  def change do
    create table(:specialities, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:speciality, :string)
      add(:level, :string)
      add(:order_date, :date)
      add(:order_number, :string)
      add(:order_institution_name, :string)
      add(:attestation_results, :string)
      add(:qualification_type, :string)
      add(:speciality_officio, :boolean, default: false)
      add(:attestation_date, :date)
      add(:attestation_name, :string)
      add(:valid_to_date, :date)
      add(:certificate_number, :string)
    end
  end
end
