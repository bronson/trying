module Trying
  class NestingError < Exception; end
  class InvalidOptions < RuntimeError; end

  def trying_merge dst, src
    typos = src.keys - dst.keys
    raise InvalidOptions.new("Invalid options: #{typos.join(", ")}") unless typos.empty?
    dst.merge! src
  end

  def trying_options options=nil
    @trying_options = options = nil if options == :reset   # for testing
    @trying_options ||= {
      :tries     => 2,
      :on        => StandardError,
      :sleep     => 1,
      :matching  => /.*/,
      :detect_nesting => false,
      :logger    => lambda { |task,r,e| STDERR.puts "#{task}#{" RETRY #{r}" if r > 0}#{" because #{e}" if e}" },
      :task      => nil,
    }

    trying_merge @trying_options, options if options
    @trying_options
  end

  def trying options = {}, &block
    opts = trying_options.dup
    trying_merge opts, options
    return nil if opts[:tries] < 1

    raise NestingError.new("Nested trying: #{@trying_nest}") if @trying_nest
    @trying_nest = caller(2).first if opts[:detect_nesting]

    previous_exception = nil
    retry_exceptions = [opts[:on]].flatten
    retries = 0

    begin
      opts[:logger].call(opts[:task],retries,previous_exception) if opts[:task]
      return yield retries, previous_exception
    rescue *retry_exceptions => exception
      raise unless exception.message =~ opts[:matching]
      raise if retries+1 >= opts[:tries]

      previous_exception = exception
      if opts[:sleep] != nil
        sleep opts[:sleep].respond_to?(:call) ? opts[:sleep].call(retries) : opts[:sleep]
      end
      retries += 1
      retry
    ensure
      @trying_nest = nil
    end
  end
end
