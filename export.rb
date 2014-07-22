require 'rubygems'
require 'httparty'

# Configuration
username     = ARGV[0] || ENV["DRIBBBLE_USERNAME"]
image_dir    = ARGV[1] || "images"
limit        = 20  # number of shots requested each time
download_num = 200 # number of shots to download

class DribbbleLikesExport

  attr_accessor :username, :image_dir, :limit, :download_num, :url

  def initialize(username, image_dir, limit, download_num)

    @username     = username
    @image_dir    = image_dir
    @limit        = limit
    @download_num = download_num

    @url          = "http://api.dribbble.com/players/#{@username}/shots/likes"

    create_download_dir

  end

  def create_download_dir

    Dir.mkdir("./#{@image_dir}") unless File.directory?("./#{@image_dir}")

  end

  def get_liked_count

    response        = HTTParty.get(@url + "&per_page=1&page=0")
    parsed_response = JSON.parse(response.body)

    return parsed_response['total']

  end

  def get_photos(limit = 0, offset = 0)

    response        = HTTParty.get(@url + "?per_page=#{limit}&page=#{offset}")
    parsed_response = JSON.parse(response.body)

    download_likes(parsed_response['shots'])

    return true

  end

  def download_likes(likes)

    likes.each do |like|

      puts "\033[37m#{like['title']}\033[0m" 

      begin

        uri = like['image_url']
        file = File.basename(uri)

        File.open("./#{@image_dir}/" + file, "wb") do |f| 
          puts "   #{uri}"
          f.write HTTParty.get(uri).parsed_response
        end

      rescue => e
        puts ":( #{e}"
      end

    end

  end

  def download

    # uncomment next line to download all your liked images
    # download_num = get_liked_count

    parsed = 0

    rest = @download_num % @limit

    if rest > 1
      rest = 1
    end

    batchs = (@download_num / @limit) + rest

    if (@download_num < @limit)
      batchs = 1
      @limit  = @download_num
    end

    puts "Downloading \033[32m#{@download_num}\033[0m shots"

    batchs.times do |i|

      offset = i*@limit

      if parsed + @limit > @download_num
        @limit = @download_num - parsed
      end

      result = get_photos(@limit, offset)
      parsed += @limit
      break if !result

    end

    puts "\033[32m#{"Aaaaand we're done, parsed #{parsed} "}\033[0m"

  end

end

dribbble = DribbbleLikesExport.new(username, image_dir, limit, download_num)
dribbble.download
