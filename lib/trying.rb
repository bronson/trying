module Trying
  class NestingError < Exception; end
  class InvalidOptions < RuntimeError; end

  # pass :reset to reset to defaults, or :ephemeral to merge options without modifying defaults
  def trying_options *options
    @trying_options = nil if options.delete :reset   # for testing
    is_ephemeral = options.delete :ephemeral

    @trying_options ||= {
      :tries     => 2,
      :on        => StandardError,
      :sleep     => 1,
      :matching  => /.*/,
      :detect_nesting => false,
      :logger    => lambda { |task,r,e| STDERR.puts "#{task}#{" RETRY #{r}" if r > 0}#{" because #{e}" if e}" },
      :task      => nil,
    }

    options = @trying_options.merge options.last || {}
    typos = options.keys - @trying_options.keys
    raise InvalidOptions.new("Invalid options: #{typos.join(", ")}") unless typos.empty?
    @trying_options = options unless is_ephemeral
    options
  end

  def trying *options, &block
    options = trying_options :ephemeral, *options
    return nil if options[:tries] < 1

    raise NestingError.new("Nested trying: #{@trying_nest}") if @trying_nest
    @trying_nest = caller(2).first if options[:detect_nesting]

    previous_exception = nil
    retry_exceptions = [options[:on]].flatten
    retries = 0

    begin
      options[:logger].call(options[:task],retries,previous_exception) if options[:task]
      return yield retries, previous_exception
    rescue *retry_exceptions => exception
      raise unless exception.message =~ options[:matching]
      raise if retries+1 >= options[:tries]

      previous_exception = exception
      if options[:sleep] != nil
        sleep options[:sleep].respond_to?(:call) ? options[:sleep].call(retries) : options[:sleep]
      end
      retries += 1
      retry
    ensure
      @trying_nest = nil
    end
  end
end
