require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
  describe Util do
    describe "check_opts" do
      it "should permit a nil opts Hash" do
        Util.check_opts({}, nil).should == {}
      end

      it "should return an equals opts Hash" do
        Util.check_opts({:foo=>nil}, {:foo=>10}).should == {:foo=>10}
      end

      it "should raise an exception if an opt is given with no matching constraint" do
        lambda {
          Util.check_opts({:foo=>nil}, {:bar=>10})
        }.should raise_error(/not permitted: :bar/)
      end

      it "should raise an exception if the value of an opt with an Array constraint is not in the Array" do
        lambda {
          Util.check_opts({:foo=>[1,2,3]}, {:foo=>10})
        }.should raise_error(/unknown value/)
      end

      it "should permit an opt with an Array constraint to have a nil value" do
        Util.check_opts({:foo=>[1,2,3]}, {}).should == {}
      end

      it "should check_opts for opts with Hash constraints" do
        lambda {
          Util.check_opts({:foo=>{:bar=>[1,2,3]}}, {:foo=>{:bar=>10}})
        }.should raise_error(/unknown value/)
      end

      it "should permit sub-hashes to be skipped with a nil value" do
        Util.check_opts({:foo=>{:bar=>10}}, {}).should == {}
      end
    end
  end
end
