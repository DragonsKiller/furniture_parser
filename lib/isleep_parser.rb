class IsleepParser
  attr_accessor :url_collections, :pages_url

  def initialize(url_collections, pages_url)
    @url_collections = url_collections
    @pages_url = pages_url
    @names = []
    @images_names = []
    @sizes = []
    @costs = []
    @pages = []
    @info = []
    @info_names = []
    @info_values = []
    @hash = []
    @descriptions = []
    @products = []
  end

  def parse
    (1..get_count_pages).each do |current_page|
      get_pages(current_page.to_s)
      name_parse(current_page.to_s)
      size_parse(current_page.to_s)
      cost_parse(current_page.to_s)
      Nokogiri::HTML(open(@pages_url+current_page.to_s)).xpath("//div[@class='row products_category']/div/div/div/a/img/@src").each do |src|
        save_image(current_page, src)
      end
    end
    info_parse
    convert_to_hash
    csv_save
  end

  def name_parse(current_page)
    Nokogiri::HTML(open(@pages_url+current_page)).xpath("//div[@class='caption product-info clearfix']/h4/a/span").each do |name|
      name = name.to_s.gsub!(/<span itemprop="name">/, '').gsub!(/<\/span>/, '')
      @names.push(name)
    end
  end

  def size_parse(current_page)
    Nokogiri::HTML(open(@pages_url+current_page)).xpath("//div[@class='caption product-info clearfix']/div/div/div/div/select/option").each do |size|
      size = size.to_s.gsub!(/<option value="(\d)*">/, '').gsub!(/(\s)*<\/option>/, '')
      @sizes.push(size)
    end
  end

  def cost_parse(current_page)
    Nokogiri::HTML(open(@pages_url+current_page)).xpath("//div[@class='price']/meta[@itemprop='price']").each do |cost|
      cost = cost.to_s.gsub!(/<meta itemprop="price" content="/, '').gsub(/.0000/, '').gsub!(/">/, '')
      @costs.push(cost)
    end
  end


  def get_pages(current_page)
    links = Nokogiri::HTML(open(@pages_url+current_page)).xpath("//div[@class='caption product-info clearfix']/h4/a").map { |link| link['href'] }
    links.each do |link|
      @pages.push(link)
    end
  end

  def get_count_pages
    Nokogiri::HTML(open(@url_collections)).xpath('//div[@class="row"]/div/div/div/div[@class="col-sm-6 text-right"]').to_s.gsub!(/<div class="col-sm-6 text-right">Показано с.*всего /, '').gsub!(/ страниц.*/, '').to_i
  end

  def save_image(current_page, src)
    uri = URI.join(@pages_url+current_page.to_s, src ).to_s # make absolute uri
    @images_names.push(File.basename(uri))
    File.open(File.join("../images/", File.basename(uri)),'wb'){ |f| f.write(open(uri).read) }
  end

  def info_parse
    @pages.each do |link|
      get_description(link)
      make_hash(link)
      @info.push(@hash)
      clear_hash
    end
  end

  def get_description(link)
    begin
      @descriptions.push(Nokogiri::HTML(open(link)).xpath("//div[@id='tab-description']/p")[0].to_s.gsub!(/<p>/, '').gsub(/<strong>/, '').gsub(/<br>/, '').gsub(/<\/strong>/, '').gsub!(/<\/p>/, ''))
    rescue NoMethodError
      @descriptions.push('')
    end
  end

  def make_hash(link)
    get_info_names(link)
    get_info_values(link)
    set_hash
  end

  def clear_hash
    @hash = []
    @info_names = []
    @info_values = []
  end

  def set_hash
    (0..@info_names.length-1).each do |iterator|
      @hash.push({@info_names[iterator] => @info_values[iterator]})
    end
  end

  def get_info_names(link)
    Nokogiri::HTML(open(link)).xpath("//table[@class='table attrbutes mb0']/tbody/tr/td[@itemprop='value']").each do |information|
      information = information.to_s.gsub!(/<td itemprop="value">/, '').gsub!(/<\/td>/, '')
      @info_values.push(information)
    end
  end

  def get_info_values(link)
    Nokogiri::HTML(open(link)).xpath("//table[@class='table attrbutes mb0']/tbody/tr/td[@itemprop='name']").each do |information|
      information = information.to_s.gsub!(/<td itemprop="name">/, '').gsub!(/<\/td>/, '')
      @info_names.push(information)
    end
  end

  def convert_to_hash
    (0..@names.length-1).each do |iterator|
      @products.push({'image' => @images_names[iterator],
        'name' => @names[iterator], 'cost' => @costs[iterator],
        'description' => @descriptions[iterator], "size" => @sizes[iterator],
        'info' => @info[iterator]})
    end
  end

  def csv_save
    CSV.open("../isleep.csv", "wb") do |csv|
      csv << @products
    end
  end
end
