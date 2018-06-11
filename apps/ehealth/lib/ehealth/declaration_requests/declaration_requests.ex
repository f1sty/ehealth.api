defmodule EHealth.DeclarationRequests do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query
  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]

  alias EHealth.API.Mithril
  alias EHealth.Divisions.Division
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.DeclarationRequests.API.Approve
  alias EHealth.DeclarationRequests.API.Creator
  alias EHealth.DeclarationRequests.API.Documents
  alias EHealth.DeclarationRequests.API.ResendOTP
  alias EHealth.DeclarationRequests.API.Sign
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.LegalEntities
  alias EHealth.Repo
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.Reference
  alias Ecto.Multi
  alias EHealth.Email.Sanitizer
  alias EHealth.Persons.Validator, as: PersonsValidator

  @channel_cabinet DeclarationRequest.channel(:cabinet)
  @channel_mis DeclarationRequest.channel(:mis)

  @status_new DeclarationRequest.status(:new)
  @status_rejected DeclarationRequest.status(:rejected)
  @status_approved DeclarationRequest.status(:approved)

  @fields_optional ~w(
    data
    status
    documents
    authentication_method_current
    printout_content
    inserted_by
    updated_by
    mpi_id
  )a

  def list(params) do
    DeclarationRequest
    |> order_by([dr], desc: :inserted_at)
    |> filter_by_employee_id(params)
    |> filter_by_legal_entity_id(params)
    |> filter_by_status(params)
    |> Repo.paginate(params)
  end

  defp filter_by_employee_id(query, %{"employee_id" => employee_id}) do
    where(query, [r], fragment("?->'employee'->>'id' = ?", r.data, ^employee_id))
  end

  defp filter_by_employee_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end

  defp filter_by_status(query, _), do: query

  def approve(id, verification_code, headers) do
    user_id = get_consumer_id(headers)

    with declaration_request <- get_by_id!(id),
         :ok <- validate_channel(declaration_request, @channel_mis),
         updates <-
           changeset(declaration_request, %{
             status: @status_approved,
             updated_by: user_id
           }),
         :ok <- validate_status_transition(updates) do
      Multi.new()
      |> Multi.run(:verification, fn _ -> Approve.verify(declaration_request, verification_code, headers) end)
      |> Multi.update(:declaration_request, updates)
      |> Repo.transaction()
    end
  end

  def approve(id, headers) do
    user_id = get_consumer_id(headers)

    with declaration_request <- get_by_id!(id),
         :ok <- validate_channel(declaration_request, @channel_cabinet),
         {:ok, %{"data" => user}} <- Mithril.get_user_by_id(user_id, headers),
         :ok <- check_user_person_id(user, declaration_request.mpi_id),
         {:ok, person} <- Reference.validate(:person, declaration_request.mpi_id),
         :ok <- validate_tax_id(user["tax_id"], person["tax_id"]),
         updates <-
           changeset(declaration_request, %{
             status: @status_approved,
             updated_by: user_id
           }),
         :ok <- validate_status_transition(updates) do
      Multi.new()
      |> Multi.run(:verification, fn _ -> Approve.verify(declaration_request, headers) end)
      |> Multi.update(:declaration_request, updates)
      |> Repo.transaction()
    end
  end

  def reject(id, user_id) do
    with %DeclarationRequest{} = declaration_request <- get_by_id!(id),
         updates <-
           declaration_request
           |> change
           |> put_change(:status, @status_rejected)
           |> put_change(:updated_by, user_id),
         :ok <- validate_status_transition(updates) do
      Repo.update(updates)
    end
  end

  defdelegate sign(params, headers), to: Sign
  defdelegate resend_otp(id, headers), to: ResendOTP

  def get_documents(declaration_id) do
    DeclarationRequest
    |> where([dr], dr.declaration_id == ^declaration_id)
    |> Repo.one!()
    |> Documents.generate_links()
  end

  defp validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {@status_new, @status_rejected},
      {@status_approved, @status_rejected},
      {@status_new, @status_approved}
    ]

    if {from, to} in valid_transitions do
      :ok
    else
      {:error, {:conflict, "Invalid transition"}}
    end
  end

  def get_by_id!(id), do: get_by_id!(id, %{})
  def get_by_id!(id, nil), do: get_by_id!(id, %{})

  def get_by_id!(id, params) do
    p =
      DeclarationRequest
      |> where([dr], dr.id == ^id)
      |> Repo.one!()

    if Enum.empty?(p.data) do
      p
    else
      if p.data["legal_entity"]["id"] == params["legal_entity_id"] do
        p
      else
        nil
      end
    end
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->'legal_entity'->>'id' = ?", r.data, ^legal_entity_id))
  end

  defp filter_by_legal_entity_id(query, _), do: query

  def create_offline(params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    # TODO: double check user_id/client_id has access to create given employee/legal_entity
    with :ok <- JsonSchema.validate(:declaration_request, %{"declaration_request" => params}),
         params <- lowercase_email(params),
         :ok <- PersonsValidator.validate(params["person"]),
         :ok <- Addresses.validate(get_in(params, ["person", "addresses"]), "REGISTRATION", headers),
         {:ok, %Employee{} = employee} <-
           Reference.validate(:employee, params["employee_id"], "$.declaration_request.employee_id"),
         :ok <- Creator.validate_employee_status(employee),
         :ok <- Creator.validate_employee_speciality(employee),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(client_id),
         {:ok, %Division{} = division} <-
           Reference.validate(:division, params["division_id"], "$.declaration_request.division_id") do
      data = Map.put(params, "channel", DeclarationRequest.channel(:mis))
      Creator.create(data, user_id, params["person"], employee, division, legal_entity, headers)
    end
  end

  def create_online(params, headers) do
    user_id = get_consumer_id(headers)
    params = Map.delete(params, "legal_entity_id")

    with :ok <- JsonSchema.validate(:cabinet_declaration_request, params),
         {:ok, %{"data" => user}} <- Mithril.get_user_by_id(user_id, headers),
         :ok <- check_user_person_id(user, params["person_id"]),
         {:ok, person} <- Reference.validate(:person, params["person_id"]),
         {:ok, %Employee{} = employee} <- Reference.validate(:employee, params["employee_id"]),
         :ok <- Creator.validate_employee_status(employee),
         :ok <- Creator.validate_employee_speciality(employee),
         {:ok, %Division{} = division} <- Reference.validate(:division, params["division_id"]),
         {:ok, %LegalEntity{} = legal_entity} <- Reference.validate(:legal_entity, division.legal_entity_id),
         :ok <- validate_tax_id(user["tax_id"], person["tax_id"]) do
      data =
        params
        |> Map.put("person", person)
        |> Map.put("employee", employee)
        |> Map.put("channel", DeclarationRequest.channel(:cabinet))

      Creator.create(data, user_id, person, employee, division, legal_entity, headers)
    end
  end

  defp validate_tax_id(user_tax_id, person_tax_id) do
    if user_tax_id == person_tax_id do
      :ok
    else
      {:error, {:"422", "Invalid person"}}
    end
  end

  defp check_user_person_id(user, person_id) do
    if user["person_id"] == person_id do
      :ok
    else
      {:error, :forbidden}
    end
  end

  def changeset(%DeclarationRequest{} = declaration_request, params) do
    cast(declaration_request, params, @fields_optional)
  end

  defp lowercase_email(params) do
    path = ~w(person email)
    email = get_in(params, path)
    put_in(params, path, Sanitizer.sanitize(email))
  end

  defp validate_channel(%DeclarationRequest{channel: @channel_mis}, @channel_cabinet) do
    {:error, {:forbidden, "Declaration request should be approved by Doctor"}}
  end

  defp validate_channel(%DeclarationRequest{channel: @channel_cabinet}, @channel_mis) do
    {:error, {:forbidden, "Declaration request should be approved by Patient"}}
  end

  defp validate_channel(_, _), do: :ok
end
