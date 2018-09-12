defmodule EHealth.PRMFactories.PartyFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def party_factory do
        %EHealth.Parties.Party{
          first_name: "Петро",
          last_name: "Іванов",
          second_name: "Миколайович",
          birth_date: ~D[1980-09-19],
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
              type: "NATIONAL_ID",
              number: "AA000000",
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

      def party_user_factory do
        %EHealth.PartyUsers.PartyUser{
          user_id: UUID.generate(),
          party: build(:party)
        }
      end
    end
  end
end
