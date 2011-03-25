require File.dirname(File.absolute_path(__FILE__)) + '/../lib/retryable'

describe "Retryable#retryable" do
  include Retryable

  before :each do
    retryable_options :reset
  end

  def sleep n
    # each test should set its own expectation on how sleep will be called
    raise "Don't call sleep during testing!"
  end

  def should_raise e
    lambda { yield }.should raise_error e
  end

  def count_retryable *opts
    @count = 0
    return retryable(*opts) { |*args| @count += 1; yield *args }
  end


  it "should not affect the return value of the block" do
    should_not_receive :sleep
    count_retryable { 'foo' }.should == 'foo'
    @count.should == 1
  end

  it "should not affect the return value when there is a retry" do
    should_receive(:sleep).once.with(1)
    count_retryable { |tries| raise StandardError if tries < 1; 'foo' }.should == 'foo'
    @count.should == 2
  end

  it "passes the exception to the application" do
    should_receive(:sleep).once.with(1)
    should_raise(IOError) {
      count_retryable { raise IOError }
    }
    @count.should == 2
  end

  it "should not catch Exceptions by default" do
    should_not_receive :sleep
    should_raise(Exception) {
      count_retryable { raise Exception }
    }
    @count.should == 1
  end

  it "doesn't call the proc if :tries is 0" do
    should_not_receive :sleep
    count_retryable(:tries => 0) { raise StandardError }
    @count.should == 0
  end

  it "retries the specified number of times" do
    should_receive(:sleep).exactly(3).times.with(1)
    should_raise(StandardError) {
      count_retryable(:tries => 3) { raise StandardError }
    }
    @count.should == 4
  end

  it "retries exceptions that are covered by :on" do
    # FloatDomainError is a subclass of RangeError
    should_receive(:sleep).once.with(1)
    should_raise(FloatDomainError) {
      count_retryable(:on => RangeError) { raise FloatDomainError }
    }
    @count.should == 2
  end

  it "doesn't retry exceptions that aren't covered by :on" do
    # NameError is a sibliing of RangeError, not a subclass
    should_not_receive :sleep
    should_raise(NameError) {
      count_retryable(:on => RangeError) { raise NameError }
    }
    @count.should == 1
  end

  it "should catch an exception that matches the regex" do
    should_receive(:sleep).once.with(1)
    count_retryable(:matching => /IO timeout/) { |c| raise "yo, IO timeout!" if c == 0 }
    @count.should == 2
  end

  it "should not catch an exception that doesn't match the regex" do
    should_not_receive :sleep
    should_raise(RuntimeError) {
      count_retryable(:matching => /TimeError/) { raise "yo, IO timeout!" }
    }
    @count.should == 1
  end

  it "works with all the options set" do
    should_receive(:sleep).exactly(3).times.with(0.3)
    count_retryable(:tries => 3, :on => RuntimeError, :sleep => 0.3, :matching => /IO timeout/) { |c| raise "my IO timeout" if c < 3 }
    @count.should == 4
  end

  it "works with all the options set globally" do
    should_receive(:sleep).exactly(3).times.with(0.3)
    retryable_options :tries => 3, :on => RuntimeError, :sleep => 0.3, :matching => /IO timeout/
    count_retryable { |c| raise "my IO timeout" if c < 3 }
    @count.should == 4
  end

  it "sends the previous exception to the block" do
    should_receive(:sleep).once.with(1)
    retryable { |tries, e|
      raise IOError if tries == 0         # first time through the loop
      e.should be_an_instance_of IOError  # make sure second time matches the first
    }
  end

  it "accepts :tries as a global option" do
    should_receive(:sleep).exactly(3).times.with(1)
    retryable_options :tries => 3
    should_raise(RangeError) {
      count_retryable { raise RangeError }
    }
    @count.should == 4
  end
end
