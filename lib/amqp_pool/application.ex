defmodule AMQPPool.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # List all child processes to be supervised
    children = [
      worker(AMQPPool.Connection, [amqp_connection_settings()], id: AMQPPool.Connection),
      :poolboy.child_spec(:channel, poolboy_config(), [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AMQPPool.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp poolboy_config do
    settings = Application.fetch_env!(:amqp_pool, :pool_settings)

    [
      {:name, {:local, :channel}},
      {:worker_module, AMQPPool.Channel},
      {:size, settings[:pool_size]},
      {:max_overflow, settings[:max_overflow]}
    ]
  end

  defp amqp_connection_settings do
    [
      username: amqp_username(),
      password: amqp_password(),
      vhost: amqp_vhost(),
      host: amqp_host()
    ]
  end

  defp amqp_username() do
    username =
      System.get_env("AMQPPOOL_AMQP_USERNAME") ||
        Application.fetch_env!(:amqp_pool, :amqp_username)

    :ok = Application.put_env(:amqp_pool, :amqp_username, username)
    username
  end

  defp amqp_password() do
    password =
      System.get_env("AMQPPOOL_AMQP_PASSWORD") ||
        Application.fetch_env!(:amqp_pool, :amqp_password)

    :ok = Application.put_env(:amqp_pool, :amqp_password, password)
    password
  end

  defp amqp_vhost() do
    vhost =
      System.get_env("AMQPPOOL_AMQP_VHOST") ||
        Application.fetch_env!(:amqp_pool, :amqp_vhost)

    :ok = Application.put_env(:amqp_pool, :amqp_vhost, vhost)
    vhost
  end

  defp amqp_host() do
    host =
      System.get_env("AMQPPOOL_AMQP_HOST") ||
        Application.fetch_env!(:amqp_pool, :amqp_host)

    :ok = Application.put_env(:amqp_pool, :amqp_host, host)
    host
  end
end
