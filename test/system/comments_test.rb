require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  setup do
    @article = articles(:one)
    @comment = comments(:one)
  end

  test "should create comment" do
    visit article_url(@article)
    click_on "New Comment"

    fill_in "Body", with: @comment.body
    fill_in "Title", with: @comment.title
    click_on "Create Comment"

    assert_text "Comment was successfully created"
    assert_text @comment.title
    assert_text @comment.body
    click_on "Back"
  end

  test "should update Comment" do
    visit article_url(@article)
    click_on "Edit this comment", match: :first

    fill_in "Body", with: @comment.body
    fill_in "Title", with: @comment.title
    click_on "Update Comment"

    assert_text "Comment was successfully updated"
    assert_text @comment.title
    assert_text @comment.body
    click_on "Back"
  end

  test "should destroy Comment" do
    visit article_url(@article)
    click_on "Destroy this comment", match: :first

    assert_text "Comment was successfully destroyed"
  end
end
