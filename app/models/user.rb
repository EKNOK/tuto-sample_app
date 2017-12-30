class User < ApplicationRecord
  attr_accessor :remember_token
  before_save {self.email = self.email.downcase}
  validates :name, presence: true, length: {maximum: 50}
  validates :email, presence: true, length: {maximum: 255},
                    format: {with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: {case_sensitive: false}
  validates :password, presence: true, length: {minimum: 3}
  has_secure_password

  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                              BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end


    # ランダムなトークンを返す
    def new_token
      SecureRandom.urlsafe_base64
    end

    # 永続的セッションのためにユーザーをデータベースに記憶する
    def remember(user)
      user.remember
      cookies.permanent.signed[:user_id] = user.id
      cookies.permanent[:remember_token] = user.remember_token
    end

    # 渡されたトークンがダイジェストと一致したらtrueを返す
    def authenticate?(remember_token)
      Bcrypt::Password.new(remember_digest).is_password?(remember_token)
    end

end
