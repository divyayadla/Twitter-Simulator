# Description

Implementation of a Twitter Clone and a client tester/simulator.

As of now, Twitter does not seem to support a WebSocket API. As part I of this project, we build an engine that (in part II) will be paired up with WebSockets to provide full functionality. Specific things we have to do are:

Implement a Twitter like engine with the following functionality:

-Register account

-Send tweet. Tweets can have hashtags (e.g. #COP5615isgreat) and mentions (@bestuser)

-Subscribe to user's tweets

-Re-tweets (so that your subscribers get an interesting tweet you got by other means)

-Allow querying tweets subscribed to, tweets with specific hashtags, tweets in which the user is mentioned (my mentions)

-If the user is connected, deliver the above types of tweets live (without querying)

Implement a tester/simulator to test the above -Simulate as many users as you can

-Simulate periods of live connection and disconnection for users

-Simulate a Zipf distribution on the number of subscribers. For accounts with a lot of subscribers, increase the number of tweets. Make some of these messages re-tweets


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `project4` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:project4, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/project4](https://hexdocs.pm/project4).

