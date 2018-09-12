defmodule EHealth.ILFactories.EmployeeRequestFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID
      alias EHealth.EmployeeRequests.EmployeeRequest, as: Request

      def employee_request_factory do
        %Request{
          data: employee_request_data(),
          employee_id: UUID.generate(),
          status: "NEW"
        }
      end

      def employee_request_data do
        %{
          division_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          legal_entity_id: "8b797c23-ba47-45f2-bc0f-521013e01074",
          position: "лікар",
          start_date: "2017-08-07",
          status: "NEW",
          employee_type: "DOCTOR",
          employment_status: %{},
          employee_category: "SPECIALIST",
          position_level: "SPECIALIST_DOCTOR",
          speciality_nomenclature: "ALLERGIST",
          dk_code: "2221.2",
          party: party(),
          # %{
          #   first_name: "Петро",
          #   last_name: "Іванов",
          #   second_name: "Миколайович",
          #   birth_date: "1991-08-19",
          #   gender: "MALE",
          #   tax_id: "3067305998",
          #   no_tax_id: false,
          #   email: "sp.virny@gmail.com",
          #   birth_country: "UA",
          #   birth_settlement: "Полтава",
          #   birth_settlement_type: "CITY",
          #   citizenship: "UA",
          #   personal_email: "test@gmail.com",
          #   documents: [
          #     %EHealth.Parties.Document{
          #       type: "NATIONAL_ID",
          #       number: "AA000000",
          #       issued_by: "RUVD",
          #       issued_at: ~D[1988-02-02]
          #     }
          #   ],
          #   phones: [
          #     %EHealth.Parties.Phone{
          #       type: "MOBILE",
          #       number: "+380972526080",
          #       public: true
          #     }
          #   ]
          # },
          doctor: doctor_data()
          # doctor: %{
          #   educations: [
          #     %{
          #       country: "UA",
          #       city: "Київ",
          #       institution_name: "Академія Богомольця",
          #       issued_date: "2017-08-01",
          #       diploma_number: "DD123543",
          #       degree: "Молодший спеціаліст",
          #       speciality: "Педіатр"
          #     }
          #   ],
          #   qualifications: [
          #     %{
          #       type: "Інтернатура",
          #       institution_name: "Академія Богомольця",
          #       speciality: "Педіатр",
          #       issued_date: "2017-08-02",
          #       certificate_number: "2017-08-03",
          #       valid_to: "2017-10-10",
          #       additional_info: "additional info"
          #     }
          #   ],
          #   specialities: [
          #     %{
          #       speciality: "Педіатр",
          #       speciality_officio: true,
          #       level: "Перша категорія",
          #       qualification_type: "Присвоєння",
          #       attestation_name: "Академія Богомольця",
          #       attestation_date: "2017-08-04",
          #       valid_to_date: "2017-08-05",
          #       certificate_number: "AB/21331"
          #     }
          #   ],
          #   science_degree: %{
          #     country: "UA",
          #     city: "Київ",
          #     degree: "Доктор філософії",
          #     institution_name: "Академія Богомольця",
          #     diploma_number: "DD123543",
          #     speciality: "Педіатр",
          #     issued_date: "2017-08-05"
          #   }
          # }
        }
      end

      def party do
        %{
          first_name: "Петро",
          last_name: "Іванов",
          second_name: "Миколайович",
          birth_date: ~D[1991-08-19],
          gender: "MALE",
          tax_id: sequence("222222222"),
          no_tax_id: false,
          birth_country: "UA",
          birth_settlement: "Полтава",
          birth_settlement_type: "CITY",
          citizenship: "UA",
          citizenship_at_birth: "UA",
          personal_email: "test@gmail.com",
          language_skills: [
            %EHealth.Parties.LanguageSkill{
              language: "uk",
              language_level: "INTERMEDIATE"
            }
          ],
          retirements: [
            %EHealth.Parties.Retirement{
              type: "DISABILITY",
              date: ~D[2018-01-01]
            }
          ],
          addresses: [
            %EHealth.Parties.Address{
              type: "REGISTRATION",
              country: "UA",
              area: "DP",
              region: "DP",
              settlement: "Дніпро",
              settlement_type: "CITY",
              street: "Sadova",
              street_type: "STREET",
              apartment: "24",
              building: "12",
              zip: "12342"
            }
          ],
          documents: [
            %EHealth.Parties.Document{
              type: "PASSPORT",
              number: "123432",
              issued_by: "RUVD",
              issued_at: ~D[1988-02-02]
            }
          ],
          phones: [
            %EHealth.Parties.Phone{
              type: "MOBILE",
              number: "+380972526080",
              public: true
            }
          ],
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      def doctor_data do
        %{
          science_degree: %{
            academic_status: "PHD",
            degree_country: "UA",
            degree_city: "Київ",
            degree_institution_name: "Академія Богомольця",
            degree_science_domain: "PHYSICS",
            science_domain: "BIOLOGY",
            speciality_group: "CLINICAL",
            code: "14.01.2003",
            country: "UA",
            city: "Kyiv",
            degree: "Доктор філософії",
            institution_name: "random string",
            diploma_number: "random string",
            speciality: "random string",
            issued_date: ~D[1987-04-17]
          },
          qualifications: [
            %{
              related_to: %{
                type: "HIV",
                sub_type: "RESERVED"
              },
              course_name: "Новітні методи у хірургії",
              form: "FULL_TIME",
              duration: "2",
              duration_units: "WEEK",
              results: 0.82,
              start_date: ~D"2017-06-01",
              end_date: ~D"2017-06-15",
              valid_to: ~D"2017-10-10",
              additional_info: "additional info",
              type: "Інтернатура",
              institution_name: "random string",
              speciality: "Педіатр",
              certificate_number: "random string",
              issued_date: ~D[1987-04-17]
            }
          ],
          educations: [
            %{
              speciality: "Біологія",
              speciality_code: "091",
              form: "FULL_TIME",
              legalized: true,
              legalizations: [
                %{
                  issued_date: ~D"1988-04-23",
                  number: "AC438942",
                  institution_name: "American Institute of Chemists"
                }
              ],
              country: "UA",
              city: "Kyiv",
              degree: "Молодший спеціаліст",
              institution_name: "random string",
              diploma_number: "random string",
              speciality: "random string",
              issued_date: ~D[1987-04-17]
            }
          ],
          specialities: [build(:speciality)]
        }
      end
    end
  end
end
