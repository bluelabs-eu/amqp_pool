defmodule AMQPPool.Connection do
  @moduledoc false
  use GenServer

  @doc false
  def start_link(connection_options, name \\ :undefined) do
    GenServer.start_link(__MODULE__, [connection_options, name], name: __MODULE__)
  end

  @doc false
  def connection do
    GenServer.call(__MODULE__, :connection)
  end

  @doc false
  def new_channel do
    GenServer.call(__MODULE__, :new_channel)
  end

  # GenServer callbacks
  #
  # state is of the form `{connection_options, connection, channel_number, name}`
  @doc false
  def init([connection_options, name]) do
    {:ok, {connection_options, nil, nil, name}}
  end

  @doc false
  def handle_call(:connection, _from, state) do
    with {:ok, new_state = {_conn_opts, conn, _chan_number, _name}} <- ensure_connection(state) do
      {:reply, conn, new_state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:new_channel, _from, state) do
    with {:ok, new_state = {_conn_opts, conn, channel_number, _name}} <- ensure_connection(state),
         {:ok, chan} <- open_channel(conn, channel_number) do
      {:reply, {:ok, chan}, increment_channel_number(new_state)}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @doc false
  def handle_info({:DOWN, _, :process, _pid, _reason}, {conn_opts, _conn, _ch_num}) do
    # TODO log connection down
    {:noreply, {conn_opts, nil, nil}}
  end

  @doc false
  def terminate(_reason, {_conn_opts, nil, _chan_number, _name}), do: :ok

  def terminate(_reason, {_conn_opts, conn, _chan_number, _name}) do
    if Process.alive?(conn.pid) do
      AMQP.Connection.close(conn)
    end

    :ok
  end

  defp ensure_connection({connection_options, nil, _channel_number, name}) do
    with {:ok, conn} <- AMQP.Connection.open(connection_options, name) do
      Process.monitor(conn.pid)
      {:ok, {connection_options, conn, 1, name}}
    end
  end

  defp ensure_connection({connection_options, conn, channel_number, name}) do
    {:ok, {connection_options, conn, channel_number, name}}
  end

  defp increment_channel_number({conn_opts, conn, channel_number, name}) do
    {conn_opts, conn, channel_number + 1, name}
  end

  defp open_channel(conn, number) do
    with {:ok, chan_pid} <- :amqp_connection.open_channel(conn.pid, number) do
      chan = %AMQP.Channel{conn: conn, pid: chan_pid}
      {:ok, chan}
    end
  end
end
