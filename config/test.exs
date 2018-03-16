use Mix.Config

config :btrz_auth, :token,
  issuer: "btrz-api-client",
  main_secret: "NfUeAlyXW4ItToJokpFpdd4b5BhDGEE+3b9stOChnhkuLjRPMOgIVcRIqP8jCDeV",
  secondary_secret: "t0PCMbBHkow/PUPH3Cz5gj66MrTI5t22iNCT2et3FqtHVvjhyDJ6kqOtrKTI6l3b"

config :btrz_auth, :db,
  uris: ["127.0.0.1:27017"],
  database: "betterez_core",
  username: "",
  password: "",
  collection_name: "applications",
  property: "key"
