require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "#hashtags extracts hashtags" do
    assert_includes articles(:one).comments.new(title: "title", body: "Rails is awesome! #rails").hashtags, "#rails"
  end
end
