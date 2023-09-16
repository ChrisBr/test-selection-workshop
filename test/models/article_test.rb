require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "is valid if body mentions Rails" do
    assert Article.new(title: "title", body: "Rails is awesome!").valid?
  end

  test "is invalid if body does not mention Rails" do
    refute Article.new(title: "title", body: "It doesn't scale").valid?
  end

  test "#hashtags extracts hashtags" do
    assert_includes Article.new(title: "title", body: "Rails is awesome! #rails").hashtags, "#rails"
  end
end
