defmodule Core.PRMRepo.Migrations.GlobalParameterPhoneNumberAuthLimit do
  use Ecto.Migration

  alias EHealth.GlobalParameters

  def change do
    user_id = Confex.fetch_env!(:ehealth, :system_user)

    GlobalParameters.create(
      %{"parameter" => "phone_number_auth_limit", "value" => "5", "inserted_by" => user_id, "updated_by" => user_id},
      user_id
    )
  end
end
