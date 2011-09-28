require_relative "helper"

describe Squirm::Pool do
  describe "#checkout" do
    it "should wait until timeout if all connections busy" do
      assert try_checkout(0.05, 0.02)
    end

    it "should raise error if pool checkout times out" do
      assert_raises Squirm::Timeout do
        try_checkout(0.02, 0.05)
      end
    end

    private

    def try_checkout(timeout, sleep_time)
      pool = Squirm::Pool.new(timeout)
      pool.checkin Object.new
      t1 = Thread.new do
        conn = pool.checkout
        sleep(sleep_time)
        pool.checkin conn
      end
      t2 = Thread.new {
        sleep(0.01)
        pool.checkout
      }
      [t1, t2].map(&:value)
      true
    end
  end
end

