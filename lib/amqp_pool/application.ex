defmodule AMQPPool.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias AMQPPool.Pool

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children =
      for p <- pools() do
        supervisor(Pool, [p], id: p)
      end

    opts = [strategy: :one_for_one, name: AMQPPool.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp pools() do
    Application.fetch_env!(:amqp_pool, :pools)
  end
end
