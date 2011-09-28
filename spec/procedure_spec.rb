require_relative "helper"

describe Squirm::Procedure::Arguments do

  it "should have a count" do
    args = Squirm::Procedure::Arguments.new("text, text")
    assert_equal 2, args.count
  end

  it "should number duplicate names" do
    args = Squirm::Procedure::Arguments.new("text, text, text")
    assert_equal "text", args[0]
    assert_equal "text2", args[1]
    assert_equal "text3", args[2]
  end

  it "should detect named args" do
    args = Squirm::Procedure::Arguments.new("hello text, world text")
    assert_equal "hello", args[0]
    assert_equal "world", args[1]
  end

  it "should remove leading underscores from arg names" do
    args = Squirm::Procedure::Arguments.new("_hello text, _world text")
    assert_equal "hello", args[0]
    assert_equal "world", args[1]
  end

  describe "#to_params" do
    it "should give a list of numeric params" do
      args = Squirm::Procedure::Arguments.new("text, text")
      assert_equal "$1::text, $2::text", args.to_params
    end
  end

  # describe "#format" do
  #   it "should return an array of args in the proper order" do
  #     args = Squirm::Procedure::Arguments.new("hello text, world text")
  #   end
  # end

end

describe Squirm::Procedure do

  before { Squirm.disconnect }
  after  { Squirm.disconnect }

  it "should have an info SQL statement" do
    assert_match(/SELECT/, Squirm::Procedure.new("foo").info_sql)
  end

  describe "#initialize" do
    it "should set a default schema if none is given" do
      procedure = Squirm::Procedure.new("foo")
      assert_equal 'public', procedure.schema
      assert_equal "foo", procedure.name
    end

    it "should set arguments if given" do
      procedure = Squirm::Procedure.new("foo", :args => "bar text")
      assert_equal 1, procedure.arguments.count
    end
  end

  describe "#load" do

    before { Squirm.connect $squirm_test_connection }

    it "should set the procedure's arguments" do
      Squirm.connect $squirm_test_connection
      proc = Squirm::Procedure.new("regexp_matches", :args => "text, text",
                                    :schema => "pg_catalog").load
      assert_equal ["text", "text2"], proc.arguments.to_a
    end

    it "should raise an exception if no function is found" do
      begin
        Squirm::Procedure.new("xxxxxx").load
        assert false, "should have raised error"
      rescue Squirm::Procedure::NotFound
        assert true
      end
    end

    it "should raise an exception if overloaded functions are loaded with no args" do
      begin
        Squirm::Procedure.new("date", :schema => "pg_catalog").load
        assert false, "should have raised error"
      rescue Squirm::Procedure::TooManyChoices
        assert true
      end
    end

    it "should load an overloaded functions if instance was initialized with :args" do
      assert Squirm::Procedure.new("date", :args => "abstime", :schema => "pg_catalog").load
    end

  end

  describe "#call" do

    before {Squirm.connect $squirm_test_connection}

    it "should yield the result to a block if given" do
      proc = Squirm::Procedure.new("date", :args => "abstime", :schema => "pg_catalog").load
      proc.call("Jan 1, 2011") do |result|
        assert_instance_of PGresult, result
      end
    end

    it "should return the value of a single-row result" do
      proc = Squirm::Procedure.new("date", :args => "abstime", :schema => "pg_catalog").load
      assert_equal "2011-01-01", proc.call("Jan 1, 2011")
    end

    it "should return the an array of hashes for set results" do
      Squirm.transaction do |conn|
        conn.exec(<<-SQL)
          CREATE TABLE temp_table (name varchar);
          INSERT INTO temp_table VALUES ('joe');
          INSERT INTO temp_table VALUES ('bob');
          CREATE FUNCTION temp_func() RETURNS SETOF temp_table AS $$
            BEGIN
              RETURN QUERY SELECT * FROM temp_table;
            END;
          $$ LANGUAGE 'plpgsql';
        SQL
        proc = Squirm::Procedure.new("temp_func").load
        result = proc.call
        assert_instance_of Array, result
        assert_instance_of Hash, result[0]
        Squirm.rollback
      end
    end
  end
end
