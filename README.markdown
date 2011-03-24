# Retryable

Runs a code block and retries it when an exception occurs.

It's configured using four optional parameters `:tries`, `:on`, `:matching` and `:sleep`, and
runs the passed block. Should an exception occur, it'll retry for (tries-1) times.

Should the number of retries be reached without success, the last exception
will be raised.


## Examples

Open an URL, retry up to two times when an `OpenURI::HTTPError` occurs.

    require "retryable"
    require "open-uri"

    include Retryable

    retryable( :tries => 3, :on => OpenURI::HTTPError ) do
      xml = open( "http://example.com/test.xml" ).read
    end

Do _something_, retry up to four times for either `ArgumentError` or
`TimeoutError` exceptions.

    require "retryable"
    include Retryable

    retryable( :tries => 5, :on => [ ArgumentError, TimeoutError ] ) do
      # some crazy code
    end



Do _something_, retry up to three times for `ArgumentError` exceptions
which smell like "Bacon", but have a nap between tries.

    require "retryable"
    include Retryable

    retryable( :tries => 3,
               :on => ArgumentError,
               :matching => /Bacon/,
               :sleep => 3) do

      # some crazy code about bacon
    end




## Defaults

    :tries => 1, :on => Exception, :matching => /.*/, :sleep => 0


