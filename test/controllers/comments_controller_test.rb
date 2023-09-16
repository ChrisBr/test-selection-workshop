require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:one)
    @comment = comments(:one)
  end

  test "should get new" do
    get new_article_comment_url(@article)
    assert_response :success
  end

  test "should create comment" do
    assert_difference("Comment.count") do
      post article_comments_url(@article), params: { comment: { article_id: @comment.article_id, body: @comment.body, title: @comment.title } }
    end

    assert_redirected_to article_url(@article)
  end

  test "should get edit" do
    get edit_article_comment_url(@article, @comment)
    assert_response :success
  end

  test "should update comment" do
    patch article_comment_url(@article, @comment), params: { comment: { article_id: @comment.article_id, body: @comment.body, title: @comment.title } }
    assert_redirected_to article_url(@article)
  end

  test "should destroy comment" do
    assert_difference("Comment.count", -1) do
      delete article_comment_url(@article, @comment)
    end

    assert_redirected_to article_url(@article)
  end
end
