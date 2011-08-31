shared_examples_for "any redis object model" do
  describe "a model" do
    it "has redis_keys" do
      subject.should respond_to :redis_keys
    end

    it "deletes all redis keys when destroyed" do
      redis_keys = subject.redis_keys
      subject.destroy
      redis_keys.each do |key|
        Aji.redis.exists(key).should be_false,
          "#{key} exists in Redis when it shouldn't"
      end
    end
  end
end
