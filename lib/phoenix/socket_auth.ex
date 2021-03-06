defmodule BtrzAuth.Phoenix.SocketAuth do
  @moduledoc """
  This module should be used only by Phoenix Sockets.
  """

  @doc """
  Wraps the `Guardian.Phoenix.Socket.authenticate` using the `BtrzAuth.Phoenix.Socket` implementation module.
  """
  def authenticate(socket, token) do
    if Code.ensure_loaded?(Phoenix) do
      Guardian.Phoenix.Socket.authenticate(socket, BtrzAuth.Phoenix.Socket, token)
    else
      :error
    end
  end
end
