defmodule FormwangWeb.Layouts do
  @moduledoc """
  This module contains different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered around other layouts.
  """
  use FormwangWeb, :html

  embed_templates "layouts/*"
end