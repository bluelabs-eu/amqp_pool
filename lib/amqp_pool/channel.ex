defmodule AMQPPool.Channel do
  use GenServer
  @moduledoc "Manages a single AMQP channel."

  @doc false
  def start_link([conn]) do
    GenServer.start_link(__MODULE__, conn, [])
  end

  @doc """
  Use a channel. Checking in and out are done automatically.

  Example:

  ```elixir
  :ok = AMQPPool.Channel.with_channel(:my_pool, fn channel ->
    AMQP.Basic.publish(channel, exchange, routing_key, payload)
  end)
  ```

  Note, if you want to pattern match on the result, do it outside of the `with_channel` function. Don't let a pattern match fail in the function supplied to `with_channel`.

  Here is a more advanced example using `with`:

  ```elixir
  :ok = AMQPPool.Channel.with_channel(:my_pool, fn channel ->
    with :ok <- AMQP.Basic.publish(channel, exchange, routing_key, payload),
      :ok <- AMQP.Basic.publish(channel, exchange2, routing_key2, payload2) do
      :ok
    else _ -> :error
    end
  end)

  In the example above, if one of the commands fails, the pattern match *outside* the `with_channel` will fail.
  ```

  The second parameter is optional and is used to define a callback function that
  can be used to bootstrap a channel by means of declaring exchanges, queues and bindings
  when appropriate. This function is only called once in the life-time of a channel.
  """
  def with_channel(pool, func, setup \\ fn chan -> {:ok, chan} end, timeout \\ 1000) do
    :poolboy.transaction(
      pool,
      fn pid -> GenServer.call(pid, {:with_channel, func, setup}, timeout - 50) end,
      timeout
    )
  end

  # GenServer callbacks

  @doc false
  def init(conn) do
    {:ok, {nil, conn}}
  end

  @doc false
  def ensure_channel(nil, conn) do
    with {:ok, chan} <- AMQPPool.Connection.new_channel(conn) do
      Process.monitor(chan.conn.pid)
      Process.monitor(chan.pid)

      {:ok, chan}
    end
  end

  def ensure_channel(chan, _conn), do: {:ok, chan}

  @doc false
  def handle_call({:with_channel, func, setup}, _from, {chan, conn}) do
    with {:ok, chan} <- ensure_channel(chan, conn),
         {:ok, chan} <- setup.(chan) do
      {:reply, func.(chan), {chan, conn}}
    else
      {:error, reason} -> {:reply, {:error, reason}, {chan, conn}}
    end
  rescue
    e ->
      {:reply, {:error, e}, {chan, conn}}
  end

  @doc false
  def handle_info({:DOWN, _, :process, _pid, _reason}, _state) do
    {:noreply, nil}
  end

  @doc false
  def terminate(_reason, {nil, _conn}), do: :ok

  def terminate(_reason, {chan, _conn}) do
    if Process.alive?(chan.pid) do
      AMQP.Channel.close(chan)
    end

    :ok
  end
end
