class BrwParser
  attr_accessor :root_url, :collections_url

  def initialize(root_url, collections_url)
    @root_url = root_url
    @collections_url = collections_url
    @products = []
    @names = []
    @collections = []
    @costs = []
    @sizes = []
    @products_pages = []
    @codes = []
    @colors = []
    @descriptions = []
    @product_description = []
    @images_names = []
    @types = []
  end

  def parse
    collection_page = Nokogiri::HTML(open(@collections_url)).xpath('//div[@class="item col-lg-3 col-md-4 col-sm-4 col-xs-12"]/a').map { |link| link['href'] }
    pages_parse(collection_page)
    convert_to_hash
    csv_save
  end

  def pages_parse(collection_page)
    collection_page.each do |link|
      pages = Nokogiri::HTML(open(@root_url+link)).xpath("//div[@class='item col-lg-3 col-md-4 col-sm-4 col-xs-6']/div/div[@class='inner']")
      pages.xpath("//a[@class='cap black']").each do |page|
        page = page.to_s.gsub!(/<a href="/, '').gsub!(/" class.*/, '')
        @products_pages.push(page)
      end
      info_parse
      @products_pages = []
      main_info_parse(pages)
      parse_image(link)
    end
  end

  def main_info_parse(pages)
    name_parse(pages)
    collection_parse(pages)
    cost_parse(pages)
    size_parse(pages)
  end

  def name_parse(pages)
    pages.xpath("//a[@class='cap black']").each do |name|
      name = name.to_s.gsub!(/<a href=".*">/, '').gsub!(/ *<\/a>/, '')
      @names.push(name)
    end
  end

  def collection_parse(pages)
    pages.xpath("//span[@class='at']").each do |collection|
      collection = collection.to_s.gsub!(/<!--<a href="" style="color:#5f5f5f"><\/a>-->/, '').gsub!(/<span class="at">Коллекция <a.*\/">/, '').gsub!(/<\/a><\/span>/, '')
      @collections.push(collection)
    end
  end

  def cost_parse(pages)
    pages.xpath("//div/div/span[@class='cost']").each do |cost|
      cost = cost.to_s.gsub!(/<span class="cost">/, '').gsub!(/ руб.<\/span>/, '')
      @costs.push(cost)
    end
  end

  def size_parse(pages)
    pages.xpath("//span[@class='size']").each do |size|
      size = size.to_s.gsub!(/<span class="size">Размеры: /, '').gsub!(/<\/span>/, '')
      @sizes.push(size)
    end
  end

  def info_parse
    @products_pages.each do |page|
      begin
        type_parse(page)
        product_page = Nokogiri::HTML(open(@root_url+page)).xpath("//div[@class='infoBlock col-lg-7 col-md-7 col-sm-7']")
        code_parse(product_page)
        color_parse(product_page)
        description_parse(page)
      rescue OpenURI::HTTPError
        nul_info_push
      end
    end
  end

  def nul_info_push
    @types.push('')
    @codes.push('')
    @colors.push('')
    @descriptions.push('')
  end

  def type_parse(page)
    @types.push(Nokogiri::HTML(open(@root_url+page)).xpath("//div[@class='breadcrumbs']/div/ul/li")[2].to_s.gsub!(/.*">/, '').gsub!(/<\/.*>/, ''))
  end

  def code_parse(page)
    code = page.xpath("//span[@class='cod']").to_s.gsub!(/<span class="cod">Код: /, '').gsub!(/<\/span>/, '')
    @codes.push(code)
  end

  def color_parse(page)
    color = page.xpath("//div[@class='inlinePar cfix']/ul/li/a").to_s.gsub!(/<a class="fancybox" title="/, '').gsub!(/" href=".*/, '')
    @colors.push(color)
  end

  def description_parse(page)
    if(@root_url+page != 'https://www.brw.by/catalog/gostinaya/uglovye_elementy/shkaf_verkhniy_stilius_nnad_1wn/')
        Nokogiri::HTML(open(@root_url+page)).xpath("//div[@class='infoBlock col-lg-7 col-md-7 col-sm-12 pull-right-md']/div/ul/li").each do |description|
          description = description.to_s.gsub!(/(.*">)?(<li>)?/, '').gsub!(/<\/[s,d,f,l].*/, '')
          @product_description.push(description)
        end
        @descriptions.push(@product_description)
      else
        @descriptions.push(Nokogiri::HTML(open('https://www.brw.by/catalog/gostinaya/uglovye_elementy/shkaf_verkhniy_stilius_nnad_1wn/')).
        xpath("//div[@class='infoBlock col-lg-7 col-md-7 col-sm-12 pull-right-md']/div/blockquote/li/font").to_s.gsub!(/<font face="Arial" size="2">/, '').gsub!(/<\/font>/, ''))
      end
  end


  def parse_image(link)
    image = Nokogiri::HTML(open(@root_url+link)).xpath("//div[@class='image']/ul/li/@style").to_s.gsub!(/background-image: url\(/, '')
    save_image(image)
  end

  def save_image(image)
    if !image.nil?
      image = image.split(/\)/)
      image.each do |url|
        uri = @root_url+url
        image_name = File.basename(uri)
        @images_names.push(image_name)
        File.open(File.join("../images/", image_name),'wb'){ |f| f.write(open(uri).read) }
      end
    end
  end

  def convert_to_hash
    (0..@names.length-1).each do |iterator|
      @products.push({'image' => @images_names[iterator],
        'name' => 'code: ' + @codes[iterator] + ' name: ' + @names[iterator],
        'collection' => @collections[iterator], 'type' => @types[iterator], "cost" => @costs[iterator],
        'description' => @descriptions[iterator], "size" => @sizes[iterator],
        'color' => @colors[iterator]})
    end
  end

  def csv_save
    CSV.open("../brw.csv", "wb") do |csv|
      csv << @products
    end
  end
end
