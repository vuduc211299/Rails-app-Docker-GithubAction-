# frozen_string_literal: true

# The ImagesController handles the logic for managing images in the application.
class ImagesController < ApplicationController
  before_action :authenticate_user!
  # load_and_authorize_resource

  # Retrieves all images belonging to the current user and assigns them to the @images instance variable.
  def index
    @images = current_user.images.all
  end

  # Initializes a new Image object and assigns it to the @image instance variable.
  def new
    @image = Image.new
  end

  # Finds the image with the specified ID belonging to the current user and assigns it to the @image instance variable.
  # If the image is not found, redirects to the images index page with a notice.
  def edit
    @image = current_user.images.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to images_url, notice: 'Image not found'
    nil
  end

  # Updates the image with the specified ID.
  # If a file is uploaded, it is validated and stored in an S3 bucket.
  # If there are any errors during the upload or save process, logs the error message and redirects to the edit image page with a notice.
  def update
    url, uploaded_file = image_url
    validate_upload_file(uploaded_file) if uploaded_file

    image_update(url)
  rescue Aws::S3::Errors, StandardError, ActiveRecord::RecordNotFound => e
    Rails.logger.error "Error message: #{e.message}"
    redirect_to edit_image_url, notice: e.message.to_s
  end

  # Deletes the image with the specified ID.
  # If the image is not found, redirects to the images index page with a notice.
  def destroy
    @image = current_user.images.find(params[:id])

    @image.s3_remove_object
    @image.destroy
    redirect_to images_url, notice: 'Image was successfully deleted.'
  rescue ActiveRecord::RecordNotFound
    redirect_to images_url, notice: 'Image not exist'
  end

  # Creates a new image record in the database based on the provided parameters.
  # If a file is uploaded, it is validated and stored in an S3 bucket.
  # If the image is successfully saved, redirects to the images index page with a success notice.
  # If there are any errors during the upload or save process, logs the error message and redirects to the new image page with an error notice.
  def create
    url, uploaded_file = image_url
    validate_upload_file(uploaded_file) if uploaded_file

    image_create(url)
  rescue Aws::S3::Errors, StandardError, ActiveRecord::RecordNotFound => e
    Rails.logger.error "Error message: #{e}"
    redirect_to new_image_url, notice: "Error: #{e.message}"
  end

  private

  # Strong parameters for image upload.
  def upload_params
    params.require(:image).permit(:title, :description, :url)
  end

  # Validates the uploaded file.
  # Raises an exception if the file type is not supported or if the file size exceeds the limit.
  def validate_upload_file(uploaded_file)
    unless ['image/jpeg', 'image/png', 'image/jpg'].include? uploaded_file.content_type # check the file type
      raise 'Please upload valid image file, only jpeg, jpg and png are allowed'
    end

    return unless uploaded_file.size > 5.megabytes # check the file size

    raise 'Please upload image file smaller than 5MB.'
  end

  # Retrieves the uploaded file URL and the uploaded file itself from the upload_params.
  def image_url
    return unless upload_params[:url]

    uploaded_file = upload_params[:url]
    tmp_file = uploaded_file.tempfile
    file_name = uploaded_file.original_filename

    @image = Image.new
    obj = @image.s3_uploader(tmp_file, file_name)
    version_id = obj.version_id
    ["#{file_name}-#{version_id}", uploaded_file]
  end

  # Updates the image with the specified ID using the provided URL.
  # If the image fails to save, renders the edit page.
  # If the image is successfully updated, redirects to the images index page with a success notice.
  def image_update(url)
    @image = current_user.images.find(params[:id])
    @image.update(
      upload_params.merge(url: url)
    )

    unless @image.save
      render :edit
      return
    end

    redirect_to images_url, notice: 'Image was successfully updated.'
  end

  # Creates a new image record in the database using the provided URL.
  # If the image fails to save, renders the new page.
  # If the image is successfully created, redirects to the images index page with a success notice.
  def image_create(url)
    @image = current_user.images.new(
      upload_params.merge(url: url)
    )

    unless @image.save
      render :new
      return
    end

    redirect_to images_url, notice: 'Image was successfully created.'
  end
end
