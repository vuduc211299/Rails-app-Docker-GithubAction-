# frozen_string_literal: true

# Represents an image in the application.
class Image < ApplicationRecord
  belongs_to :user

  # Validates the presence and length of the title attribute.
  validates :title, presence: { message: "Title can't be blank and should have at least 6 chars" },
                    length: { minimum: 6 }

  # Validates the length of the description attribute, allowing it to be blank.
  validates :description, allow_blank: true, length: { maximum: 20 }

  # Validates the presence of the url attribute.
  validates :url, presence: { message: 'Please select an image' }

  # Returns the AWS S3 resource for uploading files.
  def self.s3_resource
    @s3_resource ||= Aws::S3::Resource.new
  end

  # Uploads a file to AWS S3 bucket.
  #
  # file - The file to be uploaded.
  # name - The name of the file.
  #
  # Returns nil if an error occurs during the upload.
  def s3_uploader(file, name)
    s3_bucket.put_object(body: file, key: name)
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "Error message: #{e}"
    nil
  end

  # Removes an object from AWS S3 bucket.
  def s3_remove_object
    key, version_id = file_name_and_version_id
    begin
      s3_bucket.delete_objects(removed_obj(key, version_id))
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Error message: #{e}"
      nil
    end
  end

  # Returns a signed URL for accessing the image from AWS S3 bucket.
  def signed_url
    file_name, version_id = file_name_and_version_id
    s3_obj = s3_bucket.object(file_name)
    s3_obj.presigned_url(:get, expires_in: 3600, version_id: version_id)
  rescue Aws::S3::Errors => e
    Rails.logger.error "Error message: #{e}"
  end

  private

  # Extracts the file name and version ID from the URL.
  def file_name_and_version_id
    reverse_url = url.reverse
    version_id = reverse_url[0..reverse_url.index('-') - 1].reverse
    file_name = url.gsub("-#{version_id}", '')

    [file_name, version_id]
  end

  def removed_obj(key, version_id)
    {
      delete: {
        objects: [
          {
            key: key,
            version_id: version_id
          }
        ]
      }
    }
  end

  def s3_bucket
    s3_resource = Image.s3_resource
    s3_resource.bucket(ENV.fetch('AWS_BUCKET'))
  end
end
