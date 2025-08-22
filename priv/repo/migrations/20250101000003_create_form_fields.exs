defmodule Formwang.Repo.Migrations.CreateFormFields do
  use Ecto.Migration

  def change do
    create table(:form_fields) do
      add :label, :string, null: false
      add :field_type, :string, null: false
      add :required, :boolean, default: false, null: false
      add :placeholder, :string
      add :options, {:array, :string}, default: []
      add :validation_rules, :map, default: %{}
      add :sort_order, :integer, default: 0, null: false
      add :settings, :map, default: %{}
      add :form_id, references(:forms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:form_fields, [:form_id])
    create index(:form_fields, [:form_id, :sort_order])
  end
end