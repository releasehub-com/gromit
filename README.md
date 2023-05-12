# Gromit

Your documentation search assitant

## Usage

Make sure to provide your OpenAI token using the `OPENAPI_ACCESS_TOKEN` environment variable.

To mount the Gromit engine in Rails 7, require the engine from your `Gemfile`:

```ruby
gem "gromit", require: "gromit/engine"
```

And add this line to your routes:

```ruby
Rails.application.routes.draw do
  mount Gromit::Engine => "/"
end
```

Gromit provides the following routes:

```
Routes for Gromit::Engine:
healthcheck GET  /healthcheck(.:format) gromit/gromit#healthcheck {:format=>:json}
     search POST /search(.:format)      gromit/gromit#search {:format=>:json}
     upsert POST /upsert(.:format)      gromit/gromit#upsert {:format=>:json}
```

To index your documentation locally you can use `gromit-reindexer`. This will update `redis-stack-server` running on your machine.

```bash
bundle exec gromit-reindexer -s /path/to/your/docs
```

To remotely upsert your documentation you can use `gromit-uploader`.

```bash
BASE_URL=https://gromit-rails.example.com bundle exec gromit-uploader -s /path/to/your/docs
```

For a working example of a Rails 7 application using Gromit check out:
https://github.com/releasehub-com/gromit-example

## Installation

Add this line to your application's Gemfile:

```ruby
gem "gromit"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install gromit
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---
Made with love by the folks @ [release.com](https://release.com)
