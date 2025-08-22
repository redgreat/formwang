defmodule Formwang.Repo.Migrations.CreateForms do
  use Ecto.Migration

  def change do
    create table(:forms) do
      add :title, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :status, :string, default: "draft", null: false
      add :settings, :map, default: %{}
      add :share_token, :string, null: false
      add :qr_code_url, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:forms, [:slug])
    create unique_index(:forms, [:share_token])
    create index(:forms, [:user_id])
    create index(:forms, [:status])
  end
end