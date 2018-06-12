defmodule EHealth.PRMRepo.Migrations.AddCountryOfBirthIntoParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add :country_of_birth, :string
    end

  end
end
