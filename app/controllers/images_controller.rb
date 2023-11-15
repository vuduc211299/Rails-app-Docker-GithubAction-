class ImagesController < ApplicationController

  def index
    @images = Image.all
  end

  def new
    @image = Image.new
  end
  # upload the images to s3, then save the url to DB
  def create
    uploaded_file = upload_params[:url]
    tmp_file = uploaded_file.tempfile
    file_name = uploaded_file.original_filename
    # get tmp_file, upload to s3, get the link of S3, then save it as url
    # after that save info into DB
    begin
      Image.s3_uploader(tmp_file, file_name)
      @image = Image.new(
        title: upload_params[:title],
        description: upload_params[:description],
        url: file_name
      )
      if @image.save
        flash[:notice] = 'Images was uploaded'
        redirect_to images_url
      else
        redirect_to images_url, error: 'Something went wrongs'
      end
    rescue Aws::S3::Errors => error
      Rails.logger.error "Error message: #{error}"
    end
  end

  private
  
  def upload_params
    params.require(:image).permit(:title, :description, :url)
  end
end
