defmodule EHealth.Web.RegisterControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox

  alias Ecto.UUID
  alias EHealth.Registers.Register
  alias EHealth.MockServer

  @status_new Register.status(:new)
  @status_processed Register.status(:processed)
  @status_processing Register.status(:processing)

  describe "list registers" do
    setup %{conn: conn} do
      insert(:il, :register, status: @status_new)
      insert(:il, :register, status: @status_processed)
      insert(:il, :register, status: @status_processing)

      %{conn: conn}
    end

    test "success list", %{conn: conn} do
      assert 3 =
               conn
               |> get(register_path(conn, :index))
               |> json_response(200)
               |> Map.get("data")
               |> length()
    end

    test "search by status", %{conn: conn} do
      data =
        conn
        |> get(register_path(conn, :index), status: @status_processed)
        |> json_response(200)
        |> Map.get("data")

      assert 1 == length(data)
      assert @status_processed == hd(data)["status"]
    end

    test "search by inserted_at range", %{conn: conn} do
      insert(:il, :register, status: @status_processing, inserted_at: ~N[2017-12-12 12:10:12])
      %{id: id} = insert(:il, :register, status: @status_processing, inserted_at: ~N[2017-12-13 02:10:12])
      insert(:il, :register, status: @status_processing, inserted_at: ~N[2017-12-14 14:10:12])

      params = %{
        status: @status_processing,
        inserted_at_from: "2017-12-13",
        inserted_at_to: "2017-12-13"
      }

      assert [register] =
               conn
               |> get(register_path(conn, :index), params)
               |> json_response(200)
               |> Map.get("data")

      assert id == register["id"]
      assert @status_processing == register["status"]
    end
  end

  describe "create register" do
    defmodule Termination do
      use MicroservicesHelper

      Plug.Router.patch "/persons/:id/declarations/actions/terminate" do
        # check that declaration termination reason started with `auto_`
        case conn.body_params["reason"] do
          "auto_" <> _type -> send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: %{}}))
          _ -> send_resp(conn, 404, Jason.encode!(%{meta: %{code: 404}, data: %{}}))
        end
      end
    end

    setup :set_mox_global

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(Termination)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      %{conn: conn}
    end

    test "success with status PROCESSED", %{conn: conn} do
      expect(MPIMock, :search, 3, fn _, _ ->
        persons_data = [%{"id" => UUID.generate()}, %{"id" => UUID.generate()}]
        {:ok, MockServer.wrap_response_with_paging(persons_data)}
      end)

      expect(MPIMock, :update_person, 6, fn _, _, _ ->
        {:ok, MockServer.wrap_object_response()}
      end)

      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_register_type)

      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "DEATH_REGISTRATION",
        person_type: "patient"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 0,
               "not_found" => 0,
               "processing" => 0,
               "total" => 6
             } == data["qty"]

      assert "PROCESSED" = data["status"]

      # check register_entry
      register_entries =
        conn
        |> get(register_entry_path(conn, :index), register_id: data["id"])
        |> json_response(200)
        |> Map.get("data")

      assert 6 = length(register_entries)

      Enum.each(register_entries, fn entry ->
        assert data["id"] == entry["register_id"]
        assert data["inserted_by"] == entry["updated_by"]
        assert data["updated_by"] == entry["inserted_by"]
        assert Map.has_key?(entry, "document_type")
        assert Map.has_key?(entry, "document_number")
      end)
    end

    test "success with status PROCESSING", %{conn: conn} do
      expect(MPIMock, :search, 4, fn params, _ ->
        {operation_status, response_data} =
          case params do
            %{"number" => "primary"} ->
              {:ok, MockServer.wrap_response_with_paging([%{"id" => UUID.generate()}, %{"id" => UUID.generate()}])}

            %{"number" => "processing"} ->
              {:error, %{"error" => %{"message" => "system unavailable"}}}

            _ ->
              {:ok, MockServer.wrap_response_with_paging([])}
          end

        {operation_status, response_data}
      end)

      expect(MPIMock, :update_person, 4, fn _, _, _ ->
        {:ok, %{"data" => %{}, "meta" => %{"code" => 200}}}
      end)

      %{values: values} = insert(:il, :dictionary_document_type)
      dict_values = values |> Map.keys() |> Kernel.++(["TAX_ID"]) |> Enum.join(", ")

      attrs = %{
        file: get_csv_file("diverse"),
        file_name: "persons",
        type: "death",
        person_type: "patient"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 5,
               "not_found" => 1,
               "processing" => 1,
               "total" => 11
             } == data["qty"]

      assert "PROCESSING" = data["status"]

      assert [
               "Row has length 4 - expected length 2 on line 4",
               "Invalid type - expected one of #{dict_values} on line 6",
               "Row has length 1 - expected length 2 on line 7",
               "Invalid number - expected non empty string on line 8",
               "Row has length 1 - expected length 2 on line 10"
             ] == data["errors"]
    end

    test "person_type not passed", %{conn: conn} do
      attrs = %{
        file: get_csv_file("valid"),
        file_name: "death",
        type: "death"
      }

      assert [invalid] =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.person_type" == invalid["entry"]
    end

    test "invalid dictionary type", %{conn: conn} do
      insert(:il, :dictionary_register_type)

      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death",
        person_type: "patient"
      }

      assert [invalid] =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.type" == invalid["entry"]
    end

    test "invalid person_type", %{conn: conn} do
      attrs = %{
        file: get_csv_file("valid"),
        file_name: "death",
        type: "death",
        person_type: "invalid"
      }

      assert [invalid] =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.person_type" == invalid["entry"]
    end

    test "invalid CSV file format", %{conn: conn} do
      attrs = %{
        file: "invalid base64 string",
        file_name: "death",
        type: "death",
        person_type: "patient"
      }

      assert [invalid] =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.file" == invalid["entry"]
    end

    test "invalid CSV headers", %{conn: conn} do
      attrs = %{
        file: get_csv_file("invalid_headers"),
        file_name: "death",
        type: "death",
        person_type: "patient"
      }

      assert "Invalid CSV headers" =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error message))

      assert [] == conn |> get(register_path(conn, :index)) |> json_response(200) |> Map.get("data")
    end

    test "invalid CSV body", %{conn: conn} do
      %{values: values} = insert(:il, :dictionary_document_type)
      dict_values = values |> Map.keys() |> Kernel.++(["TAX_ID"]) |> Enum.join(", ")

      attrs = %{
        file: get_csv_file("invalid_body"),
        file_name: "death",
        type: "death",
        person_type: "patient"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 2,
               "not_found" => 0,
               "processing" => 0,
               "total" => 2
             } == data["qty"]

      assert "PROCESSED" = data["status"]

      assert [
               "Invalid number - expected non empty string on line 2",
               "Invalid type - expected one of #{dict_values} on line 3"
             ] == data["errors"]
    end

    test "invalid CSV type field because of empty dictionary values by DOCUMENT_TYPE", %{conn: conn} do
      attrs = %{
        file: get_csv_file("valid"),
        file_name: "death",
        type: "death",
        person_type: "patient"
      }

      assert "Type not allowed" =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error message))
    end
  end

  describe "create register with param reason_description and user_id" do
    defmodule TerminationWithRequiredParams do
      use MicroservicesHelper

      Plug.Router.patch "/persons/:id/declarations/actions/terminate" do
        case is_binary(conn.body_params["reason_description"]) do
          true -> send_resp(conn, 200, Jason.encode!(%{meta: %{code: 200}, data: %{}}))
          _ -> send_resp(conn, 404, Jason.encode!(%{meta: %{code: 404}, data: %{}}))
        end
      end
    end

    setup :set_mox_global

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(TerminationWithRequiredParams)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      insert(:il, :dictionary_document_type)
      %{conn: conn}
    end

    test "both params passed", %{conn: conn} do
      expect(MPIMock, :search, 3, fn params, _ ->
        case is_binary(params["type"]) do
          true -> {:ok, MockServer.wrap_response_with_paging([%{"id" => UUID.generate()}], 200)}
          _ -> {:error, MockServer.wrap_object_response(%{}, 422)}
        end
      end)

      expect(MPIMock, :update_person, 3, fn _, _, _ ->
        {:ok, MockServer.wrap_object_response()}
      end)

      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death",
        person_type: "patient",
        reason_description: "Згідно реєстру померлих"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 0,
               "not_found" => 0,
               "processing" => 0,
               "total" => 3
             } == data["qty"]

      assert "PROCESSED" = data["status"]
    end

    test "param reason_description not passed", %{conn: conn} do
      expect(MPIMock, :search, 3, fn params, _ ->
        case is_binary(params["type"]) do
          true -> {:ok, MockServer.wrap_response_with_paging([%{"id" => UUID.generate()}])}
          _ -> {:error, MockServer.wrap_object_response(%{}, 422)}
        end
      end)

      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death",
        person_type: "patient"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 0,
               "not_found" => 0,
               "processing" => 3,
               "total" => 3
             } == data["qty"]

      assert "PROCESSING" = data["status"]
    end

    test "header consumer_id not set", %{conn: conn} do
      conn = delete_consumer_id_header(conn)

      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death",
        person_type: "patient",
        reason_description: "Згідно реєстру померлих"
      }

      message =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(401)
        |> get_in(~w(error message))

      assert "Missing header x-consumer-id" == message
    end
  end

  defp get_csv_file(name) do
    "test/data/register/#{name}.csv"
    |> File.read!()
    |> Base.encode64()
  end
end
