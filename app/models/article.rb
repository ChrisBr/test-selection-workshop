class Article < ApplicationRecord
  include WithHashtags

  has_many :comments, dependent: :destroy
  validates :title, presence: true

  validate :body_mentions_rails

  private

  def body_mentions_rails
    unless body.to_s.downcase.include?('rails')
      errors.add(:body, 'doesnt mention Rails!')
    end
  end
end
