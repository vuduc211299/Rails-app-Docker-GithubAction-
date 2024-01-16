# The ImagesController handles the logic for managing images in the application.
class ImagesController < ApplicationController
  # Retrieves all images from the database and assigns them to the @images instance variable.
  def index
    @images = Image.all
  end

  # Initializes a new Image object and assigns it to the @image instance variable.
  def new
    @image = Image.new
  end

  # Creates a new image record in the database based on the provided parameters.
  # If a file is uploaded, it is validated and stored in an S3 bucket.
  # The image record is then saved with the provided title, description, URL, and user ID.
  # If the image is successfully saved, the user is redirected to the index page with a success notice.
  # If there are any errors during the upload or save process, the user is redirected to the new page with an appropriate notice.
  def create
    begin
      if upload_params[:url]
        uploaded_file = upload_params[:url]
        tmp_file = uploaded_file.tempfile
        file_name = uploaded_file.original_filename

        validate_upload_file(uploaded_file)
      else
        file_name = nil
      end

      if file_name
        @image = Image.new
        @image.s3_uploader(tmp_file, file_name)
      end

      @image = Image.new(
        title: upload_params[:title],
        description: upload_params[:description],
        url: file_name,
        user_id: current_user.id
      )

      if @image.save
        redirect_to images_url, notice: 'Image was successfully created.'
      else
        render :new
      end
    rescue Aws::S3::Errors => error
      Rails.logger.error "Error message: #{error}"
      redirect_to new_image_url, notice: 'Image upload failed.'
    rescue => error
      redirect_to new_image_url, notice: error.message
    end
  end

  private

  # Strong parameters for image upload.
  def upload_params
    params.require(:image).permit(:title, :description, :url)
  end

  # Validates the uploaded file.
  # Raises an exception if the file type is not supported or if the file size exceeds the limit.
  def validate_upload_file(uploaded_file)
    unless ['image/jpeg', 'image/png', 'image/jpg'].include? uploaded_file.content_type  # check the file type
      raise 'Please upload valid image file, only jpeg, jpg and png are allowed'
    end

    if uploaded_file.size > 5.megabytes # check the file size
      raise 'Please upload image file smaller than 5MB.'
    end
  end
end
