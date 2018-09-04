defmodule EHealth.PRMFactories.EmployeeFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def employee_factory do
        division = build(:division)
        party = build(:party)

        %EHealth.Employees.Employee{
          is_active: true,
          position: "some position",
          status: "APPROVED",
          employee_type: "DOCTOR",
          end_date: ~D[2012-04-17],
          start_date: ~D[2017-08-07],
          employment_status: %{},
          employee_category: "SPECIALIST",
          position_level: "SPECIALIST_DOCTOR",
          speciality_nomenclature: "ALLERGIST",
          dk_code: "2221.2",
          party: party,
          division: division,
          legal_entity_id: division.legal_entity.id,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          additional_info: doctor(),
          speciality: speciality()
        }
      end

      def doctor do
        %{
          "science_degree" => %{
            "academic_status" => "PHD",
            "degree_country" => "UA",
            "degree_city" => "Київ",
            "degree_institution_name" => "Академія Богомольця",
            "degree_science_domain" => "PHYSICS",
            "science_domain" => "BIOLOGY",
            "speciality_group" => "CLINICAL",
            "code" => "14.01.2003",
            "country" => "UA",
            "city" => "Kyiv",
            "degree" => Enum.random(doctor_science_degrees()),
            "institution_name" => "random string",
            "diploma_number" => "random string",
            "speciality" => "random string",
            "issued_date" => ~D[1987-04-17]
          },
          "qualifications" => [
            %{
              "related_to" => %{
                "type" => "HIV",
                "sub_type" => "RESERVED"
              },
              "course_name" => "Новітні методи у хірургії",
              "form" => "FULL_TIME",
              "duration" => "2",
              "duration_units" => "WEEKS",
              "results" => 0.82,
              "start_date" => ~D"2017-06-01",
              "end_date" => ~D"2017-06-15",
              "valid_to" => ~D"2017-10-10",
              "additional_info" => "additional info",
              "type" => Enum.random(doctor_types()),
              "institution_name" => "random string",
              "speciality" => Enum.random(doctor_specialities()),
              "certificate_number" => "random string",
              "issued_date" => ~D[1987-04-17]
            }
          ],
          "educations" => [
            %{
              "speciality" => "Біологія",
              "speciality_code" => "091",
              "form" => "FULL_TIME",
              "legalized" => true,
              "legalizations" => [
                %{
                  "issued_date" => ~D"1988-04-23",
                  "number" => "AC438942",
                  "institution_name" => "American Institute of Chemists"
                }
              ],
              "country" => "UA",
              "city" => "Kyiv",
              "degree" => Enum.random(doctor_degrees()),
              "institution_name" => "random string",
              "diploma_number" => "random string",
              "speciality" => "random string",
              "issued_date" => ~D[1987-04-17]
            }
          ],
          "specialities" => [speciality()]
        }
      end

      def speciality do
        %{
          "order_date" => ~D"2016-02-12",
          "order_number" => "X23454",
          "order_institution_name" => "Богомольця",
          "attestation_results" => "BA",
          "speciality" => Enum.random(doctor_specialities()),
          "speciality_officio" => true,
          "level" => Enum.random(doctor_levels()),
          "qualification_type" => Enum.random(doctor_qualification_types()),
          "attestation_name" => "random string",
          "attestation_date" => ~D[1987-04-17],
          "valid_to_date" => ~D[1987-04-17],
          "certificate_number" => "random string"
        }
      end

      defp doctor_degrees do
        [
          "Молодший спеціаліст",
          "Бакалавр",
          "Спеціаліст",
          "Магістр"
        ]
      end

      defp doctor_science_degrees do
        [
          "Доктор філософії",
          "Кандидат наук",
          "Доктор наук"
        ]
      end

      defp doctor_specialities do
        [
          "THERAPIST",
          "PEDIATRICIAN",
          "FAMILY_DOCTOR"
        ]
      end

      defp doctor_levels do
        [
          "Друга категорія",
          "Перша категорія",
          "Вища категорія"
        ]
      end

      defp doctor_qualification_types do
        [
          "Присвоєння",
          "Підтвердження"
        ]
      end

      defp doctor_types do
        [
          "Інтернатура",
          "Спеціалізація",
          "Передатестаційний цикл",
          "Тематичне вдосконалення",
          "Курси інформації",
          "Стажування"
        ]
      end
    end
  end
end
