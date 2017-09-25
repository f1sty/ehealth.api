defmodule EHealth.LegalEntity.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  import Ecto.Changeset

  alias EHealth.API.Signature
  alias EHealth.Validators.KVEDs
  alias EHealth.LegalEntity.Request
  alias EHealth.Validators.TaxID
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.BirthDate
  alias EHealth.Validators.JsonSchema

  def decode_and_validate(params) do
    params
    |> validate_sign_content()
    |> validate_json()
  end

  def validate_sign_content(content) do
    content
    |> validate_request()
    |> validate_signature()
    |> normalize_signature_error()
  end

  def validate_json({:ok, %{"data" => %{"is_valid" => false}}}) do
    {:error, {:bad_request, "Signed request data is invalid"}}
  end
  def validate_json({:ok, %{"data" => %{"content" => content} = data}}) do
    with :ok <- validate_schema(content),
         :ok <- validate_kveds(content),
         :ok <- validate_addresses(content),
         :ok <- validate_tax_id(content),
         :ok <- validate_birth_date(content),
         :ok <- validate_edrpou(content, Map.get(data, "signer"))
    do
      :ok
    end
  end
  def validate_json(err), do: err

  # Request validator

  def validate_request(params) do
    fields = ~W(
      signed_legal_entity_request
      signed_content_encoding
    )a

    %Request{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}) do
    changes
    |> Map.get(:signed_legal_entity_request)
    |> Signature.decode_and_validate(Map.get(changes, :signed_content_encoding))
  end
  def validate_signature(err), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %Request{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, error)
  end
  def normalize_signature_error(ok_resp), do: ok_resp

  # Legal Entity content validator

  def validate_schema(content) do
    JsonSchema.validate(:legal_entity, content)
  end

  def validate_kveds(content) do
    content
    |> Map.get("kveds")
    |> KVEDs.validate(content["type"])
    |> case do
         %Ecto.Changeset{valid?: false} = err -> {:error, err}
         _ -> :ok
       end
  end

  # Addresses validator

  def validate_addresses(content) do
    content
    |> Map.get("addresses")
    |> Addresses.validate()
    |> case do
         {:ok, _} -> :ok
         err -> err
       end
  end

  # Tax ID validator

  def validate_tax_id(content) do
    content
    |> get_in(["owner", "tax_id"])
    |> TaxID.validate()
    |> case do
         true -> :ok
         _ ->
          {:error, [{%{
            description: "invalid tax_id value",
            params: [],
            rule: :invalid
          }, "$.owner.tax_id"}]}
       end
  end

  # EDRPOU validator

  def validate_edrpou(content, signer) do
    data  = %{}
    types = %{edrpou: :string}

    {data, types}
    |> cast(signer, Map.keys(types))
    |> validate_required(Map.keys(types))
    |> validate_format(:edrpou, ~r/^[0-9]{8,10}$/)
    |> validate_inclusion(:edrpou, [Map.fetch!(content, "edrpou")])
    |> prepare_legal_entity(content)
  end

  def validate_birth_date(content) do
    content
    |> get_in(["owner", "birth_date"])
    |> BirthDate.validate()
    |> case do
         true -> :ok
         _ ->
          {:error, [{%{
            description: "invalid birth_date value",
            params: [],
            rule: :invalid
          }, "$.owner.birth_date"}]}
       end
  end

  defp prepare_legal_entity(%Ecto.Changeset{valid?: true}, legal_entity), do: {:ok, legal_entity}
  defp prepare_legal_entity(changeset, _legal_entity), do: {:error, changeset}
end
