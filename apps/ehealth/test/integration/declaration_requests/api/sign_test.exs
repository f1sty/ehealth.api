defmodule EHealth.Integraiton.DeclarationRequests.API.SignTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.DeclarationRequests.API.Sign
  import Mox

  alias Ecto.UUID
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.Repo
  alias HTTPoison.Response

  setup :verify_on_exit!

  describe "check_status/2" do
    test "returns error when status is not APPROVED" do
      declaration_request = insert(:il, :declaration_request, status: "ACTIVE")
      result = check_status(declaration_request)
      expected_result = {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}
      assert expected_result == result
    end

    test "returns expected result when status is APPROVED" do
      declaration_request = insert(:il, :declaration_request, status: "APPROVED")
      assert :ok == check_status(declaration_request)
    end
  end

  describe "check_patient_signed/1" do
    test "returns error when content is empty" do
      result = check_patient_signed("")

      expected_result =
        {:error, [{%{description: "Can not be empty", params: [], rule: :invalid}, "$.declaration_request"}]}

      assert expected_result == result
    end

    test "returns error when patient_signed is false" do
      input_data = %{"person" => %{"key" => "value", "patient_signed" => false}}
      result = check_patient_signed(input_data)

      expected_result =
        {:error,
         [{%{description: "Patient must sign declaration form", params: [], rule: :invalid}, "$.person.patient_signed"}]}

      assert expected_result == result
    end

    test "returns expected result when patient_signed is true" do
      id = UUID.generate()

      content = %{
        "id" => id,
        "person" => %{"key" => "value", "patient_signed" => true},
        "status" => "APPROVED",
        "content" => "<html></html>"
      }

      assert :ok == check_patient_signed(content)
    end
  end

  describe "compare_with_db/1" do
    test "returns error when data does not match" do
      db_data = %DeclarationRequest{data: %{"person" => %{"key" => "another_value"}}}
      input_data = %{"person" => %{"key" => "value"}}
      result = compare_with_db(input_data, db_data)

      expected_result =
        {:error,
         [
           {%{description: "Signed content does not match the previously created content", params: [], rule: :invalid},
            "$.content"}
         ]}

      assert expected_result == result
    end

    test "returns expected result when data matches" do
      id = UUID.generate()

      db_data = %DeclarationRequest{
        id: id,
        data: %{
          "person" => %{"key" => "value", "patient_signed" => false},
          "seed" => "99bc78ba577a95a11f1a344d4d2ae55f2f857b98"
        },
        status: "APPROVED",
        printout_content: "<html></html>"
      }

      content = %{
        "id" => id,
        "person" => %{"key" => "value", "patient_signed" => true},
        "status" => "APPROVED",
        "content" => "<html></html>",
        "seed" => "some_current_hash",
        "declaration_number" => nil
      }

      assert :ok == compare_with_db(content, db_data)
    end
  end

  describe "check_drfo/1" do
    test "returns error when drfo does not match the tax_id" do
      tax_id = "AA111"
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))
      signer = %{"drfo" => "222"}
      result = check_drfo(signer, [{"x-consumer-id", user_id}])
      assert {:error, {:"422", "Does not match the signer drfo"}} == result
    end

    test "returns expected result when drfo matches the tax_id" do
      tax_id = "AA111"
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      signer = %{"drfo" => "AA 111"}
      assert :ok == check_drfo(signer, [{"x-consumer-id", user_id}])
    end

    test "check drfo when it latin" do
      tax_id = "МЮ111"
      assert [1052, 1070, 49, 49, 49] == String.to_charlist(tax_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      drfo = "MYU 111"
      assert 'MYU 111' == String.to_charlist(drfo)
      signer = %{"drfo" => drfo}
      assert :ok == check_drfo(signer, [{"x-consumer-id", user_id}])
    end

    test "returns expected result when drfo is null" do
      tax_id = "AA111"
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))
      signer = %{"drfo" => nil}
      result = check_drfo(signer, [{"x-consumer-id", user_id}])
      assert {:error, {:"422", "Does not match the signer drfo"}} == result
    end
  end

  describe "check_employee_id/2" do
    test "returns forbidden when you try to sign someone else's declaration" do
      content = %{"employee" => %{"id" => UUID.generate()}}
      x_consumer_id_header = {"x-consumer-id", "88231792-f27f-4e5d-9f29-f246557ba42b"}
      assert {:error, :forbidden} == check_employee_id(content, [x_consumer_id_header])
    end

    test "returns expected result when you sign declaration from your legal entity" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      party = insert(:prm, :party, declaration_limit: 100)
      %{id: employee_id} = insert(:prm, :employee, legal_entity_id: legal_entity_id, party: party)

      content = %{"employee" => %{"id" => employee_id}}
      headers = [{"x-consumer-metadata", Jason.encode!(%{client_id: legal_entity_id})}]
      assert :ok == check_employee_id(content, headers)
    end
  end

  describe "create_or_update_person/2" do
    test "returns expected result" do
      expect(MPIMock, :search, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person, fn params, _headers ->
        {:ok, %{"data" => params}}
      end)

      person = %{"first_name" => "test", "birth_date" => "1990-01-01", "last_name" => "test", "patient_signed" => false}
      uuid = "6e8d4595-e83c-4f97-be76-c6e2b96b05f1"

      assert {:ok,
              %{
                "data" => %{
                  "first_name" => "test",
                  "birth_date" => "1990-01-01",
                  "last_name" => "test",
                  "patient_signed" => true,
                  "id" => uuid
                }
              }} == create_or_update_person(%DeclarationRequest{mpi_id: uuid}, %{"person" => person}, [])
    end

    test "person is not active" do
      expect(MPIMock, :search, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person, fn _params, _headers ->
        {:ok, %Response{status_code: 409}}
      end)

      person = %{
        "first_name" => "test",
        "last_name" => "test",
        "birth_date" => "1990-01-01",
        "patient_signed" => false
      }

      uuid = "d2bb5bef-5984-4c25-9538-16ed61dc810e"

      assert {:conflict, "person is not active"} ==
               create_or_update_person(%DeclarationRequest{mpi_id: uuid}, %{"person" => person}, [])
    end

    test "person not found" do
      expect(MPIMock, :search, fn _params, _headers ->
        {:ok, %{"data" => []}}
      end)

      expect(MPIMock, :create_or_update_person, fn _params, _headers ->
        {:ok, %Response{status_code: 404}}
      end)

      person = %{"data" => "somedata", "birth_date" => "1990-01-01", "patient_signed" => false}
      uuid = UUID.generate()

      assert {:conflict, "person is not found"} ==
               create_or_update_person(%DeclarationRequest{id: uuid}, %{"person" => person}, [])
    end

    test "person already exists on MPI" do
      person_id = UUID.generate()

      expect(MPIMock, :search, fn _params, _headers ->
        {:ok, %{"data" => [string_params_for(:person, id: person_id)]}}
      end)

      expect(MPIMock, :update_person, fn id, params, _headers ->
        {:ok, %{"data" => Map.put(params, "id", id)}}
      end)

      person = %{"first_name" => "test", "birth_date" => "1990-01-01", "last_name" => "test", "patient_signed" => false}
      uuid = UUID.generate()

      assert {:ok,
              %{
                "data" => %{
                  "first_name" => "test",
                  "birth_date" => "1990-01-01",
                  "id" => person_id,
                  "last_name" => "test",
                  "patient_signed" => true
                }
              }} == create_or_update_person(%DeclarationRequest{id: uuid}, %{"person" => person}, [])
    end
  end

  describe "create_declaration_with_termination_logic/2" do
    # defmodule OPSMock do
    #   use MicroservicesHelper

    #   Plug.Router.post "/declarations/with_termination" do
    #     %{"declaration_request_id" => _} = conn.body_params
    #     send_resp(conn, 200, Jason.encode!(%{data: conn.body_params}))
    #   end
    # end

    # setup do
    #   {:ok, port, ref} = start_microservices(OPSMock)

    #   System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

    #   on_exit(fn ->
    #     System.put_env("OPS_ENDPOINT", "http://localhost:4040")
    #     stop_microservices(ref)
    #   end)

    #   :ok
    # end

    test "returns expected result" do
      %{data: declaration_request_data} =
        declaration_request =
        insert(
          :il,
          :declaration_request,
          status: "ACTIVE",
          authentication_method_current: %{"type" => "OTP"},
          overlimit: false
        )

      person_id = UUID.generate()
      person_data = %{"data" => %{"id" => person_id}}
      client_id = UUID.generate()
      x_consumer_id_header = {"x-consumer-id", client_id}

      expect(OPSMock, :create_declaration_with_termination_logic, fn params, _headers ->
        get_declaration_with_termination_logic(params, client_id, person_id)
      end)

      {:ok, %{"data" => data}} =
        create_declaration_with_termination_logic(person_data, declaration_request, [x_consumer_id_header])

      IO.inspect(declaration_request, label: "declaration_request")
      IO.inspect(declaration_request_data, label: "declaration_request_data")
      System.halt()

      assert false === data["overlimit"]
      assert client_id == data["created_by"]
      assert client_id == data["updated_by"]
      assert person_id == data["person_id"]
      assert declaration_request_data["division"]["id"] == data["division_id"]
      # assert declaration_request_data["employee"]["id"] == data["employee_id"]
      assert declaration_request_data["legal_entity"]["id"] == data["legal_entity_id"]
      # assert declaration_request_data["start_date"] == data["start_date"]
      # assert declaration_request_data["end_date"] == data["end_date"]
      assert declaration_request_data["scope"] == data["scope"]
      assert declaration_request_data["seed"] == data["seed"]
      assert "active" == data["status"]
      assert data["is_active"]
    end

    test "returns active status when authentication_method_current.type == NA" do
      declaration_request =
        insert(:il, :declaration_request, status: "ACTIVE", authentication_method_current: %{"type" => "NA"})

      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic(person_data, declaration_request, [])
      assert "active" == data["status"]
    end

    test "returns pending_validation status when authentication_method_current.type == OFFLINE" do
      declaration_request =
        insert(:il, :declaration_request, status: "ACTIVE", authentication_method_current: %{"type" => "OFFLINE"})

      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic(person_data, declaration_request, [])
      assert "pending_verification" == data["status"]
    end

    test "returns empty status when authentication_method_current.type is unknown" do
      declaration_request =
        insert(:il, :declaration_request, status: "ACTIVE", authentication_method_current: %{"type" => "SOME_TYPE"})

      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic(person_data, declaration_request, [])
      assert "" == data["status"]
    end
  end

  describe "update_declaration_request_status/2" do
    test "updates declaration request status to SIGNED and drops unnecessary fields in response" do
      declaration_request = insert(:il, :declaration_request, status: "ACTIVE")
      declaration_response_data = %{"updated_by" => "", "updated_at" => "", "created_by" => "", "another_key" => ""}
      declaration_response = %{"data" => declaration_response_data}
      {:ok, data} = update_declaration_request_status(declaration_request, declaration_response)
      refute Map.has_key?(data, "updated_by")
      refute Map.has_key?(data, "updated_at")
      refute Map.has_key?(data, "created_by")
      assert Map.has_key?(data, "another_key")
      %DeclarationRequest{status: status} = Repo.get!(DeclarationRequest, declaration_request.id)
      assert "SIGNED" == status
    end
  end

  defp get_declaration_with_termination_logic(params, client_id \\ nil, person_id \\ nil) do
    # IO.inspect(params)
    client_id = if client_id, do: client_id, else: UUID.generate()
    person_id = if person_id, do: person_id, else: UUID.generate()

    declaration =
      string_params_for(:declaration, params)
      |> Map.put("created_by", client_id)
      |> Map.put("updated_by", client_id)
      |> Map.put("person_id", person_id)

    {:ok, %{"data" => declaration}}
  end
end
