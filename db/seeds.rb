require 'json'
require 'open-uri'
require 'rubygems'
require 'excon'

Episode.destroy_all
puts "Deleted all entries"

def request_api(url)
    Excon.get(
      url,
      headers: {
        'Token' => ENV.fetch('TOKEN'),
        'Content-Type' => 'application/json'
      }
    )
end

# EPISODE
titles = []
links = []
cover_images = []
subtitles = []
descriptions = []
durations = []
published_ats = []
shownotes = []

url = 'https://app.podigee.com/api/v1/episodes'

response = request_api(url)

JSON.parse(response.body).each do |json|
  titles << json['title']
  links << json['permalink']
  cover_images << json['cover_image']
  subtitles << json['subtitle']
  descriptions << json['description']
  durations << json['duration']
  published_ats << json['published_at']
  shownotes << json['show_notes']
end

#  creating html for embed player
def embed_player(link)
  "<iframe src=\"#{link}/embed?context=external&theme=default\" style=\"border: 0\" border=\"0\" height=\"100\" width=\"100%\"></iframe>"
end

permalinks = []
links.each do |l|
  permalinks << embed_player(l)
end

episodes_hash = {}
titles_hash = {}
permalinks_hash = {}
cover_images_hash = {}
subtitles_hash = {}
descriptions_hash = {}
durations_hash = {}
published_ats_hash = {}
shownotes_hash = {}

titles.each_with_index do |t, i|
  episodes_hash["episode#{i}"] = Episode.new
  titles_hash["title#{i}"] = t
end

permalinks.each_with_index do |p, i|
  permalinks_hash["permalink#{i}"] = p
end

cover_images.each_with_index do |p, i|
  cover_images_hash["cover_image#{i}"] = p
end

subtitles.each_with_index do |p, i|
  subtitles_hash["subtitle#{i}"] = p
end

descriptions.each_with_index do |p, i|
  descriptions_hash["description#{i}"] = p
end

durations.each_with_index do |p, i|
  durations_hash["duration#{i}"] = p
end

published_ats.each_with_index do |p, i|
  published_ats_hash["published_at#{i}"] = p
end

shownotes.each_with_index do |s, i|
  shownotes_hash["shownote#{i}"] = s
end
episodes_hash.each_with_index do |(_k, v), i|
  v.title = titles_hash["title#{i}"]
  v.permalink = permalinks_hash["permalink#{i}"]
  v.cover_image = cover_images_hash["cover_image#{i}"]
  v.subtitle = subtitles_hash["subtitle#{i}"]
  v.description = descriptions_hash["description#{i}"]
  v.duration = durations_hash["duration#{i}"]
  v.published_at = published_ats_hash["published_at#{i}"]
  v.shownotes = shownotes_hash["shownote#{i}"]
  v.save!
end
puts "Created Episodes"
