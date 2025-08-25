defmodule FormwangWeb.PageController do
  use FormwangWeb, :controller

  def home(conn, _params) do
    # 重定向到管理员登录页面
    redirect(conn, to: ~p"/admin/login")
  end
end