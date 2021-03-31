require 'openssl'

class User < ApplicationRecord
  VALID_USERNAME = /\A\w+\z/.freeze
  VALID_EMAIL = /.+@.+\..+/i.freeze
  ITERATIONS = 20_000
  DIGEST = OpenSSL::Digest.new('SHA256')

  attr_accessor :password

  has_many :questions

  validates :username,
            presence: true,
            uniqueness: true,
            length: { maximum: 40 },
            format: { with: VALID_USERNAME }

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: VALID_EMAIL }

  validates :password, presence: true, on: :create
  validates :password, confirmation: true

  before_save :encrypt_password

  def self.hash_to_string(password_hash)
    password_hash.unpack1('H*')
  end

  def self.authenticate(email, password)
    user = find_by(email: email)
    return nil unless user.present?

    hashed_password = User.hash_to_string(
      OpenSSL::PKCS5.pbkdf2_hmac(
        password, user.password_salt, ITERATIONS, DIGEST.length, DIGEST
      )
    )
    return user if user.password_hash == hashed_password

    nil
  end

  private

  def encrypt_password
    if password.present?
      self.password_salt = User.hash_to_string(OpenSSL::Random.random_bytes(16))

      self.password_hash = User.hash_to_string(
        OpenSSL::PKCS5.pbkdf2_hmac(
          password, password_salt, ITERATIONS, DIGEST.length, DIGEST
        )
      )
    end
  end
end
