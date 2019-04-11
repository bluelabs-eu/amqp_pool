defmodule AMQPPoolTest do
  use ExUnit.Case
  doctest AMQPPool

  test "configuration using environment variables" do
    Application.put_env(:amqp_pool, :pools, [:my_pool])

    :ok = System.put_env("MY_POOL_USERNAME", "guest")
    :ok = System.put_env("MY_POOL_PASSWORD", "guest")
    :ok = System.put_env("MY_POOL_VHOST", "/")
    :ok = System.put_env("MY_POOL_HOST", "localhost")
    :ok = System.put_env("MY_POOL_PORT", "5672")

    {:ok, apps} = Application.ensure_all_started(:amqp_pool)

    assert Application.get_env(:amqp_pool, :my_pool_username) == "guest"
    assert Application.get_env(:amqp_pool, :my_pool_password) == "guest"
    assert Application.get_env(:amqp_pool, :my_pool_vhost) == "/"
    assert Application.get_env(:amqp_pool, :my_pool_host) == "localhost"
    assert Application.get_env(:amqp_pool, :my_pool_port) == 5672

    [
      "MY_POOL_USERNAME",
      "MY_POOL_PASSWORD",
      "MY_POOL_VHOST",
      "MY_POOL_HOST",
      "MY_POOL_PORT"
    ]
    |> Enum.each(&System.delete_env/1)

    Enum.each(apps, fn app -> :ok = Application.stop(app) end)
  end

  test "basic publish/consume test" do
    Application.put_env(:amqp_pool, :pools, [:my_pool_1, :my_pool_2])
    Application.put_env(:amqp_pool, :my_pool_1_username, "guest")
    Application.put_env(:amqp_pool, :my_pool_1_password, "guest")
    Application.put_env(:amqp_pool, :my_pool_1_vhost, "/")
    Application.put_env(:amqp_pool, :my_pool_1_host, "localhost")
    Application.put_env(:amqp_pool, :my_pool_1_port, 5672)

    Application.put_env(:amqp_pool, :my_pool_2_username, "guest")
    Application.put_env(:amqp_pool, :my_pool_2_password, "guest")
    Application.put_env(:amqp_pool, :my_pool_2_vhost, "/")
    Application.put_env(:amqp_pool, :my_pool_2_host, "localhost")
    Application.put_env(:amqp_pool, :my_pool_2_port, 5672)

    {:ok, apps} = Application.ensure_all_started(:amqp_pool)

    exchange_name = "hello"
    exchange_type = :fanout
    exchange_opts = []
    queue_name = "hello-world"
    queue_opts = []
    rkey = "world"
    payload1 = "Hello, world!"

    {:ok, payload2, _metadata} =
      AMQPPool.Channel.with_channel(
        :my_pool_1,
        # main function
        fn channel ->
          AMQP.Basic.publish(channel, exchange_name, rkey, payload1)
          AMQP.Basic.get(channel, queue_name, no_ack: true)
        end,
        # setup
        fn channel ->
          :ok = AMQP.Exchange.declare(channel, exchange_name, exchange_type, exchange_opts)
          {:ok, _} = AMQP.Queue.declare(channel, queue_name, queue_opts)
          :ok = AMQP.Queue.bind(channel, queue_name, exchange_name)
          {:ok, channel}
        end
      )

    assert payload2 == payload1

    {:ok, payload3, _metadata} =
      AMQPPool.Channel.with_channel(
        :my_pool_2,
        # main function
        fn channel ->
          AMQP.Basic.publish(channel, exchange_name, rkey, payload1)
          AMQP.Basic.get(channel, queue_name, no_ack: true)
        end,
        # setup
        fn channel ->
          :ok = AMQP.Exchange.declare(channel, exchange_name, exchange_type, exchange_opts)
          {:ok, _} = AMQP.Queue.declare(channel, queue_name, queue_opts)
          :ok = AMQP.Queue.bind(channel, queue_name, exchange_name)
          {:ok, channel}
        end
      )

    assert payload3 == payload1

    Enum.each(apps, fn app -> :ok = Application.stop(app) end)
  end
end
