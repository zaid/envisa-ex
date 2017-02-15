defmodule EvlDaemon.Event do
  @moduledoc """
  This module includes the needed functions to return human-readable versions of the
  TPI responses.
  """

  @derive [Poison.Encoder]

  defstruct [:command, :data, :description, :priority, :timestamp]

  @doc """
  Return a new Event based on the payload and timestamp.
  """
  def new(payload, timestamp) do
    %EvlDaemon.Event{
      command: EvlDaemon.TPI.command_part(payload),
      data: EvlDaemon.TPI.data_part(payload),
      description: description(payload),
      priority: EvlDaemon.Event.Command.priority(payload),
      timestamp: timestamp,
    }
  end

  @doc """
  Return a human readable version of both the command and data portions of the event.
  """
  def description(payload) do
    (EvlDaemon.Event.Command.description(payload) <> " " <> EvlDaemon.Event.Data.description(payload))
    |> String.trim
  end
end
