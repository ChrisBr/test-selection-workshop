class Comment < ApplicationRecord
  include WithHashtags

  belongs_to :article
  validates :title, presence: true
  validates :body, presence: true
end
