defmodule EHealth.Web.EmployeesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer
  alias EHealth.Employees.Employee
  alias EHealth.Parties.Party
  alias Ecto.UUID
  alias EHealth.PRMRepo
  import Mox

  describe "list employees" do
    test "gets only employees that have legal_entity_id == client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: UUID.generate())
      %{id: legal_entity_id} = legal_entity
      party1 = insert(:prm, :party, tax_id: "2222222225")
      party2 = insert(:prm, :party, tax_id: "2222222224")

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok,
         %{"data" => [%{"id" => party1.id, "declaration_count" => 10}, %{"id" => party2.id, "declaration_count" => 10}]}}
      end)

      insert(:prm, :employee, legal_entity: legal_entity, party: party1)

      insert(
        :prm,
        :employee,
        legal_entity: legal_entity,
        employee_type: Employee.type(:pharmacist),
        party: party2
      )

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, employee_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])

      first = Enum.at(resp["data"], 0)
      assert legal_entity_id == first["legal_entity"]["id"]

      second = Enum.at(resp["data"], 1)
      assert legal_entity_id == second["legal_entity"]["id"]
      assert Enum.any?(resp["data"], &Map.has_key?(&1, "doctor"))
      assert Enum.any?(resp["data"], &Map.has_key?(&1, "pharmacist"))
      assert 10 == hd(resp["data"])["party"]["declaration_count"]
    end

    test "filter employees by invalid party_id", %{conn: conn} do
      %{id: legal_entity_id} = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, employee_path(conn, :index, party_id: "invalid"))
      assert json_response(conn, 422)
    end

    test "get employees", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      %{id: legal_entity_id} = legal_entity
      party = insert(:prm, :party)

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => "#{party.id}", "declaration_count" => 10}]}}
      end)

      insert(:prm, :employee, legal_entity: legal_entity, party: party)

      resp =
        conn
        |> put_client_id_header(legal_entity_id)
        |> get(employee_path(conn, :index))
        |> json_response(200)
        |> Map.get("data")
        |> assert_list_response_schema("employee")

      employee = List.first(resp)
      refute Map.has_key?(employee["doctor"], "science_degree")
      refute Map.has_key?(employee["doctor"], "qualifications")
      refute Map.has_key?(employee["doctor"], "educations")

      refute Map.has_key?(employee, "inserted_by")
      refute Map.has_key?(employee, "updated_by")
      refute Map.has_key?(employee, "is_active")
    end

    test "get employees by NHS ADMIN", %{conn: conn} do
      party1 = insert(:prm, :party, tax_id: "2222222225")
      party2 = insert(:prm, :party, tax_id: "2222222224")

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => party1.id, "declaration_count" => 10}]}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: MockServer.get_client_admin())
      insert(:prm, :employee, legal_entity: legal_entity, party: party1)
      insert(:prm, :employee, legal_entity: legal_entity, party: party2)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, employee_path(conn, :index))
      resp = json_response(conn, 200)["data"]
      assert 2 = length(resp)
    end

    test "get employees with client_id that does not match legal entity id", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, employee_path(conn, :index, legal_entity_id: id))
      resp = json_response(conn, 200)
      assert [] == resp["data"]
      assert Map.has_key?(resp, "paging")
      assert String.contains?(resp["meta"]["url"], "/employees")
    end

    test "search employees by tax_id" do
      tax_id = "123"
      party = insert(:prm, :party, tax_id: tax_id)

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => "#{party.id}", "declaration_count" => 10}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, party: insert(:prm, :party))
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = put_client_id_header(build_conn(), legal_entity.id)
      conn = get(conn, employee_path(conn, :index, tax_id: tax_id))
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      party = PRMRepo.get(Party, resp |> hd() |> get_in(["party", "id"]))
      assert tax_id == party.tax_id
    end

    test "search employees by no_tax_id", %{conn: conn} do
      party = insert(:prm, :party, no_tax_id: true)

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => "#{party.id}", "declaration_count" => 10}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      insert(:prm, :employee, party: insert(:prm, :party))
      %{id: id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      conn = get(conn, employee_path(conn, :index, no_tax_id: true))
      assert [data] = json_response(conn, 200)["data"]
      assert id == data["id"]
      assert data["party"]["no_tax_id"]
    end

    test "search employees by invalid tax_id" do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      conn = get(conn, employee_path(conn, :index, tax_id: ""))
      resp = json_response(conn, 200)["data"]
      assert Enum.empty?(resp)
    end

    test "search employees by edrpou" do
      edrpou = "37367387"
      legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      insert(:prm, :employee)

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => "#{employee.party_id}", "declaration_count" => 10}]}}
      end)

      conn = put_client_id_header(build_conn(), legal_entity.id)
      conn = get(conn, employee_path(conn, :index, edrpou: edrpou))
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
    end

    test "search employees by invalid edrpou" do
      conn = put_client_id_header(build_conn(), "7cc91a5d-c02f-41e9-b571-1ea4f2375552")

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      conn = get(conn, employee_path(conn, :index, edrpou: ""))
      resp = json_response(conn, 200)["data"]
      assert Enum.empty?(resp)
    end
  end

  describe "get employee by id" do
    test "with party, division, legal_entity", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")

      speciality_officio = build(:speciality)
        # %EHealth.Parties.Speciality{
        #   order_date: ~D"2016-02-12",
        #   order_number: "X23454",
        #   order_institution_name: "Богомольця",
        #   attestation_results: "BA",
        #   speciality: "Педіатр",
        #   speciality_officio: true,
        #   level: "Перша категорія",
        #   qualification_type: "Присвоєння",
        #   attestation_name: "random string",
        #   attestation_date: ~D[1987-04-17],
        #   valid_to_date: ~D[1987-04-17],
        #   certificate_number: "random string"
        # }
        # "speciality" => "PEDIATRICIAN",
        # "level" => "Перша категорія",
        # "qualification_type" => "Присвоєння",
        # "attestation_name" => "Академія Богомольця",
        # "attestation_date" => "2017-08-04",
        # "valid_to_date" => "2017-08-05",
        # "certificate_number" => "AB/21331",
        # "speciality_officio" => true,
        # "order_date" => "2017-01-02",
        # "order_number" => "X23423",
        # "order_institution_name" => "Богомольця",
        # "attestation_results" => "BA"
      # }

      specialities = [
        speciality_officio,
        build(:speciality, speciality: "Фармацевт", speciality_officio: false)]
        # %EHealth.Parties.Speciality{
        #   order_date: ~D"2016-02-12",
        #   order_number: "X23454",
        #   order_institution_name: "Богомольця",
        #   attestation_results: "BA",
        #   speciality: "Педіатр",
        #   speciality_officio: false,
        #   level: "Перша категорія",
        #   qualification_type: "Присвоєння",
        #   attestation_name: "random string",
        #   attestation_date: ~D[1987-04-17],
        #   valid_to_date: ~D[1987-04-17],
        #   certificate_number: "random string"
        # }
        # %{
        #   "speciality" => "PHARMACIST",
        #   "level" => "Перша категорія",
        #   "qualification_type" => "Присвоєння",
        #   "attestation_name" => "Академія Богомольця",
        #   "attestation_date" => "2017-08-04",
        #   "valid_to_date" => "2017-08-05",
        #   "certificate_number" => "AB/21331",
        #   "speciality_officio" => false,
        #   "order_date" => "2017-01-02",
        #   "order_number" => "X23423",
        #   "order_institution_name" => "Богомольця",
        #   "attestation_results" => "BA"
        # }

      party1 =
        insert(
          :prm,
          :party,
          tax_id: "2222222225",
          specialities: specialities
        )

      # speciality_officio = speciality_officio |> Jason.encode! |> Jason.decode!
      specialities = specialities
                     |> Jason.encode!
                     |> Jason.decode!
                     |> Enum.map(&Map.drop(&1, ~w(id party_id inserted_at updated_at)))
      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party1, speciality: Map.from_struct(speciality_officio) |> Map.delete(:__meta__))


      expect(ReportMock, :get_declaration_count, 2, fn _, _ ->
        {:ok, %{"data" => [%{"id" => "#{employee.party_id}", "declaration_count" => 10}]}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)

      data =
        conn
        |> get(employee_path(conn, :show, employee.id))
        |> json_response(200)
        |> Map.get("data")

      assert_show_response_schema(data, "employee")
      assert specialities == data["doctor"]["specialities"]
      assert 10 == data["party"]["declaration_count"]

      party2 = insert(:prm, :party, tax_id: "2222222224")

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          employee_type: Employee.type(:pharmacist),
          party: party2
        )

      conn
      |> get(employee_path(conn, :show, employee.id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("employee")
    end

    test "without division", %{conn: conn} do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      employee = insert(:prm, :employee, legal_entity: legal_entity, division: nil)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, employee_path(conn, :show, employee.id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp["data"], "party")
      assert Map.has_key?(resp["data"], "legal_entity")

      refute Map.has_key?(resp["data"]["party"], "data")
      refute Map.has_key?(resp["data"]["party"], "updated_by")
      refute Map.has_key?(resp["data"]["party"], "created_by")

      refute Map.has_key?(resp["data"]["legal_entity"], "data")
      refute Map.has_key?(resp["data"]["legal_entity"], "updated_by")
      refute Map.has_key?(resp["data"]["legal_entity"], "created_by")

      refute Map.has_key?(resp["data"], "division_id")
      assert nil == resp["data"]["division"]
    end

    test "with MSP token when legal_entity_id != client_id", %{conn: conn} do
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, employee_path(conn, :show, employee.id))
      json_response(conn, 403)
    end

    test "with MIS token when legal_entity_id != client_id", %{conn: conn} do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, MockServer.get_client_mis())
      conn = get(conn, employee_path(conn, :show, employee.id))
      json_response(conn, 200)
    end

    test "with ADMIN token when legal_entity_id != client_id", %{conn: conn} do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, MockServer.get_client_admin())
      conn = get(conn, employee_path(conn, :show, employee.id))
      json_response(conn, 200)
    end

    test "when legal_entity_id == client_id", %{conn: conn} do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, employee_path(conn, :show, employee.id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_map(resp["data"])
    end
  end

  describe "deactivate employee" do
    setup %{conn: conn} do
      party = insert(:prm, :party, tax_id: "2222222225")
      insert(:prm, :party_user, party: party)
      insert(:prm, :party_user, party: party)
      legal_entity = insert(:prm, :legal_entity)
      doctor = insert(:prm, :employee, legal_entity: legal_entity, party: party)

      pharmacist =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          party: party,
          employee_type: Employee.type(:pharmacist)
        )

      {:ok, %{conn: conn, legal_entity: legal_entity, doctor: doctor, pharmacist: pharmacist}}
    end

    test "with invalid transitions condition", %{conn: conn, legal_entity: legal_entity} do
      employee = insert(:prm, :employee, legal_entity: legal_entity, status: "DEACTIVATED")
      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 409)["error"]["message"] == "Employee is DEACTIVATED and cannot be updated."
    end

    test "can't deactivate OWNER", %{conn: conn, legal_entity: legal_entity} do
      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          employee_type: Employee.type(:owner)
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 409)["error"]["message"] == "Owner can’t be deactivated"
    end

    test "can't deactivate PHARMACY OWNER", %{conn: conn, legal_entity: legal_entity} do
      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          employee_type: Employee.type(:pharmacy_owner)
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 409)["error"]["message"] == "Pharmacy owner can’t be deactivated"
    end

    test "successful doctor", %{conn: conn, doctor: doctor, legal_entity: legal_entity} do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => doctor.party_id, "declaration_count" => 10}]}}
      end)

      expect(OPSMock, :terminate_employee_declarations, fn _id, _user_id, "auto_employee_deactivate", "", _headers ->
        {:ok, %{}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, employee_path(conn, :deactivate, doctor.id))

      resp = json_response(conn, 200)
      refute resp["is_active"]
      assert 10 == resp["data"]["party"]["declaration_count"]
    end

    test "successful pharmacist", %{conn: conn, pharmacist: pharmacist, legal_entity: legal_entity} do
      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => [%{"id" => pharmacist.party_id, "declaration_count" => 10}]}}
      end)

      expect(OPSMock, :terminate_employee_declarations, fn _id, _user_id, "auto_employee_deactivate", "", _headers ->
        {:ok, %{}}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, employee_path(conn, :deactivate, pharmacist.id))

      resp = json_response(conn, 200)
      refute resp["is_active"]
      assert 10 == resp["data"]["party"]["declaration_count"]
    end

    test "not found", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375552")

      assert_raise Ecto.NoResultsError, fn ->
        patch(conn, employee_path(conn, :deactivate, UUID.generate()))
      end
    end
  end
end
