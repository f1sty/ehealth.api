defmodule EHealth.Parties.LanguageSkill do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @fields ~w(
    language
    language_level
  )a

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key false
  embedded_schema do
    field(:language, :string)
    field(:language_level, :string)
  end

  def changeset(language_skill, attrs) do
    language_skill
    |> cast(attrs, @fields)
    |> validate_required([:language])
  end
end
