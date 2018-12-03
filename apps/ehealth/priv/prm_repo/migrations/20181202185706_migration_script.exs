defmodule EHealth.PRMRepo.Migrations.MigrationScript do
  use Ecto.Migration

  @copy_fields %{
    educations: ~w(country city institution_name issued_date diploma_number degree speciality),
    qualifications: ~w(type institution_name speciality issued_date certification_number),
    specialities: ~w(speciality speciality_officio level qualification_type attestation_name attestation_date valid_to_date certificate_number),
    science_degree: ~w(country city degree institution_name diploma_number speciality issued_date),
    documents: ~w(type number),
    phones: ~w(type number)
  }

  def change do
    alter table(:employees) do
      add(:employment_status, :jsonb)
      add(:employee_category, :string)
      add(:position_level, :string)
      add(:speciality_nomenclature, :string)
      add(:dk_code, :string)
    end

    alter table(:parties) do
      add(:birth_settlement_type, :string)
      add(:citizenship, :string)
      add(:citizenship_at_birth, :string)
      add(:language_skills, :jsonb)
      add(:photo, :jsonb)
      add(:personal_email, :string)
      add(:retirements, :jsonb)
      add(:birth_country, :string)
      add(:birth_settlement, :string)
    end

    create table(:addresses, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:country, :string)
      add(:area, :string)
      add(:region, :string)
      add(:settlement_type, :string)
      add(:settlement, :string)
      add(:settlement_id, :uuid)
      add(:street_type, :string)
      add(:street, :string)
      add(:building, :string)
      add(:apartment, :string)
      add(:zip, :string)

      add(:party_id, references(:parties, type: :uuid))
    end

    create table(:provided_services, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string, null: false)
      add(:sub_types, {:array, :map})
      add(:employee_id, references(:employees, type: :uuid, on_delete: :nothing))
    end

    create table(:educations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:country, :string)
      add(:city, :string)
      add(:institution_name, :string)
      add(:issued_date, :date)
      add(:diploma_number, :string)
      add(:degree, :string)
      add(:speciality, :string)
      add(:party_id, references(:parties, type: :uuid))
    end

    copy_jsonb_from_parties_table(:educations)

    alter table(:educations) do
      add(:speciality_code, :string)
      add(:legalized, :boolean, default: false)
      add(:form, :string)

      timestamps()
    end

    create table(:legalizations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:issued_date, :date)
      add(:number, :string)
      add(:institution_name, :string)

      add(:education_id, references(:educations, type: :uuid))
    end

    create table(:qualifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:institution_name, :string)
      add(:speciality, :string)
      add(:issued_date, :date)
      add(:certification_number, :string)
      add(:party_id, references(:parties, type: :uuid))
    end

    copy_jsonb_from_parties_table(:qualifications)

    alter table(:qualifications) do
      add(:related_to, :map)
      add(:course_name, :string)
      add(:form, :string)
      add(:duration, :string)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:additional_info, :string)
      add(:duration_units, :string)
      add(:results, :float)

      timestamps()
    end

    create table(:specialities, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:speciality, :string)
      add(:speciality_officio, :boolean)
      add(:level, :string)
      add(:qualification_type, :string)
      add(:attestation_name, :string)
      add(:attestation_date, :date)
      add(:valid_to_date, :date)
      add(:certificate_number, :string)
      add(:party_id, references(:parties, type: :uuid))
    end

    copy_jsonb_from_parties_table(:specialities)

    alter table(:specialities) do
      add(:order_date, :date)
      add(:order_number, :string)
      add(:order_institution_name, :string)
      add(:attestation_results, :string)

      timestamps()
    end

    create table(:science_degrees, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:country, :string)
      add(:city, :string)
      add(:degree, :string)
      add(:institution_name, :string)
      add(:diploma_number, :string)
      add(:speciality, :string)
      add(:issued_date, :date)
      add(:party_id, references(:parties, type: :uuid))
    end

    copy_jsonb_from_parties_table(:science_degree)

    alter table(:science_degrees) do
      add(:degree_country, :string)
      add(:degree_city, :string)
      add(:degree_institution_name, :string)
      add(:science_domain, :string)
      add(:speciality_group, :string)
      add(:code, :string)
      add(:degree_science_domain, :string)
      add(:academic_status, :string)

      timestamps()
    end

    create table(:documents, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:number, :string)
      add(:party_id, references(:parties, type: :uuid))
    end

    copy_jsonb_from_parties_table(:documents)

    alter table(:documents) do
      add(:issued_by, :string)
      add(:issued_at, :date)
    end

    create table(:phones, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:number, :string)
      add(:party_id, references(:parties, type: :uuid))
    end

    copy_jsonb_from_parties_table(:phones)

    alter table(:phones) do
      add(:public, :boolean)
    end

    create index(:phones, [:party_id])
    create index(:documents, [:party_id])
    create index(:science_degrees, [:party_id])
    create index(:qualifications, [:party_id])
    create index(:specialities, [:party_id])
    create index(:educations, [:party_id])
    create index(:addresses, [:party_id])
    create index(:provided_services, [:employee_id])
  end

  defp copy_jsonb_from_parties_table(party_field) do
    fields = @copy_fields[party_field]
             |> Enum.join(", ")
    query = get_query(party_field, fields)
    execute(query)
  end

  defp get_query(field, fields) do
    case field do
      :science_degree ->
        "INSERT INTO science_degrees (party_id, #{fields}) select party_id, #{fields} from json_populate_recordset(null::\"science_degrees\", (select array_to_json(array_agg((select jsonb_insert(science_degree, '{party_id}', (select cast(id as text))::jsonb)))) from parties));"
      val ->
        "INSERT INTO #{val} (party_id, #{fields}) select party_id, #{fields} from json_populate_recordset(null::\"#{val}\", (select array_to_json(array_agg((select jsonb_insert(jsonb_array_elements, '{party_id}', (select cast(id as text))::jsonb)))) from (select id, jsonb_array_elements(#{val}) from parties) as lst));"
    end
  end
end
