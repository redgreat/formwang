defmodule Formwang.Forms.Form do
  use Ecto.Schema
  import Ecto.Changeset

  schema "forms" do
    field :title, :string
    field :description, :string
    field :slug, :string
    field :status, :string, default: "draft"
    field :settings, :map, default: %{}
    field :share_token, :string
    field :qr_code_url, :string

    belongs_to :user, Formwang.Accounts.User
    has_many :form_fields, Formwang.Forms.FormField, on_delete: :delete_all
    has_many :form_submissions, Formwang.Forms.FormSubmission, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc "表单创建和更新的changeset"
  def changeset(form, attrs) do
    form
    |> cast(attrs, [:title, :description, :slug, :status, :settings, :user_id])
    |> validate_required([:title, :user_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_inclusion(:status, ["draft", "published", "archived"])
    |> generate_slug()
    |> generate_share_token()
    |> unique_constraint(:slug)
    |> unique_constraint(:share_token)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil -> changeset
      title ->
        slug = title
               |> String.downcase()
               |> String.replace(~r/[^a-z0-9\s-]/, "")
               |> String.replace(~r/\s+/, "-")
               |> String.trim("-")
        
        put_change(changeset, :slug, "#{slug}-#{:rand.uniform(9999)}")
    end
  end

  defp generate_share_token(changeset) do
    if get_field(changeset, :share_token) do
      changeset
    else
      token = :crypto.strong_rand_bytes(16) |> Base.url_encode64() |> binary_part(0, 16)
      put_change(changeset, :share_token, token)
    end
  end
end