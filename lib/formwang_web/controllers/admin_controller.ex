defmodule FormwangWeb.AdminController do
  use FormwangWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def submissions(conn, _params) do
    render(conn, :submissions)
  end

  def settings(conn, _params) do
    render(conn, :settings)
  end
end