defmodule Garden.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Garden.MemoryNode,
      Garden.PruningAgent,
      Garden.BloomAgent,
      Garden.WatcherAgent,
      Garden.CycleAgent,
      Garden.LedgerAgent,
      Garden.SeedVault
    ]

    opts = [
      strategy: :one_for_one,
      name: Garden.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
