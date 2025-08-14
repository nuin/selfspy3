defmodule SelfspyWebWeb.PageController do
  use SelfspyWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
