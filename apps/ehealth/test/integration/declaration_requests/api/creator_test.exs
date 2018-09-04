defmodule EHealth.Integraiton.DeclarationRequest.API.CreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox
  import Ecto.Changeset, only: [get_change: 2, put_change: 3]

  alias EHealth.DeclarationRequests.API.Creator
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.Utils.NumberGenerator
  alias Ecto.UUID

  describe "generate_printout_form/1" do
    setup %{conn: _conn} do
      expect(ManMock, :render_template, fn id, data ->
        case id do
          "999" ->
            {:error, "oops, I did it again"}

          id when id in [4, "4"] ->
            printout_form =
              data
              |> Map.drop(~w(locale format)a)
              |> Jason.encode!()

            {:ok, printout_form}
        end
      end)

      insert(:il, :dictionary_settlement_type)
      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_street_type)
      insert(:il, :dictionary_document_relationship_type)
      insert(:il, :dictionary_speciality_type)

      :ok
    end

    test "updates declaration request with expected printout form when data is valid" do
      number = NumberGenerator.generate(1, 2)

      employee_speciality =
        speciality()
        |> Map.put("speciality", "PEDIATRICIAN")
        |> Map.put("qualification_type", "Присвоєння")
        |> Map.put("level", "Перша категорія")

      employee = insert(:prm, :employee, speciality: employee_speciality)

      data =
        "test/data/sign_declaration_request.json"
        |> File.read!()
        |> Jason.decode!()

      authentication_method_current = %{
        "type" => "OTP"
      }

      printout_content =
        %DeclarationRequest{id: UUID.generate(), data: data}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, authentication_method_current)
        |> put_change(:declaration_number, number)
        |> Creator.generate_printout_form(employee)
        |> get_change(:printout_content)

      expected_content = %{
        person: %{
          full_name: "Петро Миколайович Іванов",
          first_name: "Петро",
          second_name: "Миколайович",
          last_name: "Іванов",
          gender: %{
            male: true,
            female: false
          },
          birth_date: "19.08.1991",
          document: %{
            type: "Паспорт",
            number: "120518",
            issued_at: ""
          },
          birth_settlement: "Вінниця",
          birth_country: "Україна",
          tax_id: "3126509816",
          addresses: %{
            registration: %{
              full_address:
                "Житомирська область, Бердичівський район, місто Київ, вулиця Ніжинська 15, квартира 23, 02090",
              zip: "02090",
              type: "REGISTRATION",
              street_type: "вулиця",
              street: "Ніжинська",
              settlement_type: "місто",
              settlement_id: "43432432",
              settlement: "Київ",
              region: "Бердичівський",
              country: "UA",
              building: "15",
              area: "Житомирська",
              apartment: "23"
            },
            residence: %{
              full_address: "Житомирська область, Бердичівський район, місто Київ, вулиця Ніжинська 16, квартира 41, \
02090",
              zip: "02090",
              type: "RESIDENCE",
              street_type: "вулиця",
              street: "Ніжинська",
              settlement_type: "місто",
              settlement_id: "43432432",
              settlement: "Київ",
              region: "Бердичівський",
              country: "UA",
              building: "16",
              area: "Житомирська",
              apartment: "41"
            }
          },
          phones: %{
            number: "+380503410870"
          },
          email: "email@example.com",
          secret: "secret",
          emergency_contact: %{
            full_name: "Петро Миколайович Іванов",
            phones: %{
              number: "+380503410870"
            }
          },
          confidant_person: %{
            primary: %{
              full_name: "Петро Миколайович Іванов",
              phones: %{
                number: "+380503410870"
              },
              birth_date: "19.08.1991",
              gender: %{
                male: true,
                female: false
              },
              birth_settlement: "Вінниця",
              birth_country: "Україна",
              documents_person: %{
                type: "Паспорт",
                number: "120518",
                issued_at: ""
              },
              tax_id: "3126509816",
              documents_relationship: %{
                type: "Документ",
                number: "120519",
                issued_at: ""
              }
            },
            secondary: %{
              full_name: "Іван Миколайович Петров",
              phones: %{
                number: "+380503410871"
              },
              birth_date: "20.08.1991",
              gender: %{
                male: true,
                female: false
              },
              birth_settlement: "Вінниця",
              birth_country: "Україна",
              documents_person: %{
                type: "Паспорт",
                number: "120520",
                issued_at: ""
              },
              tax_id: "3126509817",
              documents_relationship: %{
                type: "Документ",
                number: "120521",
                issued_at: ""
              }
            }
          },
          national_id: "––",
          preferred_way_communication: "––"
        },
        employee: %{
          full_name: "Петро Миколайович Іванов",
          phones: %{
            number: "+380503410870"
          },
          email: "email@example.com",
          speciality: %{
            valid_to_date: "1987-04-17",
            speciality_officio: true,
            speciality: "педіатр",
            qualification_type: "Присвоєння",
            level: "Перша категорія",
            certificate_number: "random string",
            attestation_name: "random string",
            attestation_date: "1987-04-17",
            attestation_results: "BA",
            order_date: "2016-02-12",
            order_institution_name: "Богомольця",
            order_number: "X23454"
          }
        },
        division: %{
          addresses: %{
            residence: %{
              full_street: nil
            }
          },
          email: "email@example.com",
          phone: "+380503410870"
        },
        legal_entity: %{
          full_name: "Клініка Борис",
          addresses: %{
            registration: %{
              full_address: "Житомирська область, Бердичівський район, місто Київ, вулиця Ніжинська 15, квартира 23, \
02090"
            }
          },
          edrpou: "5432345432",
          full_license: "fd123443 (2017-02-28)",
          phones: %{
            number: "+380503410870"
          },
          email: "email@example.com"
        },
        confidant_persons: %{
          exist: true,
          secondary: true
        },
        authentication_method_current: %{
          otp: true,
          offline: false
        },
        declaration_id: nil,
        declaration_number: number,
        start_date: "02.03.2017"
      }

      assert printout_content == Jason.encode!(expected_content)
    end

    test "updates declaration request with expected printout form when data contains more than three licenses " do
      authentication_method_current = %{
        "type" => "OTP"
      }

      licenses = [get_license("1a"), get_license("2b"), get_license("3c"), get_license("4d")]
      employee = insert(:prm, :employee, id: "d290f1ee-6c54-4b01-90e6-d701748f0851")

      data =
        "test/data/sign_declaration_request.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["legal_entity", "licenses"], licenses)

      printout_content =
        %DeclarationRequest{id: UUID.generate(), data: data}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, authentication_method_current)
        |> Creator.generate_printout_form(employee)
        |> get_change(:printout_content)
        |> Jason.decode!()
        |> get_in(["legal_entity", "full_license"])

      assert printout_content == "1a (2017-02-28), 2b (2017-02-28), 3c (2017-02-28)"
    end

    test "updates declaration request with printout form that has empty fields when data is empty" do
      number = NumberGenerator.generate(1, 2)

      employee_speciality =
        speciality()
        |> Map.put("speciality", "PEDIATRICIAN")
        |> Map.put("qualification_type", "Присвоєння")
        |> Map.put("level", "Перша категорія")

      employee = insert(:prm, :employee, id: "d290f1ee-6c54-4b01-90e6-d701748f0851", speciality: employee_speciality)

      printout_content =
        %DeclarationRequest{id: UUID.generate(), data: %{}}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, %{})
        |> put_change(:declaration_number, number)
        |> Creator.generate_printout_form(employee)
        |> get_change(:printout_content)

      expected_content = %{
        person: %{
          full_name: "",
          first_name: nil,
          last_name: nil,
          second_name: "––",
          gender: %{
            male: false,
            female: false
          },
          birth_date: "",
          document: %{
            type: "",
            number: "",
            issued_by: "",
            issued_at: ""
          },
          birth_settlement: "",
          birth_country: "",
          tax_id: "––",
          addresses: %{
            registration: %{
              full_address: ""
            },
            residence: %{
              full_address: ""
            }
          },
          phones: %{
            number: "––"
          },
          email: "––",
          secret: "",
          emergency_contact: %{
            full_name: "",
            phones: %{
              number: "––"
            }
          },
          confidant_person: %{
            primary: %{},
            secondary: %{}
          },
          preferred_way_communication: "––",
          national_id: "––"
        },
        employee: %{
          full_name: "",
          phones: %{
            number: "––"
          },
          email: "",
          speciality: %{
            valid_to_date: "1987-04-17",
            speciality_officio: true,
            speciality: "педіатр",
            qualification_type: "Присвоєння",
            level: "Перша категорія",
            certificate_number: "random string",
            attestation_name: "random string",
            attestation_date: "1987-04-17",
            attestation_results: "BA",
            order_date: "2016-02-12",
            order_institution_name: "Богомольця",
            order_number: "X23454"
          }
        },
        division: %{
          addresses: %{
            residence: %{
              full_street: nil
            }
          },
          email: nil,
          phone: nil
        },
        legal_entity: %{
          full_name: "",
          addresses: %{
            registration: %{
              full_address: ""
            }
          },
          edrpou: "",
          full_license: "",
          phones: %{
            number: "––"
          },
          email: ""
        },
        confidant_persons: %{
          exist: false,
          secondary: false
        },
        authentication_method_current: %{
          otp: false,
          offline: false
        },
        declaration_id: nil,
        declaration_number: number,
        start_date: ""
      }

      assert printout_content == Jason.encode!(expected_content)
    end

    test "returns error on printout_content field" do
      System.put_env("DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", "999")
      employee = insert(:prm, :employee)

      changeset =
        %DeclarationRequest{id: UUID.generate(), data: %{}}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, %{})
        |> Creator.generate_printout_form(employee)

      assert ~s(Error during MAN interaction. Result from MAN: "oops, I did it again") ==
               elem(changeset.errors[:printout_content], 0)

      System.put_env("DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", "4")
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record exists" do
    test "auth method's type is set to OTP password" do
      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("id", "b5350f79-f2ca-408f-b15d-1ae0a8cc861c")
             |> Map.put("authentication_methods", [
               %{
                 "type" => "OTP",
                 "phone_number" => "+380508887700"
               }
             ])
           ]
         }}
      end)

      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "Олена",
            "second_name" => "XXX",
            "last_name" => "Пчілка",
            "birth_date" => "1980-08-19",
            "tax_id" => "3126509816",
            "authentication_methods" => [
              %{
                "phone_number" => "+380508887700"
              }
            ]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> Creator.determine_auth_method_for_mpi(DeclarationRequest.channel(:mis))

      assert %{"number" => "+380508887700", "type" => "OTP"} == get_change(changeset, :authentication_method_current)
      assert "b5350f79-f2ca-408f-b15d-1ae0a8cc861c" == get_change(changeset, :mpi_id)
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record does not exist" do
    test "MPI record does not exist" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "Олександр",
            "last_name" => "Олесь",
            "birth_date" => "1988-08-19",
            "tax_id" => "3126509817",
            "authentication_methods" => [
              %{
                "phone_number" => "+380508887701"
              }
            ]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> Creator.determine_auth_method_for_mpi(DeclarationRequest.channel(:mis))

      assert get_change(changeset, :authentication_method_current) == %{"type" => "NA"}
    end

    test "Gandalf makes a NA decision" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      System.put_env("GNDF_TABLE_ID", "not_available")

      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "Олександр",
            "last_name" => "Олесь",
            "birth_date" => "1988-08-19",
            "tax_id" => "3126509817",
            "authentication_methods" => [
              %{
                "type" => "OTP",
                "phone_number" => "+380508887702"
              }
            ]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> Creator.determine_auth_method_for_mpi(DeclarationRequest.channel(:mis))

      assert %{"type" => "NA"} == get_change(changeset, :authentication_method_current)
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI returns an error" do
    test "MPI returns an error" do
      expect(MPIMock, :search, fn _, _ ->
        {:error, %HTTPoison.Error{reason: :something}}
      end)

      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "test",
            "last_name" => "test",
            "birth_date" => "1990-01-01",
            "phones" => [
              %{
                "number" => "+380508887701"
              }
            ]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> Creator.determine_auth_method_for_mpi(DeclarationRequest.channel(:mis))

      assert ~s(Error during MPI interaction. Result from MPI: :something) ==
               elem(changeset.errors[:authentication_method_current], 0)
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record does not exist (2)" do
    test "authentication_methods OTP converts to NA" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "test",
            "last_name" => "test",
            "birth_date" => "1990-01-01",
            "phones" => [
              %{
                "number" => "+380508887701"
              }
            ],
            "authentication_methods" => [
              %{
                "type" => "OTP",
                "phone_number" => "+380508887701"
              }
            ]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> Creator.determine_auth_method_for_mpi(DeclarationRequest.channel(:mis))

      assert get_change(changeset, :authentication_method_current) == %{"type" => "NA"}
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record with type NA" do
    test "authentication_methods NA converts to OTP" do
      expect(MPIMock, :search, fn params, _ ->
        {:ok,
         %{
           "data" => [
             params
             |> Map.put("authentication_methods", [%{"type" => "NA"}])
           ]
         }}
      end)

      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "test",
            "last_name" => "test",
            "birth_date" => "1990-01-01",
            "phones" => [
              %{
                "number" => "+380508887701"
              }
            ],
            "authentication_methods" => [
              %{
                "type" => "OTP",
                "phone_number" => "+380508887701"
              }
            ]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> Creator.determine_auth_method_for_mpi(DeclarationRequest.channel(:mis))

      assert %{"type" => "OTP", "number" => "+380508887701"} == get_change(changeset, :authentication_method_current)
    end
  end

  describe "send_verification_code/1" do
    defmodule SendingVerificationCode do
      use MicroservicesHelper

      Plug.Router.post "/verifications" do
        code =
          case conn.body_params["phone_number"] do
            "+380991234567" -> 200
            "+380508887700" -> 404
          end

        send_resp(conn, code, Jason.encode!(%{data: ["response_we_don't_care_about"]}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(SendingVerificationCode)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      :ok
    end
  end

  describe "put_party_email/1" do
    defmodule PRMMithrilMock do
      use MicroservicesHelper

      @invalid_party_id "6b4127ea-99ad-4493-b5ce-6f0769fa9fab"
      @invalid_user_id "79d70fe0-00dd-4dc3-b302-c8f3a6f6ad38"
      @user_id "53c63398-7033-47f6-9602-be250e35049e"
      @role_id UUID.generate()

      def user_id, do: @user_id

      # PRM API
      Plug.Router.get "/party_users" do
        party_id = Map.get(conn.query_params, "party_id")

        user_id =
          case party_id do
            @invalid_party_id -> @invalid_user_id
            _ -> @user_id
          end

        party_users = [
          %{
            user_id: user_id
          }
        ]

        Plug.Conn.send_resp(conn, 200, Jason.encode!(%{data: party_users}))
      end

      # Mithril API
      Plug.Router.get "/admin/roles" do
        roles = [
          %{
            "id" => @role_id
          }
        ]

        Plug.Conn.send_resp(conn, 200, Jason.encode!(%{data: roles}))
      end

      Plug.Router.get "/admin/users/#{@invalid_user_id}/roles" do
        Plug.Conn.send_resp(conn, 200, Jason.encode!(%{data: []}))
      end

      Plug.Router.get "/admin/users/#{@user_id}/roles" do
        roles = [
          %{
            "user_id" => @user_id,
            "role_id" => @role_id
          }
        ]

        Plug.Conn.send_resp(conn, 200, Jason.encode!(%{data: roles}))
      end

      Plug.Router.get "/admin/users/#{@user_id}" do
        user = %{
          "email" => "user@email.com"
        }

        Plug.Conn.send_resp(conn, 200, Jason.encode!(%{data: user}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(PRMMithrilMock)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OAUTH_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        System.put_env("OAUTH_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      :ok
    end

    test "user is not doctor" do
      types = %{"data" => :map}
      data = %{"employee" => %{"party" => %{"id" => "6b4127ea-99ad-4493-b5ce-6f0769fa9fab"}}}
      changes = %{data: data}
      errors = [email: {"Current user is not a doctor", []}]

      expected_result = %Ecto.Changeset{
        action: nil,
        changes: changes,
        errors: errors,
        data: data,
        types: types,
        valid?: false
      }

      result = Creator.put_party_email(%Ecto.Changeset{data: data, changes: changes, types: types, valid?: true})
      assert expected_result == result
    end

    test "everything is ok" do
      types = %{"data" => :map}
      party_user = insert(:prm, :party_user, user_id: PRMMithrilMock.user_id())
      data = %{"employee" => %{"party" => %{"id" => party_user.party_id}}}
      expected_changes = %{data: put_in(data, ["employee", "party", "email"], "user@email.com")}
      changes = %{data: data}

      expected_result = %Ecto.Changeset{
        action: nil,
        changes: expected_changes,
        errors: [],
        data: data,
        types: types,
        valid?: true
      }

      result = Creator.put_party_email(%Ecto.Changeset{data: data, changes: changes, types: types, valid?: true})
      assert expected_result == result
    end
  end

  defp get_license(license_number) do
    %{
      "license_number" => license_number,
      "issued_by" => "Кваліфікацйна комісія",
      "issued_date" => "2017-02-28",
      "expiry_date" => "2017-02-28",
      "active_from_date" => "2017-02-28",
      "what_licensed" => "реалізація наркотичних засобів"
    }
  end
end
