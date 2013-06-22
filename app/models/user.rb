class User < ActiveRecord::Base
  before_save :create_remember_token

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      user.name = auth['info']['name']
    end
  end

  private
  def create_remember_token
    self.create_remember_token = SecureRandom.urlsafe_base64
  end
end
