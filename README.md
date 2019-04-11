# AMQPPool

AMQPPool manages a pool of AMQP channels for you.

## Usage

```elixir
:ok = AMQPPool.Channel.with_channel(:my_pool,
        # main function
        fn channel ->
          AMQP.Basic.publish(channel, exchange, routing_key, payload)
        end,
        # setup
        fn channel ->
          :ok = AMQP.Exchange.declare(channel, exchange_name, exchange_type, exchange_opts)
          {:ok, channel}
        end
      )
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `amqp_pool` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:amqp_pool, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/amqp_pool](https://hexdocs.pm/amqp_pool).

## Configuration

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

The details of the AMQP endpoint can also be provided using environment variables using the
`<pool-name-in-all-caps>_<parameter>` format (e.g. `MY_POOL_USERNAME="USERNAME"`).