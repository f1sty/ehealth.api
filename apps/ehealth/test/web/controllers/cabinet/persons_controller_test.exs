defmodule EHealth.Web.Cabinet.PersonsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  import Mox

  alias Ecto.UUID
  alias EHealth.MockServer

  setup :verify_on_exit!

  defmodule OpsServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/declarations/0cd6a6f0-9a71-4aa7-819d-6c158201a282" do
      response =
        build(
          :declaration,
          id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
          person_id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          division_id: "21f22e09-8dd9-4ca4-bcc7-72994ef2850a",
          employee_id: "5753a279-8f8c-42b9-8f4d-57b38cabe55d",
          legal_entity_id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9"
        )
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.patch "/declarations/0cd6a6f0-9a71-4aa7-819d-6c158201a282/actions/terminate" do
      response =
        build(
          :declaration,
          person_id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
          status: "terminated"
        )
        |> Map.put("reason", "manual_person")
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/latest_block" do
      response =
        %{"hash" => "some_current_hash"}
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  defmodule MithrilServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/admin/users/8069cb5c-3156-410b-9039-a1b2f2a4136c" do
      user = %{
        "id" => "8069cb5c-3156-410b-9039-a1b2f2a4136c",
        "settings" => %{},
        "email" => "test@example.com",
        "type" => "user",
        "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
        "tax_id" => "2222222225",
        "is_blocked" => false
      }

      response =
        user
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/clients/c3cc1def-48b6-4451-be9d-3b777ef06ff9/details" do
      response =
        %{"client_type_name" => "CABINET"}
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/clients/75dfd749-c162-48ce-8a92-428c106d5dc3/details" do
      response =
        %{"client_type_name" => "MSP"}
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/668d1541-e4cf-4a95-a25a-60d83864ceaf" do
      user = %{
        "id" => "668d1541-e4cf-4a95-a25a-60d83864ceaf",
        "settings" => %{},
        "email" => "test@example.com",
        "type" => "user"
      }

      response =
        user
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/roles" do
      response =
        [
          %{
            id: "e945360c-8c4a-4f37-a259-320d2533cfc4",
            role_name: "DOCTOR"
          }
        ]
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/8069cb5c-3156-410b-9039-a1b2f2a4136c/roles" do
      response =
        [
          %{
            id: UUID.generate(),
            user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c",
            role_id: "e945360c-8c4a-4f37-a259-320d2533cfc4",
            role_name: "DOCTOR"
          }
        ]
        |> MockServer.wrap_response()
        |> Jason.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/:id" do
      Plug.Conn.send_resp(conn, 404, "")
    end
  end

  # todo: move declarations tests to declaration_controller_test.exs
  setup do
    insert(:prm, :global_parameter, %{parameter: "adult_age", value: "18"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})

    register_mircoservices_for_tests([
      {MithrilServer, "OAUTH_ENDPOINT"},
      {OpsServer, "OPS_ENDPOINT"}
    ])

    :ok
  end

  describe "update person" do
    test "no required header", %{conn: conn} do
      conn = patch(conn, cabinet_persons_path(conn, :update_person, UUID.generate()))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "invalid params", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"))
      assert resp = json_response(conn, 422)

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.signed_content"
                   }
                 ]
               }
             } = resp
    end

    test "invalid signed content", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64("invalid")
        })

      %{"error" => %{"invalid" => [%{"rules" => [%{"description" => error_description}]}]}} = json_response(conn, 422)
      assert "Not a base64 string" == error_description
    end

    test "tax_id doesn't match with signed content", %{conn: conn} do
      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "3378115538"}}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{}))
        })

      assert resp = json_response(conn, 409)

      assert %{
               "error" => %{
                 "type" => "request_conflict",
                 "message" => "Person that logged in, person that is changed and person that sign should be the same"
               }
             } = resp
    end

    test "tax_id doesn't match with signer", %{conn: conn} do
      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "2222222220"}}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{"tax_id" => "2222222220"}))
        })

      assert resp = json_response(conn, 409)

      assert %{
               "error" => %{
                 "type" => "request_conflict",
                 "message" => "Person that logged in, person that is changed and person that sign should be the same"
               }
             } = resp
    end

    test "invalid signed content changeset", %{conn: conn} do
      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "2222222225"}}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: "2222222225")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("drfo", "2222222225")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{"tax_id" => "2222222225"}))
        })

      assert json_response(conn, 422)
    end

    test "user person_id doesn't match query param id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{}))
        })

      assert json_response(conn, 403)
    end

    test "invalid client_type", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "75dfd749-c162-48ce-8a92-428c106d5dc3")

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{})
      assert json_response(conn, 403)
    end

    test "success update person", %{conn: conn} do
      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "2222222225"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: "2222222225")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :update_person, fn id, _params, _headers ->
        get_person(id, 200)
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      conn =
        conn
        |> put_req_header("drfo", "2222222225")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      data = %{
        "first_name" => "Артем",
        "last_name" => "Иванов",
        "birth_date" => "1990-01-01",
        "birth_country" => "Ukraine",
        "birth_settlement" => "Kyiv",
        "gender" => "MALE",
        "documents" => [%{"type" => "PASSPORT", "number" => "120518"}],
        "addresses" => [
          %{
            "type" => "RESIDENCE",
            "zip" => "02090",
            "settlement_type" => "CITY",
            "country" => "UA",
            "settlement" => "Київ",
            "area" => "Житомирська",
            "settlement_id" => UUID.generate(),
            "building" => "15",
            "region" => "Бердичівський"
          },
          %{
            "type" => "REGISTRATION",
            "zip" => "02090",
            "settlement_type" => "CITY",
            "country" => "UA",
            "settlement" => "Київ",
            "area" => "Житомирська",
            "settlement_id" => UUID.generate(),
            "building" => "15",
            "region" => "Бердичівський"
          }
        ],
        "authentication_methods" => [%{"type" => "OTP", "phone_number" => "+380991112233"}],
        "emergency_contact" => %{
          "first_name" => "Петро",
          "last_name" => "Іванов",
          "second_name" => "Миколайович"
        },
        "process_disclosure_data_consent" => true,
        "secret" => "secret",
        "tax_id" => "2222222225"
      }

      uaddresses_mock_expect()

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(data))
        })

      assert json_response(conn, 200)
    end
  end

  describe "get person details" do
    test "no required header", %{conn: conn} do
      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "tax_id are different in user and person", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          last_name: "Джонс",
          second_name: "Петрович",
          tax_id: "2222222220"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Person not found"}} = resp
    end

    test "returns person detail for logged user", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          last_name: "Джонс",
          second_name: "Петрович",
          tax_id: "2222222225"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      response_data = json_response(conn, 200)["data"]

      assert "c8912855-21c3-4771-ba18-bcd8e524f14c" == response_data["id"]
      assert "Алекс" == response_data["first_name"]
      assert "Джонс" == response_data["last_name"]
      assert "Петрович" == response_data["second_name"]
    end
  end

  describe "create declaration request online" do
    test "success create declaration request online", %{conn: conn} do
      expect(MPIMock, :person, fn _, _ ->
        birth_date =
          Date.utc_today()
          |> Date.add(-365 * 10)
          |> to_string()

        get_person("c8912855-21c3-4771-ba18-bcd8e524f14c", 200, %{
          birth_date: birth_date,
          documents: [
            %{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}
          ],
          tax_id: "2222222225",
          authentication_methods: [%{"type" => "NA"}]
        })
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      person_id = "c8912855-21c3-4771-ba18-bcd8e524f14c"
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)

      expect(ManMock, :render_template, fn _id, _data ->
        {:ok, "<html><body>Printout form for declaration request.</body></html>"}
      end)

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declarations_path(conn, :create_declaration_request), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      assert %{"data" => %{"seed" => "some_current_hash"}} = json_response(conn, 200)
    end
  end

  describe "terminate declaration" do
    test "success terminate declaration", %{conn: conn} do
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      {declaration, _} =
        get_declaration(
          %{
            id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: "c8912855-21c3-4771-ba18-bcd8e524f14c"
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200)
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200)
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> patch(cabinet_declarations_path(conn, :terminate_declaration, "0cd6a6f0-9a71-4aa7-819d-6c158201a282"))

      assert %{"data" => %{"id" => "0cd6a6f0-9a71-4aa7-819d-6c158201a282", "status" => "terminated"}} =
               json_response(conn, 200)
    end
  end

  describe "get declaration details" do
    test "successfully get declaration details by id", %{conn: conn} do
      user_id = "8069cb5c-3156-410b-9039-a1b2f2a4136c"
      legal_entity_id = "c3cc1def-48b6-4451-be9d-3b777ef06ff9"
      division_id = "21f22e09-8dd9-4ca4-bcc7-72994ef2850a"
      employee_id = "5753a279-8f8c-42b9-8f4d-57b38cabe55d"
      person_id = "c8912855-21c3-4771-ba18-bcd8e524f14c"
      declaration_id = "0cd6a6f0-9a71-4aa7-819d-6c158201a282"

      legal_entity = insert(:prm, :legal_entity, id: legal_entity_id)
      insert(:prm, :party_user, user_id: user_id)
      insert(:prm, :division, id: division_id, legal_entity: legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :employee, id: employee_id, party: party)

      {declaration, _} =
        get_declaration(
          %{
            id: declaration_id,
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(MithrilMock, :get_user_by_id, fn user_id_param, _ when user_id_param == user_id ->
        {:ok, %{"data" => %{"person_id" => person_id}}}
      end)

      expect(MPIMock, :person, fn id, _ -> get_person(id, 200) end)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/declaration_id"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, fn _ ->
        {:ok, %{body: "signed_content_hash"}}
      end)

      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = "<html><body>Printout form for declaration #{declaration_id}</body></html>"

        data = %{
          "content" => %{"content" => content},
          "signed_content" => signed_content,
          "signatures" => [
            %{
              "is_valid" => true,
              "signer" => %{},
              "validation_error_message" => ""
            }
          ]
        }

        {:ok, %{"data" => data}}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> get(cabinet_declarations_path(conn, :show_declaration, declaration_id))
        |> json_response(200)

      data = resp["data"]

      assert data["id"] == declaration_id
      assert data["division"]["id"] == division_id
      assert data["employee"]["id"] == employee_id
      assert data["legal_entity"]["id"] == legal_entity_id
      assert data["person"]["id"] == person_id
      assert is_binary(data["person"]["gender"])
      assert is_binary(data["person"]["birth_country"])
      assert data["content"] == "<html><body>Printout form for declaration #{declaration_id}</body></html>"
    end
  end

  describe "get foreign declaration details" do
    test "get 403 error on get foreign declaration details by id", %{conn: conn} do
      user_id = "8069cb5c-3156-410b-9039-a1b2f2a4136c"
      legal_entity_id = "c3cc1def-48b6-4451-be9d-3b777ef06ff9"
      division_id = "21f22e09-8dd9-4ca4-bcc7-72994ef2850a"
      employee_id = "5753a279-8f8c-42b9-8f4d-57b38cabe55d"
      person_id = "c8912855-21c3-4771-ba18-bcd8e524f14c"
      declaration_id = "0cd6a6f0-9a71-4aa7-819d-6c158201a282"

      legal_entity = insert(:prm, :legal_entity, id: legal_entity_id)
      insert(:prm, :party_user, user_id: user_id)
      insert(:prm, :division, id: division_id, legal_entity: legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :employee, id: employee_id, party: party)

      {declaration, _} =
        get_declaration(
          %{
            id: declaration_id,
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(MithrilMock, :get_user_by_id, fn user_id_param, _ when user_id_param == user_id ->
        {:ok, %{"data" => %{"person_id" => "id-PERSON-TRY-GET-FOREIGN-DECLARATION"}}}
      end)

      expect(MPIMock, :person, fn id, _ -> get_person(id, 200) end)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> get(cabinet_declarations_path(conn, :show_declaration, declaration_id))
        |> json_response(403)

      assert "forbidden" = response["error"]["type"]
    end
  end

  describe "declaration not found" do
    test "get 404 error on get foreign declaration details by id", %{conn: conn} do
      user_id = "8069cb5c-3156-410b-9039-a1b2f2a4136c"
      legal_entity_id = "c3cc1def-48b6-4451-be9d-3b777ef06ff9"
      declaration_id = "Declaration-not-found-id-6c158201a282"

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        {:error, :not_found}
      end)

      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity_id}))
        |> get(cabinet_declarations_path(conn, :show_declaration, declaration_id))
        |> json_response(404)

      assert "not_found" = response["error"]["type"]
    end
  end

  describe "person details" do
    test "no required header", %{conn: conn} do
      conn = get(conn, cabinet_persons_path(conn, :person_details))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "tax_id are different in user and person", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          second_name: "Петрович",
          birth_country: "string value",
          birth_settlement: "string value",
          gender: "string value",
          email: "test@example.com",
          tax_id: "2222222220",
          documents: [%{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}],
          phones: [%{"type" => "MOBILE", "number" => "+380972526080"}],
          secret: "string value",
          emergency_contact: %{},
          process_disclosure_data_consent: true,
          authentication_methods: [%{"type" => "NA"}],
          preferred_way_communication: "––"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :person_details))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Person not found"}} = resp
    end

    test "success get person details", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          second_name: "Петрович",
          birth_country: "string value",
          birth_settlement: "string value",
          gender: "string value",
          email: "test@example.com",
          tax_id: "2222222225",
          documents: [%{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}],
          phones: [%{"type" => "MOBILE", "number" => "+380972526080"}],
          secret: "string value",
          emergency_contact: %{},
          process_disclosure_data_consent: true,
          authentication_methods: [%{"type" => "NA"}],
          preferred_way_communication: "––"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      response =
        conn
        |> get(cabinet_persons_path(conn, :person_details))
        |> json_response(200)

      data = response["data"]

      assert data["id"] == "c8912855-21c3-4771-ba18-bcd8e524f14c"
      assert data["first_name"] == "Алекс"
      assert data["second_name"] == "Петрович"
      assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, data["birth_date"])
      assert data["birth_country"] == "string value"
      assert data["birth_settlement"] == "string value"
      assert data["gender"] == "string value"
      assert data["email"] == "test@example.com"
      assert data["tax_id"] == "2222222225"
      assert data["documents"] == [%{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}]

      assert Enum.count(data["addresses"]) == 2

      assert Enum.all?(data["addresses"], fn address ->
               address["settlement_id"] == "707dbc55-cb6b-4aaa-97c1-2a1e03476100"
             end)

      assert data["phones"] == [%{"type" => "MOBILE", "number" => "+380972526080"}]
      assert data["secret"] == "string value"
      assert data["emergency_contact"] == %{}
      assert data["process_disclosure_data_consent"] == true
      assert data["authentication_methods"] == [%{"type" => "NA"}]
      assert data["preferred_way_communication"] == "––"
    end
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

  defp get_person(id, response_status, params \\ %{}) do
    params = Map.merge(params, %{id: id, addresses: get_person_addresses()})
    person = build(:person, params)

    person =
      person
      |> Jason.encode!()
      |> Jason.decode!()

    {:ok, MockServer.wrap_object_response(person, response_status)}
  end

  defp get_person_addresses do
    [
      %{
        "zip" => "02090",
        "type" => "REGISTRATION",
        "street_type" => "STREET",
        "street" => "Ніжинська",
        "settlement_type" => "CITY",
        "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
        "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
        "region" => "ПУСТОМИТІВСЬКИЙ",
        "country" => "UA",
        "building" => "15",
        "area" => "ЛЬВІВСЬКА",
        "apartment" => "23"
      },
      %{
        "zip" => "02090",
        "type" => "RESIDENCE",
        "street_type" => "STREET",
        "street" => "Ніжинська",
        "settlement_type" => "CITY",
        "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
        "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
        "region" => "ПУСТОМИТІВСЬКИЙ",
        "country" => "UA",
        "building" => "15",
        "area" => "ЛЬВІВСЬКА",
        "apartment" => "23"
      }
    ]
  end

  defp uaddresses_mock_expect do
    expect(UAddressesMock, :validate_addresses, fn _, _ ->
      {:ok, %{"data" => %{}}}
    end)
  end
end
