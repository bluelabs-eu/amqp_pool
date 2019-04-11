defmodule AMQPPool.Pool do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @default_pool_settings [
    pool_size: 5,
    max_overflow: 2
  ]

  def start_link(pool) do
    Supervisor.start_link(__MODULE__, pool)
  end

  def init(pool) do
    import Supervisor.Spec, warn: false

    conn_worker_name = conn_worker_name(pool)

    children = [
      worker(AMQPPool.Connection, [
        amqp_connection_settings(pool),
        [name: conn_worker_name],
        connection_name(pool)
      ]),
      :poolboy.child_spec(pool, poolboy_config(pool), [conn_worker_name])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: pool]
    supervise(children, opts)
  end

  defp conn_worker_name(pool), do: Enum.join([AMQPPool.Connection, pool], ".") |> String.to_atom()

  defp poolboy_config(pool) do
    settings = Application.get_env(:amqp_pool, pool, @default_pool_settings)

    [
      {:name, {:local, pool}},
      {:worker_module, AMQPPool.Channel},
      {:size, settings[:pool_size]},
      {:max_overflow, settings[:max_overflow]}
    ]
  end

  defp amqp_connection_settings(pool) do
    [
      username: username(pool),
      password: password(pool),
      virtual_host: vhost(pool),
      port: port(pool),
      host: host(pool)
    ]
  end

  def connection_name(pool), do: get_param(:connection_name, pool, & &1, :undefined)

  def username(pool), do: fetch_param!(:username, pool)

  def password(pool), do: fetch_param!(:password, pool)

  def vhost(pool), do: get_param(:vhost, pool, & &1, "/")

  def port(pool), do: get_param(:port, pool, &to_integer/1, 5672)

  def host(pool), do: fetch_param!(:host, pool)

  defp get_param(param_name, pool, transformation \\ & &1, default \\ nil) do
    env_var = env_var(pool, param_name)
    param = param(pool, param_name)
    get_value(env_var, param, transformation, default)
  end

  defp fetch_param!(param_name, pool, transformation \\ & &1) do
    env_var = env_var(pool, param_name)
    param = param(pool, param_name)
    fetch_value!(env_var, param)
  end

  def param(pool, param), do: [pool, param] |> Enum.join("_") |> String.to_atom()

  def env_var(pool, param), do: [pool, param] |> Enum.join("_") |> String.upcase()

  def get_value(env_var, param, transformation \\ & &1, default \\ nil) do
    value =
      (System.get_env(env_var) && env_var |> System.get_env() |> transformation.()) ||
        Application.get_env(:amqp_pool, param, default)

    :ok = Application.put_env(:amqp_pool, param, value)
    value
  end

  def fetch_value!(env_var, param, transformation \\ & &1) do
    value =
      (System.get_env(env_var) ||
         Application.fetch_env!(:amqp_pool, param))
      |> transformation.()

    :ok = Application.put_env(:amqp_pool, param, value)
    value
  end

  defp to_integer(value) when is_binary(value), do: String.to_integer(value)

  defp to_integer(value) when is_integer(value), do: value
end
