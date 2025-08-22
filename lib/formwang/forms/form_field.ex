defmodule Formwang.Forms.FormField do
  use Ecto.Schema
  import Ecto.Changeset

  schema "form_fields" do
    field :label, :string
    field :field_type, :string
    field :required, :boolean, default: false
    field :placeholder, :string
    field :options, {:array, :string}, default: []
    field :validation_rules, :map, default: %{}
    field :sort_order, :integer
    field :settings, :map, default: %{}

    belongs_to :form, Formwang.Forms.Form
    has_many :form_field_values, Formwang.Forms.FormFieldValue, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc "表单字段创建和更新的changeset"
  def changeset(form_field, attrs) do
    form_field
    |> cast(attrs, [:label, :field_type, :required, :placeholder, :options, :validation_rules, :sort_order, :settings, :form_id])
    |> validate_required([:label, :field_type, :form_id])
    |> validate_inclusion(:field_type, ["text", "textarea", "email", "number", "select", "radio", "checkbox", "date", "file"])
    |> validate_length(:label, min: 1, max: 255)
    |> validate_number(:sort_order, greater_than_or_equal_to: 0)
  end
end