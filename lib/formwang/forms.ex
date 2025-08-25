defmodule Formwang.Forms do
  @moduledoc """
  表单管理上下文模块
  """

  import Ecto.Query, warn: false
  alias Formwang.Repo
  alias Formwang.Forms.{Form, FormField, FormSubmission, FormFieldValue}
  alias Formwang.Accounts.User

  ## Forms

  @doc "获取所有表单"
  def list_forms do
    Repo.all(Form)
  end

  @doc "获取所有已发布的表单"
  def list_published_forms do
    Form
    |> where([f], f.status == :published)
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  @doc "根据用户获取表单列表"
  def list_forms_by_user(%User{} = user) do
    Form
    |> where([f], f.user_id == ^user.id)
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  @doc "根据ID获取表单"
  def get_form!(id), do: Repo.get!(Form, id)

  @doc "根据slug获取表单"
  def get_form_by_slug(slug) do
    Repo.get_by(Form, slug: slug)
    |> Repo.preload([:user, :form_fields])
  end

  @doc "根据分享令牌获取表单"
  def get_form_by_share_token(token) do
    Repo.get_by(Form, share_token: token)
    |> Repo.preload([:user, :form_fields])
  end

  @doc "生成分享令牌"
  def generate_share_token(form) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64() |> binary_part(0, 32)
    
    form
    |> Form.changeset(%{share_token: token})
    |> Repo.update()
  end

  @doc "重新生成分享令牌"# 重新生成分享令牌
  def regenerate_share_token(form) do
    generate_share_token(form)
  end

  # 创建表单提交
  def create_form_submission(form, attrs \\ %{}) do
    %FormSubmission{}
    |> FormSubmission.changeset(Map.put(attrs, "form_id", form.id))
    |> Repo.insert()
    |> case do
      {:ok, submission} ->
        # 创建字段值
        create_field_values(submission, attrs["field_values"] || %{})
        {:ok, submission}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # 创建字段值
  defp create_field_values(submission, field_values) do
    Enum.each(field_values, fn {field_id, value} ->
      field_id = if is_binary(field_id), do: String.to_integer(field_id), else: field_id
      
      # 处理数组值（复选框）
      values = if is_list(value), do: value, else: [value]
      
      Enum.each(values, fn v ->
        if v != "" and not is_nil(v) do
          %FormFieldValue{}
          |> FormFieldValue.changeset(%{
            form_submission_id: submission.id,
            form_field_id: field_id,
            value: to_string(v)
          })
          |> Repo.insert()
        end
      end)
    end)
  end

  # 创建表单提交的changeset
  def change_form_submission(%FormSubmission{} = submission, attrs \\ %{}) do
    FormSubmission.changeset(submission, attrs)
  end

  @doc "创建表单"
  def create_form(attrs \\ %{}) do
    %Form{}
    |> Form.changeset(attrs)
    |> Repo.insert()
  end

  @doc "更新表单"
  def update_form(%Form{} = form, attrs) do
    form
    |> Form.changeset(attrs)
    |> Repo.update()
  end

  @doc "删除表单"
  def delete_form(%Form{} = form) do
    Repo.delete(form)
  end

  @doc "获取表单changeset"
  def change_form(%Form{} = form, attrs \\ %{}) do
    Form.changeset(form, attrs)
  end

  ## Form Fields

  @doc "获取表单的所有字段"
  def list_form_fields(%Form{} = form) do
    FormField
    |> where([ff], ff.form_id == ^form.id)
    |> order_by([ff], asc: ff.sort_order)
    |> Repo.all()
  end

  @doc "根据ID获取表单字段"
  def get_form_field!(id), do: Repo.get!(FormField, id)

  @doc "创建表单字段"
  def create_form_field(attrs \\ %{}) do
    %FormField{}
    |> FormField.changeset(attrs)
    |> Repo.insert()
  end

  @doc "更新表单字段"
  def update_form_field(%FormField{} = form_field, attrs) do
    form_field
    |> FormField.changeset(attrs)
    |> Repo.update()
  end

  @doc "删除表单字段"
  def delete_form_field(%FormField{} = form_field) do
    Repo.delete(form_field)
  end

  @doc "获取表单字段changeset"
  def change_form_field(%FormField{} = form_field, attrs \\ %{}) do
    FormField.changeset(form_field, attrs)
  end

  ## Form Submissions

  @doc "获取表单的所有提交记录"
  def list_form_submissions(%Form{} = form) do
    FormSubmission
    |> where([fs], fs.form_id == ^form.id)
    |> order_by([fs], desc: fs.submitted_at)
    |> Repo.all()
  end

  @doc "根据ID获取表单提交记录"
  def get_form_submission!(id), do: Repo.get!(FormSubmission, id)

  @doc "创建表单提交记录"
  def create_form_submission_direct(attrs \\ %{}) do
    %FormSubmission{}
    |> FormSubmission.changeset(attrs)
    |> Repo.insert()
  end

  @doc "删除表单提交记录"
  def delete_form_submission(%FormSubmission{} = form_submission) do
    Repo.delete(form_submission)
  end

  ## Form Field Values

  @doc "获取提交记录的所有字段值"
  def list_form_field_values(%FormSubmission{} = submission) do
    FormFieldValue
    |> where([ffv], ffv.form_submission_id == ^submission.id)
    |> preload(:form_field)
    |> Repo.all()
  end

  @doc "创建表单字段值"
  def create_form_field_value(attrs \\ %{}) do
    %FormFieldValue{}
    |> FormFieldValue.changeset(attrs)
    |> Repo.insert()
  end

  @doc "批量创建表单字段值"
  def create_form_field_values(submission, field_values) do
    Enum.each(field_values, fn {field_id, value} ->
      create_form_field_value(%{
        form_submission_id: submission.id,
        form_field_id: field_id,
        value: value
      })
    end)
  end
end