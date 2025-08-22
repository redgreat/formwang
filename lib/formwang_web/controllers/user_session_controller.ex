defmodule FormwangWeb.UserSessionController do
  use FormwangWeb, :controller

  alias Formwang.Accounts
  alias FormwangWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "登录成功！")
      |> UserAuth.log_in_user(user)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: "邮箱或密码错误")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "已成功退出登录。")
    |> UserAuth.log_out_user()
  end
end