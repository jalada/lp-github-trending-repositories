require 'bundler'
Bundler.require

require 'sinatra/reloader' if settings.development?
$stdout.sync = true if settings.development?

set :haml, format: :html5
trending_page = "https://github.com/trending"

# Prepares and returns this edition of the publication
# == Returns:
# HTML/CSS edition with etag. This publication changes the greeting depending
# on the time of day. It is using UTC to determine the greeting.
get '/edition/?' do

  response = Typhoeus::Request.get trending_page
  if response.success?
    html = response.body
  else
    raise "Failed to get trending page"
  end

  page = Nokogiri::HTML.parse(html)

  block = page.at_css("li.leaderboard-list-item")
  owner_and_repo = block.at_css("a.repository-name").text.split("/")

  @owner = owner_and_repo.first
  @repository = owner_and_repo.last

  client = Octokit::Client.new access_token: ENV["TOKEN"]

  repo = client.repo("#{@owner}/#{@repository}")

  @stars = repo.watchers
  @forks = repo.forks_count
  @description = block.at_css("p.repo-leaderboard-description").text rescue ""
  @description = @description.match(/[.!]$/) ? @description : @description + "."
  @language = block.at_css("span.title-meta").text rescue nil

  etag Digest::MD5.hexdigest(settings.development? ? Time.now.to_s : "#{@owner}/#{@repo}")
  haml :trending_repository
end


# Returns a sample of the publication. Triggered by the user hitting 'print sample' on you publication's page on BERG Cloud.
#
# == Parameters:
#   None.
#
# == Returns:
# HTML/CSS edition with etag. This publication changes the greeting depending on the time of day. It is using UTC to determine the greeting.
#
get '/sample/?' do

  @owner = "mozilla"
  @repository = "brick"
  @stars = 308
  @forks = 42
  @description = "UI Web Components for Mobile Web Apps."
  @language = "JavaScript"

  haml :trending_repository
end

get '/application.css' do
  sass :style
end
