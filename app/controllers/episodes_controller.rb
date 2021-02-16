require 'json'
require 'open-uri'
require 'rubygems'
require 'excon'
require 'net/http'
require 'aws-sdk-s3'

class EpisodesController < ApplicationController
  def index
    @episodes = Episode.all
  end

  def show
    @episode = Episode.find(params[:id])
  end

  def new
    @episode = Episode.new
  end



  def create
    @episode = Episode.new(episode_params)
    @episode.save!

    # Create an Episode on Podigee
    response_create_episode = create_an_episode(@episode.title)
    if response_create_episode.status == 200

      JSON.parse(response_create_episode.body).each do |json|
        @id = json.first['id']
      end

    # Generate an Upload URL from AWS
      response_upload_url = generate_upload_url
      if response_upload_url.status == 200

        @upload_url = JSON.parse(response_upload_url.body)['upload_url']
        @content_type = JSON.parse(response_upload_url.body)['content_type']
        @file_url = JSON.parse(response_upload_url.body)['file_url']
        @file = Rails.application.routes.url_helpers.rails_blob_path(@episode.audio, only_path: true)

        # Upload Audio to AWS
        if upload_audio(@upload_url, @file, @content_type).status == 200

          # Create Production with Podigee
          production_url = create_production(@file_url, @id)
          if production_url.status == 200
            @content_type = @episode.audio.content_type
            @file_url = JSON.parse(production_url.body)['file_url']
          end
        end
      end
    end

    # Start Procution with Podigee an redirect if successful
    respond_to do |format|
      if encode_audio(@id).status == 200
        format.html { redirect_to @episode, notice: 'Episode was successfully created.' }
        format.json { render :show, status: :created, location: @episode }
      else
        format.html { render :new }
        format.json { render json: @episode.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def episode_params
    params.require(:episode).permit(:title, :subtitle, :description, :cover_image, :shownotes, :audio)
  end

    def create_an_episode(title)
    Excon.post(
      "https://app.podigee.com/api/v1/episodes",
      body: {
        title: title,
        podcast_id: 37847
      }.to_json,
      headers: {
        'Token' => ENV.fetch('TOKEN'),
        'Content-Type' => 'application/json'
      }
    )
  end

  def generate_upload_url
    Excon.post(
      "https://app.podigee.com/api/v1/uploads?filename=episode001.flac",
      headers: {
        'Token' => ENV.fetch('TOKEN'),
        'Content-Type' => 'application/json'
      }
    )
  end

  def upload_audio(upload_url, file, content_type)
    boundary = "AaB03x"
    uri = URI.parse(upload_url)
    post_body = []
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"#{File.basename(file)}\"\r\n"
    post_body << "Content-Type: text/plain\r\n"
    post_body << "\r\n"
    post_body << File.read(file)
    post_body << "\r\n--#{boundary}--\r\n"

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = post_body.join
    request["Content-Type"] = "#{content_type}, boundary=#{boundary}"

    http.request(request)
  end

  def create_production(file_url, id)
    Excon.post(
      "https://app.podigee.com/api/v1/productions",
      headers: {
        'Token' => ENV.fetch('TOKEN'),
        'Content-Type' => 'application/json',
      },
      body: {
        episode_id: id,
        files: [{ "url" => file_url }]
      }.to_json
    )
  end

  def encode_audio(id)
    Excon.put(
      "https://app.podigee.com/api/v1/productions/#{id}",
      headers: {
        'Token' => ENV.fetch('TOKEN'),
        'Content-Type' => 'application/json'
      },
      body: {
        state: "encoding"
      }.to_json
    )
  end
end
