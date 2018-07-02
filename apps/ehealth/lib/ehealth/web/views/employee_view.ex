defmodule EHealth.Web.EmployeeView do
  @moduledoc false

  use EHealth.Web, :view

  alias EHealth.Web.PartyView
  alias EHealth.Parties.Party
  alias EHealth.Divisions.Division
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees.Employee

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  def render("index.json", %{employees: employees, declaration_count_data: declaration_count_data}) do
    Enum.map(employees, fn employee ->
      render_one(employee, __MODULE__, "employee_list.json", %{
        employee: employee,
        declaration_count_data: declaration_count_data
      })
    end)
  end

  def render("employee_list.json", %{employee: employee, declaration_count_data: declaration_count_data}) do
    declaration_count = Enum.find(declaration_count_data, &(Map.get(&1, "id") == employee.party.id))

    party =
      employee.party
      |> Map.take(~w(id first_name second_name last_name no_tax_id declaration_limit)a)
      |> Map.put(:declaration_count, declaration_count["declaration_count"])

    employee
    |> Map.take(~w(
      id
      position
      employee_type
      status
      start_date
      end_date
    )a)
    |> Map.put(:party, party)
    |> render_association(employee.division)
    |> render_association(employee.legal_entity)
    |> put_list_info(employee)
  end

  def render("employee_short.json", %{"employee" => employee}) do
    %{
      "id" => Map.get(employee, "id"),
      "position" => Map.get(employee, "position"),
      "party" => render(PartyView, "party_short.json", Map.take(employee, ["party"]))
    }
  end

  def render("employee_short.json", %{employee: employee}) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => render(PartyView, "party_short.json", %{party: employee.party})
    }
  end

  def render("employee_short.json", _), do: %{}

  def render("employee_private.json", %{employee: employee}) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => render(PartyView, "party_private.json", %{party: employee.party})
    }
  end

  def render("employee_private.json", _), do: %{}

  def render("employee.json", %{employee: %{employee_type: @doctor, additional_info: info} = employee} = assigns) do
    employee
    |> render_employee(Map.get(assigns, :declaration_count_data))
    |> render_doctor(Map.put(info, "specialities", get_employee_specialities(employee)))
  end

  def render("employee.json", %{employee: %{employee_type: @pharmacist, additional_info: info} = employee} = assigns) do
    employee
    |> render_employee(Map.get(assigns, :declaration_count_data))
    |> render_pharmacist(Map.put(info, "specialities", get_employee_specialities(employee)))
  end

  def render("employee.json", %{employee: employee} = assigns) do
    render_employee(employee, Map.get(assigns, :declaration_count_data))
  end

  def render_employee(employee, declaration_count_data) do
    employee
    |> Map.take(~w(
      id
      position
      status
      employee_type
      start_date
      end_date
      declaration_limit
    )a)
    |> render_association(employee.party, declaration_count_data)
    |> render_association(employee.division)
    |> render_association(employee.legal_entity)
  end

  defp render_association(map, %Party{} = party, declaration_count_data) when is_list(declaration_count_data) do
    data = Map.take(party, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      birth_country
      birth_settlement
      gender
      tax_id
      no_tax_id
      documents
      phones
      addresses
      about_myself
      working_experience
      declaration_limit
    )a)

    declaration_count = Enum.find(declaration_count_data, &(Map.get(&1, "id") == party.id))
    data = Map.put(data, :declaration_count, declaration_count["declaration_count"])
    Map.put(map, :party, data)
  end

  defp render_association(map, %Party{} = party, _), do: render_association(map, party, [])

  defp render_association(map, %Division{} = division) do
    data = Map.take(division, ~w(
      id
      name
      status
      type
      legal_entity_id
      mountain_group
    )a)
    Map.put(map, :division, data)
  end

  defp render_association(map, %LegalEntity{} = legal_entity) do
    data = Map.take(legal_entity, ~w(
      id
      name
      short_name
      public_name
      type
      edrpou
      status
      owner_property_type
      legal_form
      mis_verified
    )a)
    Map.put(map, :legal_entity, data)
  end

  defp render_association(map, _), do: map

  defp render_doctor(map, info) do
    Map.put(map, :doctor, info)
  end

  defp render_pharmacist(map, info) do
    Map.put(map, :pharmacist, info)
  end

  defp put_list_info(map, %Employee{employee_type: @doctor} = employee) do
    Map.put(map, :doctor, %{"specialities" => Map.get(employee.additional_info, "specialities")})
  end

  defp put_list_info(map, %Employee{employee_type: @pharmacist} = employee) do
    Map.put(map, :pharmacist, %{"specialities" => Map.get(employee.additional_info, "specialities")})
  end

  defp put_list_info(map, _), do: map

  defp get_employee_specialities(employee) do
    speciality = employee.speciality
    party_specialities = employee.party.specialities || []

    party_specialities =
      party_specialities
      |> Enum.filter(&(Map.get(&1, "speciality") != speciality["speciality"]))
      |> Enum.map(&Map.put(&1, "speciality_officio", false))

    case speciality do
      nil -> party_specialities
      speciality -> [speciality | party_specialities]
    end
  end
end
