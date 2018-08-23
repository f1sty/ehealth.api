defmodule EHealth.Parties.Party do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "parties" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:second_name, :string)
    field(:birth_date, :date)
    field(:birth_country, :string)
    field(:birth_settlement, :string)
    field(:birth_settlement_type, :string)
    field(:citizenship, :string)
    field(:citizenship_at_birth, :string)
    field(:photo, :string)
    field(:personal_email, :string)
    field(:gender, :string)
    field(:tax_id, :string)
    field(:no_tax_id, :boolean, default: false)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)
    field(:declaration_limit, :integer)
    field(:about_myself, :string)
    field(:working_experience, :integer)

    embeds_many(:language_skills, EHealth.Parties.LanguageSkill, on_replace: :delete)
    embeds_many(:retirements, EHealth.Parties.Retirement, on_replace: :delete)

    has_many(:users, EHealth.PartyUsers.PartyUser, foreign_key: :party_id)
    has_many(:phones, EHealth.Parties.Phone, foreign_key: :party_id, on_replace: :delete)
    has_many(:documents, EHealth.Parties.Document, foreign_key: :party_id, on_replace: :delete)
    has_many(:addresses, EHealth.Parties.Address, foreign_key: :party_id, on_replace: :delete)
    has_many(:educations, EHealth.Parties.Education, foreign_key: :party_id, on_replace: :delete)
    has_many(:specialities, EHealth.Parties.Speciality, foreign_key: :party_id, on_replace: :delete)
    has_many(:qualifications, EHealth.Parties.Qualification, foreign_key: :party_id, on_replace: :delete)

    has_one(:science_degree, EHealth.Parties.ScienceDegree, foreign_key: :party_id, on_replace: :delete)

    timestamps()
  end
end
