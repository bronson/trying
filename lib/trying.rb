module Trying
  class NestingError < Exception; end
  class InvalidOptions < RuntimeError; end

  # pass :reset to reset to defaults, or :params to merge options without modifying defaults
  def trying_options *args
    options = {}

    @trying_options = nil if args.delete :reset   # for testing
    just_params = args.delete :params             # not defaults
    options[:tries] = 1.0/0.0 if args.delete :forever

    arg = args.shift
    if arg.respond_to?(:max) && !arg.is_a?(Hash)  # 6.times
      options[:tries] = 1 + arg.max - arg.min
      arg = args.shift
    end
    if arg.respond_to?(:to_i) && !arg.nil?
      options[:tries] = arg.to_i
      arg = args.shift
    end

    raise InvalidOptions.new("Too many arguments: #{args.inspect}") unless args.size == 0
    if arg.is_a? Hash
      options.merge! arg
    elsif !arg.nil?
      raise InvalidOptions.new("Unknown argument: #{args.first.inspect}") unless args.first.is_a?(Hash)
    end

    @trying_options ||= {
      :tries     => 2,
      :on        => StandardError,
      :sleep     => 1,
      :matching  => /.*/,
      :detect_nesting => false,
      :logger    => lambda { |task,r,e| STDERR.puts "#{task}#{" RETRY #{r}" if r > 0}#{" because #{e}" if e}" },
      :task      => nil,
    }

    options = @trying_options.merge(options)
    typos = options.keys - @trying_options.keys
    raise InvalidOptions.new("Invalid options: #{typos.join(", ")}") unless typos.empty?
    @trying_options = options unless just_params
    options
  end

  def trying *args, &block
    options = trying_options(:params, *args)
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
