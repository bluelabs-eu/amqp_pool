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

  test "basic publish/consume test" do
    {:ok, apps} = Application.ensure_all_started(:amqp_pool)

    exchange_name = "hello"
    exchange_type = :fanout
    exchange_opts = []
    queue_name = "hello-world"
    queue_opts = []
    rkey = "world"
    payload1 = "Hello, world!"

    {:ok, payload2, _metadata} =
      AMQPPool.Channel.with_channel(fn channel ->
        AMQP.Exchange.declare(channel, exchange_name, exchange_type, exchange_opts)
        AMQP.Basic.publish(channel, exchange_name, rkey, payload1)
        AMQP.Queue.declare(channel, queue_name, queue_opts)
        AMQP.Queue.bind(channel, queue_name, exchange_name)
        AMQP.Basic.get(channel, queue_name, no_ack: true)
      end)

    assert payload2 == payload1

    Enum.each(apps, fn app -> :ok = Application.stop(app) end)
  end
end
