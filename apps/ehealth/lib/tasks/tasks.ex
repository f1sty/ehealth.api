defmodule EHealth.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      ehealth/bin/ehealth command ehealth_tasks migrate!
  """
  alias EHealth.Dictionaries.Dictionary

  def migrate do
    fraud_migrations_dir = Application.app_dir(:ehealth, "priv/fraud_repo/migrations")
    prm_migrations_dir = Application.app_dir(:ehealth, "priv/prm_repo/migrations")
    migrations_dir = Application.app_dir(:ehealth, "priv/repo/migrations")

    load_app()

    prm_repo = EHealth.PRMRepo
    prm_repo.start_link()

    Ecto.Migrator.run(prm_repo, prm_migrations_dir, :up, all: true)

    fraud_repo = EHealth.FraudRepo
    fraud_repo.start_link()

    Ecto.Migrator.run(fraud_repo, fraud_migrations_dir, :up, all: true)

    repo = EHealth.Repo
    repo.start_link()

    Ecto.Migrator.run(repo, migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  def seed do
    load_app()

    repo = EHealth.Repo
    repo.start_link()

    repo.delete_all(Dictionary)

    prefix = "priv/repo/fixtures/"
    dict_files = ~w(
      dictionaries.json
      id_dk_code.json
      id_dk_code_prof.json
      id_science_domain.json
      id_science_domain_degree.json
      institution_name.json
      lang_skills.json
      nomenclature.json
      other.json
      qualification_type.json
      science_domain.json
      science_domain_degree.json
      speciality.json
      speciality_code.json
      speciality_group.json
      vnz_region.json
    )

    Enum.each(dict_files, &do_seed(prefix <> &1, repo))

    System.halt(0)
    :init.stop()
  end

  defp do_seed(dict_filename, repo) do
    :ehealth
    |> Application.app_dir(dict_filename)
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn item ->
      Enum.reduce(item, %{}, fn {k, v}, acc ->
        Map.put(acc, String.to_atom(k), v)
      end)
    end)
    |> Enum.map(&struct(%Dictionary{}, &1))
    |> Enum.each(&repo.insert!/1)
  end

  defp load_app do
    start_applications([:logger, :postgrex, :ecto])
    :ok = Application.load(:ehealth)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_, _message} = Application.ensure_all_started(app)
    end)
  end
end
