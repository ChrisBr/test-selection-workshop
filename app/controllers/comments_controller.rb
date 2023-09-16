class CommentsController < ApplicationController
  before_action :set_article
  before_action :set_comment, only: %i[ show edit update destroy ]

  # GET /comments/new
  def new
    @comment = @article.comments.new
  end

  # GET /comments/1/edit
  def edit
  end

  # POST /comments
  def create
    @comment = @article.comments.new(comment_params)

    respond_to do |format|
      if @comment.save
        format.html { redirect_to article_url(@article), notice: "Comment was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to article_url(@article), notice: "Comment was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  def destroy
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to article_url(@article), notice: "Comment was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = @article.comments.find(params[:id])
    end

    def set_article
      @article = Article.find(params[:article_id])
    end


    # Only allow a list of trusted parameters through.
    def comment_params
      params.require(:comment).permit(:title, :body, :article_id)
    end
end
