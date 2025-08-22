defmodule FormwangWeb.FormController do
  use FormwangWeb, :controller

  alias Formwang.Forms
  alias Formwang.Forms.Form

  def index(conn, _params) do
    forms = Forms.list_forms_by_user(conn.assigns.current_user)
    render(conn, :index, forms: forms)
  end

  def show(conn, %{"id" => id}) do
    form = Forms.get_form!(id)
    form_fields = Forms.list_form_fields(form)
    render(conn, :show, form: form, form_fields: form_fields)
  end

  def new(conn, _params) do
    changeset = Forms.change_form(%Form{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"form" => form_params}) do
    form_params = Map.put(form_params, "user_id", conn.assigns.current_user.id)

    case Forms.create_form(form_params) do
      {:ok, form} ->
        conn
        |> put_flash(:info, "表单创建成功。")
        |> redirect(to: ~p"/admin/forms/#{form}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    form = Forms.get_form!(id)
    changeset = Forms.change_form(form)
    render(conn, :edit, form: form, changeset: changeset)
  end

  def update(conn, %{"id" => id, "form" => form_params}) do
    form = Forms.get_form!(id)

    case Forms.update_form(form, form_params) do
      {:ok, form} ->
        conn
        |> put_flash(:info, "表单更新成功。")
        |> redirect(to: ~p"/admin/forms/#{form}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, form: form, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    form = Forms.get_form!(id)
    {:ok, _form} = Forms.delete_form(form)

    conn
    |> put_flash(:info, "表单删除成功")
    |> redirect(to: ~p"/admin/forms")
  end

  # 分享表单
  def share(conn, %{"id" => id}) do
    form = Forms.get_form!(id)
    
    # 如果没有分享令牌，生成一个
    form = if is_nil(form.share_token) do
      {:ok, updated_form} = Forms.generate_share_token(form)
      updated_form
    else
      form
    end
    
    render(conn, :share, form: form)
  end

  # 重新生成分享令牌
  def regenerate_token(conn, %{"id" => id}) do
    form = Forms.get_form!(id)
    {:ok, updated_form} = Forms.regenerate_share_token(form)
    
    conn
    |> put_flash(:info, "分享链接已重新生成")
    |> redirect(to: ~p"/admin/forms/#{updated_form.id}/share")
  end
end