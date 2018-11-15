defmodule Core.PRMRepo.Migrations.FixGlobalParameterDeclarationLimit do
  @moduledoc false

  use Ecto.Migration

  alias EHealth.GlobalParameters
  alias EHealth.GlobalParameters.GlobalParameter

  def change do
    user_id = Confex.fetch_env!(:ehealth, :system_user)

    GlobalParameters.create(
      %{"parameter" => "declaration_limit", "value" => "2000", "inserted_by" => user_id, "updated_by" => user_id},
      user_id
    )
  end
end
