module Retryable
  class NestingError < Exception; end
  class InvalidOptions < RuntimeError; end

  def retryable_merge dst, src
    typos = src.keys - dst.keys
    raise InvalidOptions.new("Invalid options: #{typos.join(", ")}") unless typos.empty?
    dst.merge! src
  end

  def retryable_options options=nil
    @retryable_options = options = nil if options == :reset   # for testing
    @retryable_options ||= {
      :tries     => 2,
      :on        => StandardError,
      :sleep     => 1,
      :matching  => /.*/,
      :detect_nesting => false,
      :logger    => lambda { |task,r,e| STDERR.puts "#{task}#{" RETRY #{r}" if r > 0}#{" because #{e}" if e}" },
      :task      => nil,
    }

    retryable_merge @retryable_options, options if options
    @retryable_options
  end

  def retryable options = {}, &block
    opts = retryable_options.dup
    retryable_merge opts, options
    return nil if opts[:tries] < 1

    raise NestingError.new("Nested retryable: #{@retryable_nest}") if @retryable_nest
    @retryable_nest = caller(2).first if opts[:detect_nesting]

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
      @retryable_nest = nil
    end
  end
end
