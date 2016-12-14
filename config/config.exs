use Mix.Config

import_config "#{Mix.env}.exs"

config :distillery, no_warn_missing: [ :poison, :plug ]

config :evl_daemon, host: '127.0.0.1'
config :evl_daemon, port: 4025
config :evl_daemon, password: "SECRET"
config :evl_daemon, auto_connect: false
