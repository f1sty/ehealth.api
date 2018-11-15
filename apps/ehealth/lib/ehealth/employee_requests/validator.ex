defmodule EHealth.EmployeeRequests.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  alias EHealth.Validators.TaxID
  alias EHealth.Validators.BirthDate
  alias EHealth.Employees.Employee
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries
  alias EHealth.Email.Sanitizer
  alias EHealth.Validators.Addresses

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)
  @validation_dictionaries ["DOCUMENT_TYPE", "PHONE_TYPE"]
  @required_address_type "REGISTRATION"

  def validate(params, headers) do
    with :ok <- JsonSchema.validate(:employee_request, params),
         params <- lowercase_email(params),
         :ok <- validate_additional_info(Map.get(params, "employee_request")),
         :ok <- validate_legalized(Map.get(params, "employee_request")),
         :ok <- validate_json_objects(params),
         :ok <- validate_tax_id(params),
         :ok <- validate_birth_date(params),
         :ok <- validate_addresses(params, headers),
         :ok <- validate_provided_services_subtypes(params),
         do: {:ok, params}
  end

  defp validate_legalized(%{"employee_type" => @doctor, "doctor" => %{"educations" => data}}) do
    data
    |> Stream.map(fn education -> get_in(education, ["legalized"]) |> validate_legalizations(education) end)
    |> Enum.find(&Kernel.!=(&1, :ok))
    |> case do
      nil -> :ok
      error -> error
    end
  end

  defp validate_legalized(_), do: :ok

  defp validate_legalizations(true, data) do
    case get_in(data, ["legalizations"]) do
      nil -> cast_error("education is legalized, legalizations must be set", "$.employee_request.doctor.educations.legalizations", :required)
      _ -> :ok
    end
  end

  defp validate_legalizations(false, data) do
    case get_in(data, ["legalizations"]) do
      nil -> :ok
      _ -> cast_error("education is not legalized, legalizations must be absent", "$.employee_request.doctor.educations.legalizations", :required)
    end
  end
    
  defp validate_additional_info(%{"employee_type" => @doctor, "doctor" => data}) do
    validate_additional_info(data, String.downcase(@doctor))
  end

  defp validate_additional_info(%{"employee_type" => @pharmacist, "pharmacist" => data}) do
    validate_additional_info(data, String.downcase(@pharmacist))
  end

  defp validate_additional_info(%{"employee_type" => @doctor}) do
    cast_error("required property doctor was not present", "$.employee_request.doctor", :required)
  end

  defp validate_additional_info(%{"employee_type" => @pharmacist}) do
    cast_error("required property pharmacist was not present", "$.employee_request.pharmacist", :required)
  end

  defp validate_additional_info(%{"employee_type" => _, "doctor" => _}) do
    cast_error("field doctor is not allowed", "$.employee_request.doctor", :invalid)
  end

  defp validate_additional_info(%{"employee_type" => _, "pharmacist" => _}) do
    cast_error("field pharmacist is not allowed", "$.employee_request.pharmacist", :invalid)
  end

  defp validate_additional_info(_), do: :ok

  defp validate_additional_info(additional_info, employee_type) do
    json_schema = String.to_atom("employee_#{employee_type}")

    with :ok <- JsonSchema.validate(json_schema, additional_info),
         {:ok, speciality} <- validate_and_fetch_speciality_officio(additional_info["specialities"]),
         :ok <- validate_speciality(speciality, employee_type) do
      :ok
    else
      {:error, message} when is_binary(message) ->
        cast_error(message, "$.employee_request.#{employee_type}.specialities", :invalid)

      err ->
        err
    end
  end

  defp validate_addresses(params, headers) do
    addresses = get_in(params, ~w(employee_request party addresses))
    Addresses.validate(addresses, @required_address_type, headers)
  end

  defp validate_provided_services_subtypes(params) do
    results = get_in(params, ~w(employee_request provided_services))
    |> Enum.map(fn service -> validate_provided_service_subtype(service["type"], service["sub_types"]) end)
    case Enum.all?(results, &Kernel.==(&1, :ok)) do
      true -> :ok
      _ -> cast_error("forbidden sub_type for provided service type", "$.employee_request.provided_services.sub_types.title", :invalid)
    end
  end

  defp validate_provided_service_subtype(type, sub_types) do
    sub_types 
    |> Enum.map(fn sub_type -> sub_type["title"] end)
    |> MapSet.new
    |> MapSet.subset?(allowed_provided_service_subtypes(type)) 
    |> case do
      true -> :ok
      _ -> :error
    end
  end

  defp validate_and_fetch_speciality_officio(specialities) do
    case Enum.filter(specialities, fn speciality -> Map.get(speciality, "speciality_officio") end) do
      [speciality] -> {:ok, speciality}
      [] -> {:error, "employee doesn't have speciality with active speciality_officio"}
      _ -> {:error, "employee have more than one speciality with active speciality_officio"}
    end
  end

  defp validate_speciality(%{"speciality" => speciality}, employee_type) do
    allowed_specialities = Confex.fetch_env!(:ehealth, :employee_specialities_types)[String.to_atom(employee_type)]

    case speciality in allowed_specialities do
      true -> :ok
      _ -> {:error, "speciality #{speciality} with active speciality_officio is not allowed for #{employee_type}"}
    end
  end

  defp validate_json_objects(params) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
         docs_path = ["employee_request", "party", "documents"],
         :ok <- validate_non_req_parameteter(params, docs_path, "type", doc_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         ph_path = ["employee_request", "party", "phones"],
         :ok <- validate_non_req_parameteter(params, ph_path, "type", phone_types),
          do: :ok
  end

  defp validate_non_req_parameteter(params, path, key_name, valid_types) do
    elements = get_in(params, path)

    if elements != nil and elements != [] do
      JsonObjects.array_unique_by_key(params, path, key_name, valid_types)
    else
      :ok
    end
  end

  defp validate_tax_id(content) do
    no_tax_id = get_in(content, ~w(employee_request party no_tax_id))

    content
    |> get_in(~w(employee_request party tax_id))
    |> TaxID.validate(no_tax_id)
    |> case do
      true -> :ok
      _ -> cast_error("invalid tax_id value", "$.employee_request.party.tax_id", :invalid)
    end
  end

  defp validate_birth_date(content) do
    content
    |> get_in(~w(employee_request party birth_date))
    |> BirthDate.validate()
    |> case do
      true -> :ok
      _ -> cast_error("invalid birth_date value", "$.employee_request.party.birth_date", :invalid)
    end
  end

  defp cast_error(message, path, rule) do
    {:error,
     [
       {%{
          description: message,
          params: [],
          rule: rule
        }, path}
     ]}
  end

  defp lowercase_email(params) do
    path = ~w(employee_request party email)
    email = get_in(params, path)
    put_in(params, path, Sanitizer.sanitize(email))
  end

  defp allowed_provided_service_subtypes(type) do
    Dictionaries.get_dictionaries(["PROVIDED_SERVICE_SUBTYPE"])
    |> Map.get("PROVIDED_SERVICE_SUBTYPE")
    |> Map.keys
    |> Enum.filter(&String.starts_with?(&1, type))
    |> MapSet.new
  end
end
