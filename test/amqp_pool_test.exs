defmodule AMQPPoolTest do
  use ExUnit.Case
  doctest AMQPPool

  test "configuration using environment variables" do
    :ok = System.put_env("AMQPPOOL_AMQP_USERNAME", "guest")
    :ok = System.put_env("AMQPPOOL_AMQP_PASSWORD", "guest")
    :ok = System.put_env("AMQPPOOL_AMQP_VHOST", "/")
    :ok = System.put_env("AMQPPOOL_AMQP_HOST", "localhost")

    {:ok, apps} = Application.ensure_all_started(:amqp_pool)

    assert Application.get_env(:amqp_pool, :amqp_username) == "guest"
    assert Application.get_env(:amqp_pool, :amqp_password) == "guest"
    assert Application.get_env(:amqp_pool, :amqp_vhost) == "/"
    assert Application.get_env(:amqp_pool, :amqp_host) == "localhost"

    Enum.each(apps, fn app -> :ok = Application.stop(app) end)
  end
end
