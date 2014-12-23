[![Build Status](https://travis-ci.org/bkon/hpack.svg?branch=master)](https://travis-ci.org/bkon/hpack)
[![Code Climate](https://codeclimate.com/github/bkon/hpack/badges/gpa.svg)](https://codeclimate.com/github/bkon/hpack)
[![Test Coverage](https://codeclimate.com/github/bkon/hpack/badges/coverage.svg)](https://codeclimate.com/github/bkon/hpack)

# Hpack

Ruby implementation of the HPACK (Header Compression for HTTP/2) standard.

http://http2.github.io/http2-spec/compression.html

## Installation

Add this line to your application's Gemfile:

    gem 'hpack'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hpack

## Usage

```
require 'hpack'

io_stream = ... something which gives you IO object with data to be processed ...

decoder = Hpack::Decoder.new
decoder.decode io_stream do |header, value, metadata|
  ...
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hpack/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
