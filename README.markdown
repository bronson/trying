# Trying

Execute a block until it succeeds.  Punch it until it yields.

[![Build Status](https://api.travis-ci.org/bronson/trying.png?branch=master)](http://travis-ci.org/bronson/trying)
[![Coverage Status](https://coveralls.io/repos/bronson/trying/badge.png?branch=master)](https://coveralls.io/r/bronson/trying)
[![Code Climate](https://codeclimate.com/github/bronson/trying.png)](https://codeclimate.com/github/bronson/trying)
[![Dependency Status](https://gemnasium.com/bronson/trying.png)](https://gemnasium.com/bronson/trying)

    module HardHatMac
      include Trying

      def boot
        trying 3.times, :on => IOError do
         read_floppy
        end
      end
    end

If the first read_floppy attempt raises an IOError, it will be tried twice more before giving up.


## Install

* `gem 'trying'`

Then include it in the module or class that will call it.
This allows unrelated libraries to use their own defaults without conflict.

You can include it globally if laziness is a virtue:

    require "trying"
    include Trying
    trying_options detect_nesting: true


## Sleeping

Normally there's a one second delay between retries.
You can change this, even providing your own exponential backoff scheme.

    trying(:sleep => 0) { }                    # no pause between retries
    trying(:sleep => 10) { }                   # sleep ten seconds between retries
    trying(:sleep => lambda { |n| 4**n }) { }  # sleep 1, 4, 16, etc. each try
    trying(:sleep => nil) { }                  # don't even call sleep


## Exceptions

By default any exception that inherits from StandardError gets retried.
This usually retries runtime errors (IOError, floating point) but lets
catastrophic errors (missing method, nil reference) pass right on through.

Usually you only want to retry a few exception types anyway:

    trying :on => [IOError, RangeError] do
      ...
    end

If you really want to retry everything then use `:on => Exception`, but
do you really want to retry method missing, out of memory, and other errors that can't be fixed by trying again?

More background on Ruby exceptions:

 * <http://blog.nicksieger.com/articles/2006/09/06/rubys-exception-hierarchy>
 * <http://www.zenspider.com/Languages/Ruby/QuickRef.html#exceptions-catch-and-throw>

It's clumsier but you can also retry based on the exception message:

    trying(:matching => /export/) { ... }


## Parameters

Your block is called with two optional parameters: the number of tries until now,
and the most recent exception.

    trying 6.times do |tries, exception|
      if tries < 2
        pick_up_soap
      else
        scrape_up_soap
      end
    end


## Logging

Specify a task to have a little automated logging:

    trying 5.times, :task => 'picking up sticks') do
      raise TypeError.new "they're bricks"
    end

Prints:

    picking up sticks
    picking up sticks RETRY 1 because IOError

Use :logger to change the log message or destination:

    trying_options :logger => lambda { |task,retries,error|
      logger.error "retry #{task} #{retries}: #{error}" if retries > 0
    }

Now prints:

    retry picking up sticks 0: they're bricks
    retry picking up sticks 1: they're bricks


## Nesting

Accidentally nesting callbacks can be a real problem.  What you thought was
a 6 minute maximum delay could end up being 36 minutes or worse.
Nesting detection is off by default but it's easy to turn on:

    trying_options :detect_nesting => true
    trying 4.times do
      trying 2.times { thread_needle }   # thread_needle will never be called
    end

When a nested call is detected, a Trying::NestedException gets thrown.
This is not a StandardError, so it's not retried by default, and the error
will propagate out.


## Options

These are the default options:

* :tries => 2  # try the call once, then retry once
* :on => StandardError
* :sleep => 1
* :matching => /.*/
* :detect_nesting => false
* :logger => lambda { |task,retries,error| ... }  # only logs if you specify a :task
* :task => nil

You can pass custom settings every time you call the retryable command,
or call retryable_options to change the default settings:

    retryable_options :tries => 5, :sleep => 20
    retryable { catch_dog }


## Examples

Open an URL, retry up to two more times when an `OpenURI::HTTPError` occurs.

    require "trying"
    require "open-uri"

    include Trying

    trying 3.times, :on => [OpenURI::HTTPError, Errno::ECONNRESET] do
      xml = open("http://google.com/").read
    end

Print the default settings:

    ruby -r ./lib/trying.rb -e "include Trying; puts Trying.trying_options.inspect"


## Alternatives

* NodeJS: <https://github.com/tim-kos/node-retry>
* Robert Sosinnski's Retryable: https://github.com/robertsosinski/retryable
* Nikita Fedyashev's Retryable: https://github.com/nfedyashev/retryable
* Richard Schneeman's Rrrretry: https://github.com/schneems/rrrretry
* Haakon Sorensen's Retry: http://retry.rubyforge.org/


## License

Per Chu: MIT or public domain, your choice.


## History

The story until now...

* 2008 [Cheah Chu Yeow](https://github.com/chuyeow/try)
  wrote retryable as a freedompatch on Kernel and wrote a
  [blog post](http://blog.codefront.net/2008/01/14/retrying-code-blocks-in-ruby-on-exceptions-whatever/).
* 2009 [Carlo Zottmann](https://github.com/carlo/retryable)
  converted it to a gem and made it a separate method.
* 2010 [Songkick](https://github.com/songkick/retryable)
  converted it to a module and added :matching and :sleep.
* 2011 [Scott Bronson](https://github.com/bronson/retryable)
  rebased it back onto Chu's repo, added flexible sleep and nesting detection.
* 2012 [Nikita Fedyashev](https://github.com/nfedyashev/retryable)
  resurrected Carlo's repo and made a new retryable gem release.
* 2013 [Scott Bronson](https://github.com/bronson/trying)
  renamed his fork to trying and released this gem.
