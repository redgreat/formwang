defmodule Formwang.Forms.FormSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "form_submissions" do
    field :submitter_ip, :string
    field :user_agent, :string
    field :submitted_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :form, Formwang.Forms.Form
    has_many :form_field_values, Formwang.Forms.FormFieldValue, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc "表单提交创建的changeset"
  def changeset(form_submission, attrs) do
    form_submission
    |> cast(attrs, [:submitter_ip, :user_agent, :submitted_at, :metadata, :form_id])
    |> validate_required([:form_id])
    |> put_submitted_at()
  end

  defp put_submitted_at(changeset) do
    if get_field(changeset, :submitted_at) do
      changeset
    else
      put_change(changeset, :submitted_at, DateTime.utc_now())
    end
  end
end