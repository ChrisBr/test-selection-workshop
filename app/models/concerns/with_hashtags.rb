module WithHashtags
  def hashtags
    body.scan(/#\w+/).flatten
  end
end
