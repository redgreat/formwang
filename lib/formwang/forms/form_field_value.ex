defmodule Formwang.Forms.FormFieldValue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "form_field_values" do
    field :value, :string
    field :file_path, :string
    field :file_name, :string
    field :file_size, :integer

    belongs_to :form_submission, Formwang.Forms.FormSubmission
    belongs_to :form_field, Formwang.Forms.FormField

    timestamps(type: :utc_datetime)
  end

  @doc "表单字段值创建的changeset"
  def changeset(form_field_value, attrs) do
    form_field_value
    |> cast(attrs, [:value, :file_path, :file_name, :file_size, :form_submission_id, :form_field_id])
    |> validate_required([:form_submission_id, :form_field_id])
    |> validate_number(:file_size, greater_than_or_equal_to: 0)
  end
end