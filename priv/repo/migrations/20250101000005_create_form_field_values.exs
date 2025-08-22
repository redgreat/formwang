defmodule Formwang.Repo.Migrations.CreateFormFieldValues do
  use Ecto.Migration

  def change do
    create table(:form_field_values) do
      add :value, :text
      add :file_path, :string
      add :file_name, :string
      add :file_size, :integer
      add :form_submission_id, references(:form_submissions, on_delete: :delete_all), null: false
      add :form_field_id, references(:form_fields, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:form_field_values, [:form_submission_id])
    create index(:form_field_values, [:form_field_id])
    create index(:form_field_values, [:form_submission_id, :form_field_id])
  end
end