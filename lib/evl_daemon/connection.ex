defmodule EvlDaemon.Connection do
  use GenServer
  require Logger

  @initial_state %{socket: nil, event_dispatcher: nil, pending_commands: %{}, hostname: nil, port: 4025, password: nil}

  def start_link(state \\ @initial_state) do
    GenServer.start_link(__MODULE__, Map.merge(@initial_state, state), name: __MODULE__)
  end

  def connect do
    GenServer.call(__MODULE__, :connect)
  end

  def disconnect do
    GenServer.cast(__MODULE__, :disconnect)
  end

  def command(request) do
    GenServer.call(__MODULE__, { :command, request })
  end

  def handle_call(:connect, _sender, state) do
    Logger.debug "Connecting..."

    opts = [:binary, active: true, packet: :line]
    {:ok, socket} = :gen_tcp.connect(state.hostname, state.port, opts)
    new_state = %{state | socket: socket}

    {:reply, :ok, new_state}
  end

  def handle_call({:command, payload}, sender, state) do
    Logger.debug(fn -> "Sending [#{inspect payload}]" end)

    :ok = :gen_tcp.send(state.socket, EvlDaemon.TPI.encode(payload))

    cmd = EvlDaemon.TPI.command_part(payload)
    pending_commands = Map.put(state.pending_commands, cmd, sender)
    state = %{state | pending_commands: pending_commands}

    {:noreply, state}
  end

  def handle_cast(:disconnect, state) do
    Logger.debug "Disconnecting..."

    {:noreply, :gen_tcp.close(state.socket)}
  end

  def handle_info({:tcp, socket, "500" <> payload}, %{socket: socket} = state) do
    Logger.debug "Receiving acknowledgment for [#{inspect payload}]"

    cmd = EvlDaemon.TPI.command_part(payload)
    {client, pending_commands} = Map.pop(state.pending_commands, cmd)

    GenServer.reply(client, :ok)

    state = %{state | pending_commands: pending_commands}
    {:noreply, state}
  end

  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    {:ok, decoded_message} = EvlDaemon.TPI.decode(msg)

    Logger.debug(fn -> "Receiving [#{inspect msg}] (#{EvlDaemon.Event.description(decoded_message)})" end)
    EvlDaemon.EventDispatcher.enqueue(state.event_dispatcher, decoded_message)

    {:noreply, state}
  end
end
