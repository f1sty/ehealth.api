defmodule EHealth.PRMRepo.Migrations.CreateEducationsSpecialitiesQualificationsScienceDegreesTables do
  use Ecto.Migration

  def change do
    create table(:educations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:country, :string)
      add(:city, :string)
      add(:degree, :string)
      add(:speciality, :string)
      add(:speciality_code, :string)
      add(:legalized, :boolean, default: false)
      add(:form, :string)
      add(:diploma_number, :string)
      add(:institution_name, :string)
      add(:issued_date, :date)

      timestamps()

      add(:party_id, references(:parties, type: :uuid))
    end

    create table(:legalizations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:issued_date, :date)
      add(:number, :string)
      add(:institution_name, :string)

      add(:education_id, references(:educations, type: :uuid))
    end

    create table(:specialities, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:speciality, :string)
      add(:level, :string)
      add(:order_date, :date)
      add(:order_number, :string)
      add(:order_institution_name, :string)
      add(:attestation_results, :string)
      add(:qualification_type, :string)
      add(:speciality_officio, :boolean)
      add(:attestation_date, :date)
      add(:attestation_name, :string)
      add(:valid_to_date, :date)
      add(:certificate_number, :string)

      timestamps()

      add(:party_id, references(:parties, type: :uuid))
    end

    create table(:qualifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string)
      add(:institution_name, :string)
      add(:related_to, :map)
      add(:course_name, :string)
      add(:form, :string)
      add(:duration, :string)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:speciality, :string)
      add(:certification_number, :string)
      add(:issued_date, :date)
      add(:additional_info, :string)
      add(:duration_units, :string)
      add(:results, :float)

      timestamps()

      add(:party_id, references(:parties, type: uuid))
    end

    create table(:science_degrees, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:institution_name, :string)
      add(:degree, :string)
      add(:diploma_number, :string)
      add(:speciality, :string)
      add(:degree_country, :string)
      add(:degree_city, :string)
      add(:degree_institution_name, :string)
      add(:science_domain, :string)
      add(:speciality_group, :string)
      add(:code, :string)
      add(:degree_science_domain, :string)
      add(:academic_status, :string)
      add(:country, :string)
      add(:city, :string)
      add(:issued_date, :date)

      timestamps()

      add(:party_id, references(:parties, type: :uuid))
    end

    create index(:science_degrees, [:party_id])
    create index(:qualifications, [:party_id])
    create index(:specialities, [:party_id])
    create index(:educations, [:party_id])
  end
end
