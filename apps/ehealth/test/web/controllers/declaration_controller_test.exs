defmodule EHealth.Web.DeclarationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "list declarations" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, edrpou: "37367387"))
      json_response(conn, 401)
    end

    test "by person_id", %{conn: conn} do
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      expect(OPSMock, :get_declarations, fn %{"person_id" => person_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          status
        )
      end)

      expect(MPIMock, :search, fn %{ids: ids}, _headers ->
        get_persons(ids)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :index, person_id: UUID.generate()))

      resp =
        conn
        |> json_response(status)
        |> Map.get("data")

      assert 2 == Enum.count(resp)

      Enum.each(resp, fn elem ->
        assert Map.has_key?(elem, "reason")
        assert Map.has_key?(elem, "reason_description")
        assert Map.has_key?(elem, "declaration_number")
      end)
    end

    test "empty by person_id", %{conn: conn} do
      status = 200

      expect(OPSMock, :get_declarations, fn _params, _headers ->
        {:ok, %{"data" => [], "meta" => %{"code" => status}}}
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, person_id: UUID.generate()))
      assert [] = json_response(conn, status)["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id with empty declarations list", %{conn: conn} do
      status = 200

      expect(OPSMock, :get_declarations, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "meta" => %{"code" => status},
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, edrpou: "37367387"))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id and invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: UUID.generate()))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      status = 200

      division = insert(:prm, :division)
      legal_entity = insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      expect(OPSMock, :get_declarations, fn _params, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          1,
          status
        )
      end)

      expect(MPIMock, :search, fn %{ids: ids}, _headers ->
        get_persons(ids)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: legal_entity.id))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      person_id = UUID.generate()

      expect(OPSMock, :get_declarations, fn %{"legal_entity_id" => legal_entity_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity_id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          status
        )
      end)

      expect(MPIMock, :search, fn %{ids: ids}, _headers ->
        get_persons(ids)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: legal_entity.id))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      status = 200

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      expect(OPSMock, :get_declarations, fn %{"legal_entity_id" => legal_entity_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity_id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          3,
          status
        )
      end)

      expect(MPIMock, :search, fn %{ids: ids}, _headers ->
        get_persons(ids)
      end)

      %{id: legal_entity_id} = legal_entity
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: legal_entity_id))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 3 == length(resp["data"])
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end
  end

  describe "declaration by id" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      {declaration, declaration_id} = get_declaration(%{}, 200)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375111")
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains MSP client_id with undefined declaration id", %{conn: conn} do
      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        nil
      end)

      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get(conn, declaration_path(conn, :show, "226b4182-f9ce-4eda-b6af-43d2de8600a0"))
      json_response(conn, 404)
    end

    test "with x-consumer-metadata that contains MSP client_id with invalid legal_entity_id", %{conn: conn} do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      {declaration, declaration_id} = get_declaration(%{legal_entity_id: legal_entity_id}, 200)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      {declaration, declaration_id} =
        get_declaration(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      data = json_response(conn, 200)["data"]
      assert Map.has_key?(data, "reason")
      assert Map.has_key?(data, "reason_description")
      assert Map.has_key?(data, "declaration_number")
      assert_declaration_expanded_fields(data)
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      {declaration, declaration_id} =
        get_declaration(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert declaration_id == data["id"]
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      {declaration, declaration_id} =
        get_declaration(
          %{
            id: person_id,
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert declaration_id == data["id"]
    end
  end

  def assert_declaration_expanded_fields(declaration) do
    fields = ~W(person employee division legal_entity)
    assert is_map(declaration)
    assert declaration["declaration_request_id"]

    Enum.each(fields, fn field ->
      assert Map.has_key?(declaration, field), "Expected field #{field} not present"
      assert is_map(declaration[field]), "Expected that field #{field} is map"
      assert Enum.any?([:id, "id"], &Map.has_key?(declaration[field], &1)), "Expected field #{field}.id not present"
      refute Map.has_key?(declaration, field <> "_id"), "Field #{field}_id should be not present"
    end)
  end

  describe "approve/2 - Happy case" do
    defmodule ApproveOPSMicroservice do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "active",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "approved"
        }

        send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveOPSMicroservice)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "it transitions declaration to approved status" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      response = json_response(response, 200)

      assert "approved" = response["data"]["status"]
    end
  end

  describe "approve/2 - not owner of declaration" do
    defmodule ApproveNotOwnerOfDeclaration do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveNotOwnerOfDeclaration)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "a 403 error is returned" do
      client_id = Ecto.UUID.generate()
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      assert json_response(response, 403)
    end
  end

  describe "approve/2 - declaration was inactive" do
    defmodule ApproveDeclarationIsInactive do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => false,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveDeclarationIsInactive)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "a 404 error is returned (as if declaration never existed)" do
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      assert json_response(response, 404)
    end
  end

  describe "approve/2 - could not transition status" do
    defmodule ApproveCannotTransitionStatus do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "approved"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "active",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        error_resp = %{
          meta: %{
            code: 422
          },
          error: %{
            message: "some_eview_message"
          }
        }

        send_resp(conn, 422, Jason.encode!(error_resp))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveCannotTransitionStatus)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "a 409 error is returned" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      assert json_response(response, 409)
    end
  end

  describe "reject/2 - Happy case" do
    defmodule OPSMicroservice do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "rejected",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "rejected"
        }

        send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OPSMicroservice)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "it transitions declaration to rejected status" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      response = json_response(response, 200)

      assert "rejected" = response["data"]["status"]
    end
  end

  describe "reject/2 - not owner of declaration" do
    defmodule NotOwnerOfDeclaration do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(NotOwnerOfDeclaration)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "a 403 error is returned" do
      client_id = Ecto.UUID.generate()
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      assert json_response(response, 403)
    end
  end

  describe "reject/2 - declaration was inactive" do
    defmodule DeclarationIsInactive do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => false,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(DeclarationIsInactive)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "a 404 error is returned (as if declaration never existed)" do
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      assert json_response(response, 404)
    end
  end

  describe "reject/2 - could not transition status" do
    defmodule CannotTransitionStatus do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "closed"
        }

        send_resp(conn, 200, Jason.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "rejected",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        error_resp = %{
          meta: %{
            code: 422
          },
          error: %{
            message: "some_eview_message"
          }
        }

        send_resp(conn, 422, Jason.encode!(error_resp))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(CannotTransitionStatus)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port, conn: conn}}
    end

    test "a 409 error is returned" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      assert json_response(response, 409)
    end
  end

  describe "terminate declarations" do
    defmodule Terminate do
      use MicroservicesHelper

      Plug.Router.patch "/employees/9b6c7be2-278e-4be5-a297-2d009985c200/declarations/actions/terminate" do
        data = %{
          "terminated_declarations" => [
            %{
              "id" => "9b6c7be2-278e-4be5-a297-2d009985c720",
              "reason" => conn.body_params["reason"],
              "reason_description" => conn.body_params["reason_description"],
              "status" => "terminated",
              "updated_at" => "2018-01-26T14:21:36.404375Z",
              "updated_by" => "4261eacf-8008-4e62-899f-de1e2f7065f0"
            }
          ]
        }

        send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: data}))
      end

      Plug.Router.patch "/persons/9b6c7be2-278e-4be5-a297-2d009985c200/declarations/actions/terminate" do
        data = %{
          "terminated_declarations" => [
            %{
              "id" => "9b6c7be2-278e-4be5-a297-2d009985c720",
              "reason" => conn.body_params["reason"],
              "reason_description" => conn.body_params["reason_description"],
              "status" => "terminated",
              "updated_at" => "2018-01-26T14:21:36.404375Z",
              "updated_by" => "4261eacf-8008-4e62-899f-de1e2f7065f0"
            }
          ]
        }

        send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: data}))
      end

      Plug.Router.patch "/employees/9b6c7be2-278e-4be5-a297-2d009985c404/declarations/actions/terminate" do
        send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: %{terminated_declarations: []}}))
      end

      Plug.Router.patch "/persons/9b6c7be2-278e-4be5-a297-2d009985c404/declarations/actions/terminate" do
        send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: %{terminated_declarations: []}}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(Terminate)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      route_id = "9b6c7be2-278e-4be5-a297-2d009985c200"

      {:ok, %{port: port, conn: conn, user_id: user_id, client_id: client_id, route_id: route_id}}
    end

    test "both params person_id and employee_id passed", %{conn: conn, client_id: client_id, user_id: user_id} do
      payload = %{person_id: Ecto.UUID.generate(), employee_id: Ecto.UUID.generate(), reason_description: "lol"}

      conn
      |> put_req_header("x-consumer-id", user_id)
      |> put_client_id_header(client_id)
      |> patch("/api/declarations/terminate", payload)
      |> json_response(422)
    end

    test "terminate by person_id", %{conn: conn, route_id: person_id, user_id: user_id, client_id: client_id} do
      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/terminate", %{person_id: person_id, reason_description: "Person cheater"})
        |> json_response(200)

      assert [%{"reason" => "manual_person", "reason_description" => "Person cheater"}] =
               response["data"]["terminated_declarations"]
    end

    test "no declarations by person_id", %{conn: conn, user_id: user_id, client_id: client_id} do
      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/terminate", %{person_id: "9b6c7be2-278e-4be5-a297-2d009985c404"})
        |> json_response(422)

      assert "Person does not have active declarations" == response["error"]["message"]
    end

    test "terminate by employee_id", %{conn: conn, route_id: employee_id, user_id: user_id, client_id: client_id} do
      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/terminate", %{employee_id: employee_id, reason_description: "Employee died"})
        |> json_response(200)

      assert [%{"reason" => "manual_employee", "reason_description" => "Employee died"}] =
               response["data"]["terminated_declarations"]
    end

    test "no declarations by employee_id", %{conn: conn, user_id: user_id, client_id: client_id} do
      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/terminate", %{employee_id: "9b6c7be2-278e-4be5-a297-2d009985c404"})
        |> json_response(422)

      assert "Employee does not have active declarations" == response["error"]["message"]
    end
  end

  defp get_declarations(params, count, response_status) when count > 0 do
    declarations =
      Enum.map(1..count, fn _ ->
        declaration = build(:declaration, params)

        declaration
        |> Jason.encode!()
        |> Jason.decode!()
      end)

    {:ok,
     %{
       "data" => declarations,
       "meta" => %{"code" => response_status},
       "paging" => %{
         "page_number" => 1,
         "page_size" => 50,
         "total_entries" => count,
         "total_pages" => 1
       }
     }}
  end

  defp get_declaration(params, response_status) do
    declaration = build(:declaration, params)
    declaration_id = declaration.id

    declaration =
      declaration
      |> Jason.encode!()
      |> Jason.decode!()

    {{:ok, %{"data" => declaration, "meta" => %{"code" => response_status}}}, declaration_id}
  end

  defp get_persons(params) when is_binary(params) do
    persons =
      Enum.map(String.split(params, ","), fn id ->
        person = build(:person, id: id)

        person
        |> Jason.encode!()
        |> Jason.decode!()
      end)

    {:ok, %{"data" => persons}}
  end

  defp get_person(id) do
    person = build(:person, id: id)

    person =
      person
      |> Jason.encode!()
      |> Jason.decode!()

    {:ok, %{"data" => person}}
  end
end
