require File.dirname(__FILE__) + '/../spec_helper'

describe "Retryable#retryable" do
  include Retryable

  def do_retry(opts = {})
    @num_calls = 0
    return retryable(@retryable_opts) do
      @num_calls += 1
      if exception = opts[:raising]
        raise exception if opts[:when].nil? || opts[:when].call
      end
      opts[:returning]
    end
  end

  describe "with default options" do
    before(:each) do
      @retryable_opts = {}
    end
    
    it "should not affect the return value of the block given" do
      retryable { 'foo' }.should == 'foo'
    end

    it "should not affect the return value of the block given when there is a retry" do
      do_retry(:returning => 'foo', :raising => StandardError, :when => lambda { @num_calls == 1 } ).should == 'foo'
      @num_calls.should == 2
    end

    it "uses default options of :tries => 1 and :on => StandardError when none is given" do
      lambda {do_retry(:raising => StandardError)}.should raise_error(StandardError)
      @num_calls.should == 2
    end
  
    it "should not catch Exceptions by default" do
      lambda {do_retry(:raising => Exception)}.should raise_error(Exception)
      @num_calls.should == 1
    end

    it "does not retry if none of the retry conditions occur" do
      do_retry
      @num_calls.should == 1
    end
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