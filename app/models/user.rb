class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :listings, dependent: :destroy
  has_many :saved_listings, through: :favorites, source: :listing
  enum role: { buyer: 0, seller: 1, admin: 2 }
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         

  # convenience
  def seller?
    role == "seller"
  end
end
