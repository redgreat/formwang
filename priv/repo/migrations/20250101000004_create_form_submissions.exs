defmodule Formwang.Repo.Migrations.CreateFormSubmissions do
  use Ecto.Migration

  def change do
    create table(:form_submissions) do
      add :submitter_ip, :string
      add :user_agent, :text
      add :submitted_at, :utc_datetime, null: false
      add :metadata, :map, default: %{}
      add :form_id, references(:forms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:form_submissions, [:form_id])
    create index(:form_submissions, [:submitted_at])
    create index(:form_submissions, [:form_id, :submitted_at])
  end
end