defmodule EHealth.Parties do
  @moduledoc false

  use EHealth.Search, EHealth.PRMRepo

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.Parties.{Party, Search}

  # Party users

  @search_fields ~w(
    tax_id
    no_tax_id
    first_name
    second_name
    last_name
    birth_date
    phone_number
  )a

  @fields_optional ~w(
    second_name
    declaration_limit
    about_myself
    working_experience
    citizenship_at_birth
    personal_email
    no_tax_id
  )a

  @fields_required ~w(
    birth_country
    birth_settlement
    birth_settlement_type
    citizenship
    first_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )a

  @embed_required ~w(
    addresses
  )a

  @assoc_required ~w{
    educations
    specialities
  }a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Party)
  end

  def get_by_id!(id) do
    Party
    |> PRMRepo.get!(id)
    |> PRMRepo.preload(
      educations: [:legalizations],
      phones: [],
      addresses: [],
      documents: [],
      qualifications: [],
      specialities: [],
      science_degrees: [],
      users: []
    )

    # |> where([p], p.id == ^id)
    # |> join(:left, [p], u in assoc(p, :users))
    # |> join(:left, [p], ph in assoc(ph, :phones))
    # |> preload([p, u, ph], users: u, phones: ph)
    # |> PRMRepo.one!()
  end

  def get_by_id(id) do
    Party
    |> PRMRepo.get(id)
    |> PRMRepo.preload(
      educations: [:legalizations],
      phones: [],
      addresses: [],
      documents: [],
      qualifications: [],
      specialities: [],
      science_degrees: [],
      users: []
    )
  end

  def get_by_ids(ids) do
    Party
    |> where([e], e.id in ^ids)
    |> PRMRepo.all()
    |> PRMRepo.preload(
      educations: [:legalizations],
      phones: [],
      addresses: [],
      documents: [],
      qualifications: [],
      specialities: [],
      science_degrees: [],
      users: []
    )
  end

  def get_by_user_id(user_id) do
    Party
    |> join(:inner, [p], u in assoc(p, :users))
    |> where([..., u], u.user_id == ^user_id)
    |> PRMRepo.one()
  end

  def get_user_ids_by_tax_id(tax_id) do
    Party
    |> where([e], e.tax_id == ^tax_id)
    |> join(:inner, [p], u in assoc(p, :users))
    |> select([..., u], u.user_id)
    |> PRMRepo.all()
  end

  def get_tax_id_by_user_id(user_id) do
    Party
    |> join(:inner, [p], u in assoc(p, :users))
    |> where([..., u], u.user_id == ^user_id)
    |> select([p], p.tax_id)
    |> PRMRepo.one()
  end

  def create(attrs, consumer_id) do
    with {:ok, party} <-
           %Party{}
           |> changeset(attrs)
           |> PRMRepo.insert_and_log(consumer_id) do
      {:ok, load_references(party)}
    end
  end

  def update(%Party{} = party, attrs, consumer_id) do
    with {:ok, party} <-
           party
           |> changeset(attrs)
           |> PRMRepo.update_and_log(consumer_id) do
      {:ok, load_references(party)}
    end
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end

  def changeset(%Party{} = party, attrs) do
    party
    |> PRMRepo.preload([
      :phones,
      :addresses,
      :documents,
      :specialities,
      :qualifications,
      :educations,
      :science_degrees
    ])
    |> PRMRepo.preload(educations: [:legalizations])
    |> cast(attrs, @fields_optional ++ @fields_required)
    |> cast_assoc(:phones)
    |> cast_assoc(:documents)
    |> cast_assoc(:addresses)
    |> cast_assoc(:educations)
    |> cast_assoc(:specialities)
    |> cast_assoc(:qualifications)
    |> cast_assoc(:science_degrees)
    |> cast_embed(:language_skills)
    |> cast_embed(:retirements)
    |> validate_required(@fields_required ++ @embed_required)
  end

  def get_search_query(Party = entity, %{phone_number: number} = changes) do
    params =
      changes
      |> Map.delete(:phone_number)
      |> Map.to_list()

    phone_number = [%{"number" => number}]

    entity
    |> where(^params)
    |> where([e], fragment("? @> ?", e.phones, ^phone_number))
    |> load_references()
  end

  def get_search_query(entity, changes) do
    entity
    |> super(changes)
    |> load_references()
  end

  defp load_references(%Ecto.Query{} = query) do
    query
    |> preload(
      users: [],
      educations: [:legalizations],
      phones: [],
      addresses: [],
      documents: [],
      qualifications: [],
      specialities: [],
      science_degrees: []
    )
  end

  defp load_references(%Party{} = party) do
    party
    |> PRMRepo.preload(
      users: [],
      educations: [:legalizations],
      phones: [],
      addresses: [],
      documents: [],
      qualifications: [],
      specialities: [],
      science_degrees: []
    )
  end
end
