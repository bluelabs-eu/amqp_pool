defmodule AMQPPool do
  @moduledoc """
  AMQPPool manages a pool of AMQP channels for you to use.

  You need to configure AMQPPool to tell it how to connect and set some pool settings.
  ```elixir
  # these are the same settings as for poolboy
  config :amqp_pool, :pool_settings,
    pool_size: 20,
    max_overflow: 40

  config :amqp_pool, amqp_username: ""
  config :amqp_pool, amqp_password: ""
  config :amqp_pool, amqp_vhost: ""
  config :amqp_pool, amqp_host: ""
  ```

  AMQPPool exports one function for you to use: `AMQPPool.Channel.with_channel/2`.
  """
end
