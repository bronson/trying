require File.dirname(File.absolute_path(__FILE__)) + '/spec_helper'

describe "Retryable#retryable" do
  include Retryable

  def do_retry(opts = {})  ##########
    @num_calls = 0
    return retryable(@retryable_opts) do
      @num_calls += 1
      if exception = opts[:raising]
        raise exception if opts[:when].nil? || opts[:when].call
      end
      opts[:returning]
    end
  end

  def count_retryable *opts
    @count = 0
    return retryable(*opts) { |*args| @count += 1; yield *args }
  end

  it "should not affect the return value of the block given" do
    count_retryable { 'foo' }.should == 'foo'
    @count.should == 1
  end

  it "should not affect the return value of the block given when there is a retry" do
    count_retryable { |tries| raise StandardError if tries < 1; 'foo' }.should == 'foo'
    @count.should == 2
  end

  it "passes the exception to the application" do
    lambda { count_retryable { raise StandardError } }.should raise_error(StandardError)
    @count.should == 2
  end

  it "should not catch Exceptions by default" do
    lambda { count_retryable { raise Exception } }.should raise_error(Exception)
    @count.should == 1
  end

  describe "with the :tries option set" do
    before(:each) do
      @retryable_opts = {:tries => 3}
    end

    it "uses retries :tries times when the exception to retry on occurs every time" do
      lambda {do_retry(:raising => StandardError)}.should raise_error(StandardError)
      @num_calls.should == 4
    end
  end

  describe "with the :on option set" do
    before(:each) do
      @retryable_opts = {:on => StandardError}
    end

    it "should catch any subclass exceptions" do
      do_retry(:raising => IOError, :when => lambda {@num_calls == 1})
      @num_calls.should == 2
    end

    it "should not catch any superclass exceptions" do
      lambda {do_retry(:raising => Exception, :when => lambda {@num_calls == 1})}.should raise_error(Exception)
      @num_calls.should == 1
    end
  end

  describe "with the :matching option set" do
    before(:each) do
      @retryable_opts = {:matching => /IO timeout/}
    end

    it "should catch an exception that matches the regexp" do
      lambda {do_retry(:raising => "there was like an IO timeout and stuffs", :when => lambda {@num_calls == 1})}.should_not raise_error(RuntimeError)
      @num_calls.should == 2
    end

    it "should not catch an exception that doesn't match the regexp" do
      lambda {do_retry(:raising => "ERRROR of sorts", :when => lambda {@num_calls == 1})}.should raise_error(RuntimeError)
      @num_calls.should == 1
    end
  end

  describe "with all the options set" do
    before(:each) do
      @retryable_opts = { :tries    => 3,
                          :on       => RuntimeError,
                          :sleep    => 0.3,
                          :matching => /IO timeout/ }
    end

    it "should still work as expected" do
      lambda {do_retry(:raising => "my IO timeout", :when => lambda {@num_calls < 4})}.should_not raise_error
      @num_calls.should == 4
    end
  end
end
