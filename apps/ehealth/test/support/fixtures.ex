defmodule EHealth.Test.Support.Fixtures do
  @moduledoc false

  alias Ecto.UUID
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.Repo

  def simple_fixture(:declaration_request, status \\ "ACTIVE", authentication_method_current_type \\ "OTP") do
    data =
      "test/data/sign_declaration_request.json"
      |> File.read!()
      |> Jason.decode!()

    Repo.insert!(%DeclarationRequest{
      data: data,
      status: status,
      inserted_by: UUID.generate(),
      updated_by: UUID.generate(),
      declaration_id: UUID.generate(),
      authentication_method_current: %{"type" => authentication_method_current_type},
      printout_content: "",
      channel: DeclarationRequest.channel(:mis),
      declaration_number: to_string(Enum.random(1..1000))
    })
  end
end
