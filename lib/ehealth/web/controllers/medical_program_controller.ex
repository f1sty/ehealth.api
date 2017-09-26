defmodule EHealth.Web.MedicalProgramController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.PRM.MedicalPrograms
  require Logger

  action_fallback EHealth.Web.FallbackController

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    user_id = get_consumer_id(headers)
    with {:ok, medical_program} <- MedicalPrograms.create(user_id, params) do
      conn
      |> put_status(:created)
      |> render("show.json", medical_program: medical_program)
    end
  end
end