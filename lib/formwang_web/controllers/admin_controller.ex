defmodule FormwangWeb.AdminController do
  use FormwangWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end