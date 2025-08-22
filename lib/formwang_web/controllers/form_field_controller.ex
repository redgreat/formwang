defmodule FormwangWeb.FormFieldController do
  use FormwangWeb, :controller

  alias Formwang.Forms
  alias Formwang.Forms.FormField

  def new(conn, %{"form_id" => form_id}) do
    form = Forms.get_form!(form_id)
    changeset = Forms.change_form_field(%FormField{})
    render(conn, :new, form: form, changeset: changeset)
  end

  def create(conn, %{"form_id" => form_id, "form_field" => form_field_params}) do
    form = Forms.get_form!(form_id)
    form_field_params = Map.put(form_field_params, "form_id", form_id)

    case Forms.create_form_field(form_field_params) do
      {:ok, _form_field} ->
        conn
        |> put_flash(:info, "字段创建成功。")
        |> redirect(to: ~p"/admin/forms/#{form}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, form: form, changeset: changeset)
    end
  end

  def edit(conn, %{"form_id" => form_id, "id" => id}) do
    form = Forms.get_form!(form_id)
    form_field = Forms.get_form_field!(id)
    changeset = Forms.change_form_field(form_field)
    render(conn, :edit, form: form, form_field: form_field, changeset: changeset)
  end

  def update(conn, %{"form_id" => form_id, "id" => id, "form_field" => form_field_params}) do
    form = Forms.get_form!(form_id)
    form_field = Forms.get_form_field!(id)

    case Forms.update_form_field(form_field, form_field_params) do
      {:ok, _form_field} ->
        conn
        |> put_flash(:info, "字段更新成功。")
        |> redirect(to: ~p"/admin/forms/#{form}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, form: form, form_field: form_field, changeset: changeset)
    end
  end

  def delete(conn, %{"form_id" => form_id, "id" => id}) do
    form = Forms.get_form!(form_id)
    form_field = Forms.get_form_field!(id)
    {:ok, _form_field} = Forms.delete_form_field(form_field)

    conn
    |> put_flash(:info, "字段删除成功。")
    |> redirect(to: ~p"/admin/forms/#{form}")
  end
end