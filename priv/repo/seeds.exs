# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Formwang.Repo.insert!(%Formwang.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Formwang.Accounts

# 创建管理员用户
case Accounts.get_user_by_email("admin@formwang.com") do
  nil ->
    {:ok, _user} = Accounts.create_user(%{
      email: "admin@formwang.com",
      password: "admin123456",
      name: "管理员",
      role: "admin"
    })
    IO.puts("管理员用户创建成功: admin@formwang.com / admin123456")
  
  _user ->
    IO.puts("管理员用户已存在")
end
