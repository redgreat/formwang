defmodule FormwangWeb.PublicFormController do
  use FormwangWeb, :controller

  alias Formwang.Forms
  alias Formwang.Forms.FormSubmission

  # 表单列表页面
  def index(conn, _params) do
    forms = Forms.list_published_forms()
    render(conn, :index, forms: forms)
  end

  # 通过slug访问表单
  def show(conn, %{"slug" => slug}) do
    case Forms.get_form_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "表单不存在或已被删除")
        |> redirect(to: "/")

      form ->
        if form.status == :published do
          fields = Forms.list_form_fields(form.id)
          changeset = Forms.change_form_submission(%FormSubmission{})
          render(conn, :show, form: form, fields: fields, changeset: changeset)
        else
          conn
          |> put_flash(:error, "表单尚未发布")
          |> redirect(to: "/")
        end
    end
  end

  # 通过分享令牌访问表单
  def show_by_token(conn, %{"token" => token}) do
    case Forms.get_form_by_share_token(token) do
      nil ->
        conn
        |> put_flash(:error, "无效的分享链接")
        |> redirect(to: "/")

      form ->
        if form.status == :published do
          fields = Forms.list_form_fields(form.id)
          changeset = Forms.change_form_submission(%FormSubmission{})
          render(conn, :show, form: form, fields: fields, changeset: changeset)
        else
          conn
          |> put_flash(:error, "表单尚未发布")
          |> redirect(to: "/")
        end
    end
  end

  # 提交表单（新路由）
  def submit_form(conn, %{"slug" => slug, "form_submission" => submission_params}) do
    case Forms.get_form_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "表单不存在")
        |> redirect(to: "/")

      form ->
        submit_form_internal(conn, form, submission_params)
    end
  end

  # 提交表单（旧路由兼容）
  def submit(conn, %{"slug" => slug, "form_submission" => submission_params}) do
    case Forms.get_form_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "表单不存在")
        |> redirect(to: "/")

      form ->
        submit_form_internal(conn, form, submission_params)
    end
  end

  def submit_by_token(conn, %{"token" => token, "form_submission" => submission_params}) do
    case Forms.get_form_by_share_token(token) do
      nil ->
        conn
        |> put_flash(:error, "无效的分享链接")
        |> redirect(to: "/")

      form ->
        submit_form_internal(conn, form, submission_params)
    end
  end

  # 提交表单的私有函数
  defp submit_form_internal(conn, form, submission_params) do
    if form.status == :published do
      case Forms.create_form_submission(form, submission_params) do
        {:ok, _submission} ->
          conn
          |> put_flash(:info, "表单提交成功！感谢您的参与。")
          |> redirect(to: ~p"/forms/#{form.slug}/success")

        {:error, changeset} ->
          fields = Forms.list_form_fields(form.id)
          render(conn, :show, form: form, fields: fields, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "表单尚未发布")
      |> redirect(to: "/")
    end
  end

  # 提交成功页面
  def success(conn, %{"slug" => slug}) do
    case Forms.get_form_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "表单不存在")
        |> redirect(to: "/")

      form ->
        render(conn, :success, form: form)
    end
  end
end