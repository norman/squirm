require 'test_helper'

class StoredProceduresTest < ActiveSupport::TestCase

  test "hello world should emit a greeting" do
    procedure = Squirm.procedure "hello_world"
    assert_equal "hello world!", procedure.call
  end

end
