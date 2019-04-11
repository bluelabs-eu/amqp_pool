defmodule AMQPPool do
  @moduledoc """
  AMQPPool manages a pool of AMQP channels for you to use.

  You need to configure AMQPPool to tell it how to connect and set some pool settings.
  ```elixir
  config :amqp_pool, pools: [:my_pool]

  # these are the same settings as for poolboy
  config :amqp_pool, :my_pool,
    pool_size: 5,
    max_overflow: 2

  config :amqp_pool, my_pool_username: "USERNAME"
  config :amqp_pool, my_pool_password: "PASSWORD"
  config :amqp_pool, my_pool_vhost: "VHOST"
  config :amqp_pool, my_pool_host: "HOST"
  config :amqp_pool, my_pool_host: 5672
  ```

  AMQPPool exports one function for you to use: `AMQPPool.Channel.with_channel/2`.
  """
end
