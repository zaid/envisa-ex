defmodule EvlDaemon.EventNotifier do
  @moduledoc """
  This module defines the behaviour of an event notifier.
  """

  @callback filter(event :: EvlDaemon.Event) :: boolean
  @callback notify(event :: EvlDaemon.Event, opts :: [any]) :: atom

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour EvlDaemon.EventNotifier

      require Logger
      use GenServer

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts)
      end

      def init(opts) do
        EvlDaemon.EventDispatcher.subscribe({__MODULE__, :filter})

        {:ok, opts}
      end

      @doc """
      Used by the dispatcher to only send events that we are interested in.
      """
      def filter(_term) do
        true
      end

      @doc """
      Log the notification for the event.
      """
      def notify(_event, _opts), do: raise "Override me!"

      # Callbacks

      @doc false
      def handle_info({:handle_events, events}, opts) do
        notify(events, opts)

        {:noreply, opts}
      end

      defoverridable [filter: 1, notify: 2]
    end
  end
end
