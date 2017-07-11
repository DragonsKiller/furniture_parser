class NemanParser
  attr_accessor :root_url, :array_urls_collection

  def initialize(root_url, array_urls_collection)
    @root_url = root_url
    @array_urls_collection = array_urls_collection
    @products = []
    @names = []
    @codes = []
    @sizes = []
    @costs = []
    @collections = []
    @types = []
    @images_names = []
  end

  def parse
    @array_urls_collection.each do |url|
      page = Nokogiri::HTML(open(url)).xpath('//div[@class="margin-minus"]/a[@class="prod prod_small"]').map { |link| link['href']}
      page.each do |link|
        name_parse(link)
        type_collection_parse(link)
        code_parse(link)
        size_parse(link)
        cost_parse(link)
        image = Nokogiri::HTML(open(@root_url+link)).xpath("//div[@class='prod-wrapper']/a/span/span").xpath('//div[@class="prod-wrapper"]/a/span/span/span/img/@src').each do |src|
          uri_cheker(src)
        end
      end
    end
    convert_to_hash
    csv_save
  end

  def name_parse(link)
    Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="prod-wrapper"]/a/span[@class="prod__title"]').each do |name|
      name = name.to_s.gsub!(/<span class="prod__title">/, '').gsub!(/<\/span>/, '')
      @names.push(name)
    end
  end

  def type_collection_parse(link)
    Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="prod-wrapper"]').each do
      type = Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="wrapper_b"]/div/a')[2].to_s.gsub!(/.*">/, '').gsub!(/<\/a>/,'')
      @types.push(type)

      collection = Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="wrapper_b"]/h1').to_s.gsub!(/<h1>/, '').gsub!(/<\/h1>/, '')
      @collections.push(collection)
    end
  end

  def code_parse(link)
    Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="prod-wrapper"]/a/span[@class="dotted"]').each do |code|
      code = code.to_s.gsub!(/<span class="dotted">/, '').gsub!(/<\/span>/, '')
      @codes.push(code)
    end
  end

  def size_parse(link)
    Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="prod-wrapper"]/a/span[@class="prod-2__desc"]').each do |size|
      size = size.to_s.gsub!(/(.*br>)?(.*:)?(.*">)?(ниша под ТВ )?(\r\n)*(<b>)?(Место под ТВ )?/, '').gsub!(/ см.*/, '')
      if !size.nil?
        @sizes.push(size + " см")
      else
        @sizes.push('')
      end
    end
  end

  def cost_parse(link)
    Nokogiri::HTML(open(@root_url+link)).xpath('//div[@class="prod-wrapper"]/a/span[@class="prod-2__desc cost"]').each do |cost|
      cost = cost.to_s.gsub!(/<span class="prod-2__desc cost">(\r\n\t)?(\s)*/, '').gsub!(/бел.руб.*/, '')
      @costs.push(cost)
    end
  end

  def uri_cheker(src)
    if !src.to_s.gsub(/\p{Cyrillic}/, '').nil?
      uri_normalizer(src)
    else
      uri = URI.join(@root_url+link, src ).to_s
      saver(uri)
    end
  end

  def uri_normalizer(src)
    src = Addressable::URI.parse(src.to_s)
    src = src.normalize
    uri = @root_url + src.to_s
    save_image(uri)
  end

  def save_image(uri)
    image_name = File.basename(uri)
    @images_names.push(image_name)
    File.open(File.join("../images/", File.basename(uri)),'wb'){ |f| f.write(open(uri).read) }
  end

  def convert_to_hash
    (0..@names.length-1).each do |iterator|
      @products.push({'image' => @images_names[iterator],
        'name' => 'code: ' + @codes[iterator] + ' name: ' + @names[iterator],
        'collection' => @collections[iterator], 'type' => @types[iterator],
        "cost" => @costs[iterator], "size" => @sizes[iterator]})
    end
  end

  def csv_save
    CSV.open("../mebel-neman.csv", "wb") do |csv|
      csv << @products
    end
  end
end
