defmodule EHealth.PRMFactories.DivisionFactory do
  @moduledoc false

  alias EHealth.Divisions.Division
  alias EHealth.Divisions.DivisionAddress

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def division_factory do
        division_id = UUID.generate()

        %Division{
          id: division_id,
          legal_entity: build(:legal_entity),
          addresses: [address()],
          division_addresses: [
            build(:division_address, division_id: division_id, type: "REGISTRATION"),
            build(:division_address, division_id: division_id)
          ],
          phones: [],
          external_id: "7ae4bbd6-a9e7-4ce0-992b-6a1b18a262dc",
          type: Division.type(:clinic),
          email: "some@local.com",
          name: "some",
          status: Division.status(:active),
          mountain_group: false,
          location: %Geo.Point{coordinates: {50, 20}}
        }
      end

      def division_address_factory do
        %DivisionAddress{
          building: "15",
          apartment: "23",
          zip: "02090",
          area: "ЛЬВІВСЬКА",
          country: "UA",
          region: "ПУСТОМИТІВСЬКИЙ",
          settlement_type: "CITY",
          settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          street: "вул. Ніжинська",
          settlement: "СОРОКИ-ЛЬВІВСЬКІ",
          type: "RESIDENCE",
          street_type: "STREET"
        }
      end

      defp address do
        %{
          "building" => "15",
          "apartment" => "23",
          "zip" => "02090",
          "area" => "ЛЬВІВСЬКА",
          "country" => "UA",
          "region" => "ПУСТОМИТІВСЬКИЙ",
          "settlement_type" => "CITY",
          "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          "street" => "вул. Ніжинська",
          "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
          "type" => "RESIDENCE",
          "street_type" => "STREET"
        }
      end
    end
  end
end
