defmodule EHealth.PRMRepo.Migrations.RenameCountryOfBirthToBirthCountry do
  use Ecto.Migration

  def change do
    rename table(:parties), :country_of_birth, to: :birth_country
  end
end
