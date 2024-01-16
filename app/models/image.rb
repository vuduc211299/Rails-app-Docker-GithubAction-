class Image < ApplicationRecord

  belongs_to :user

  validates :title, presence: { message: "Title can't be blank and should have at least 6 chars" }, length: { minimum: 6 }
  validates :description, allow_blank: true, length: { maximum: 20 }
  validates :url, presence: { message: "Please select an image" }

  def self.s3_resource
    @s3 ||= Aws::S3::Resource.new
  end

  def s3_uploader(file, name)
    s3_resource = Image.s3_resource
    bucket = s3_resource.bucket(ENV.fetch("AWS_BUCKET"))
    begin
      obj = bucket.put_object(body: file, key: name)
    rescue Aws::S3::Errors::ServiceError => error
      Rails.logger.error "Error message: #{error}"
      return nil
    end
  end

  def signed_url
    begin
      s3_resource = Image.s3_resource
      s3_obj = s3_resource.bucket(ENV.fetch("AWS_BUCKET")).object(url)
      signed_url = s3_obj.presigned_url(:get, expires_in: 3600)
    rescue Aws::S3::Errors => error
      Rails.logger.error "Error message: #{error}"
    end
  end
end
