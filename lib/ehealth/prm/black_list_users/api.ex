defmodule EHealth.PRM.BlackListUsers do
  @moduledoc false

  use EHealth.PRM.Search

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias Scrivener.Page
  alias EHealth.PRMRepo
  alias EHealth.PRM.Parties
  alias EHealth.PRM.Parties.Schema, as: Party
  alias EHealth.API.Mithril
  alias EHealth.PRM.BlackListUsers.Search
  alias EHealth.PRM.BlackListUsers.Schema, as: BlackListUser

  @fields_required [:tax_id]
  @fields_optional [:is_active]

  def list(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- changeset(%Search{}, params),
         paging <- search(changeset, params, BlackListUser),
         users <- paging.entries,
         tax_ids = Enum.map(users, &(Map.get(&1, :tax_id)))
    do
      parties =
      Party
      |> where([p], p.tax_id in ^tax_ids)
      |> PRMRepo.all
      |> Enum.group_by(&Map.get(&1, :tax_id))

      users = Enum.map(users, fn user ->
        Map.put(user, :parties, Map.get(parties, user.tax_id))
      end)

      %Page{paging | entries: users}
    end
  end

  def get_by_id!(id), do: PRMRepo.get!(BlackListUser, id)

  def get_by(params), do: PRMRepo.get_by(BlackListUser, params)

  def blacklisted?(tax_id) do
    case get_by(%{tax_id: tax_id, is_active: true}) do
      nil -> false
      _ -> true
    end
  end

  def create(headers, %{"tax_id" => tax_id}) do
    user_id = get_consumer_id(headers)
    case get_by(%{tax_id: tax_id, is_active: true}) do
      nil ->
        user_ids =
          tax_id
          |> Parties.get_user_ids_by_tax_id()
          |> Enum.join(",")

        %BlackListUser{}
        |> changeset(%{"tax_id" => tax_id})
        |> validate_user_roles(user_ids)
        |> remove_tokens_by_user_ids(user_ids, headers)
        |> put_change(:inserted_by, user_id)
        |> put_change(:updated_by, user_id)
        |> PRMRepo.insert_and_log(user_id)
        |> load_references()

      _ ->
        {:error, {:conflict, "This user is already in a black list"}}
    end
  end
  def create(_user_id, params) do
    changeset(%BlackListUser{}, params)
  end

  defp validate_user_roles(changeset, user_ids) do
    validate_change changeset, :tax_id, fn :tax_id, _tax_id ->
      case Mithril.search_user_roles(%{"user_ids" => user_ids}) do
        {:ok, %{"data" => []}} -> []
        {:ok, _} -> [user_roles: "Not all roles were deleted"]
        _ -> [user_roles: "Cannot fetch Mithril user roles"]
      end
    end
  end

  def remove_tokens_by_user_ids(changeset, user_ids, headers) do
    validate_change changeset, :tax_id, fn :tax_id, _tax_id ->
      case Mithril.delete_tokens_by_user_ids(user_ids, headers) do
        {:ok, _} -> []
        _ -> [user_tokens: "Cannot delete user tokens"]
      end
    end
  end

  def deactivate(_updated_by, %BlackListUser{is_active: false}) do
    {:error, {:conflict, "User is not in a black list"}}
  end
  def deactivate(updated_by, %BlackListUser{} = black_list_user) do
    black_list_user
    |> changeset(%{is_active: false, updated_by: updated_by})
    |> PRMRepo.update_and_log(updated_by)
    |> load_references()
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, Search.__schema__(:fields))
  end
  def changeset(%BlackListUser{} = black_list_user, attrs) do
    black_list_user
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end

  defp load_references({:ok, entity}) do
    {:ok, load_references(entity)}
  end
  defp load_references(%BlackListUser{} = entity) do
    PRMRepo.preload(entity, :parties)
  end
  defp load_references(err) do
    err
  end
end