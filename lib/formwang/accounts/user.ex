defmodule Formwang.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :name, :string
    field :role, :string, default: "admin"

    has_many :forms, Formwang.Forms.Form, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc "用户注册的changeset"
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :name, :password, :role])
    |> validate_required([:email, :name, :password])
    |> validate_email()
    |> validate_password(opts)
  end

  @doc "用户更新的changeset"
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role])
    |> validate_required([:email, :name])
    |> validate_email()
  end

  @doc "验证用户密码"
  def valid_password?(%Formwang.Accounts.User{password_hash: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Formwang.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end