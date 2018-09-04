defmodule EHealth.PRMFactories.SpecialityFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def speciality_factory do
        %EHealth.Parties.Speciality{
          order_date: ~D"2016-02-12",
          order_number: "X23454",
          order_institution_name: "Богомольця",
          attestation_results: "BA",
          speciality: "Педіатр",
          speciality_officio: true,
          level: "Перша категорія",
          qualification_type: "Присвоєння",
          attestation_name: "random string",
          attestation_date: ~D[1987-04-17],
          valid_to_date: ~D[1987-04-17],
          certificate_number: "random string"
        }
      end
    end
  end
end
