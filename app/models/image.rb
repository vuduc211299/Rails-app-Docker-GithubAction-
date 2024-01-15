class Image < ApplicationRecord

  belongs_to :user

  def self.s3_uploader(file, name)
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV.fetch("AWS_BUCKET"))
    obj = bucket.put_object(body: file, key: name)
  end
end
