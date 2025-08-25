defmodule FormwangWeb.Router do
  use FormwangWeb, :router

  import FormwangWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FormwangWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug :require_authenticated_user
  end

  pipeline :redirect_if_authenticated do
    plug :redirect_if_user_is_authenticated
  end

  scope "/", FormwangWeb do
    pipe_through :browser

    get "/", PageController, :home
    
    # 公共表单访问路由
    get "/forms", PublicFormController, :index
    get "/forms/:slug", PublicFormController, :show
    post "/forms/:slug/submit", PublicFormController, :submit_form
    get "/forms/:slug/success", PublicFormController, :success
    get "/forms/token/:token", PublicFormController, :show_by_token
    post "/forms/token/:token", PublicFormController, :submit_by_token
  end

  # Authentication routes
  scope "/", FormwangWeb do
    pipe_through [:browser, :redirect_if_authenticated]

    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/admin/login", UserSessionController, :new
  end

  scope "/", FormwangWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end

  # Admin routes
  scope "/admin", FormwangWeb do
    pipe_through [:browser, :auth]

    get "/", AdminController, :index
    get "/submissions", AdminController, :submissions
    get "/settings", AdminController, :settings
    
    resources "/forms", FormController do
      resources "/fields", FormFieldController, except: [:index]
      get "/share", FormController, :share
      post "/regenerate_token", FormController, :regenerate_token
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FormwangWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:formwang, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FormwangWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
