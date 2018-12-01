require 'faraday'
require 'nokogiri'
require 'date'

def parse(link)
  link << '&affiliate_id=zdo2c683olan'
  response = Faraday.get link
  @xml_doc = Nokogiri::XML(response.body)
end

puts 'Hola! Benvenido a El Tiempo'

def ask_city
  puts 'Que municipio quieres?'
  print '> '
  @city = gets.chomp
  valid?(@city)
  tasks
end

def valid?(city)
  # see if city is correct
  unless cities_links.include? city
    puts 'Por favor inserte un municipio existente'
    ask_city
  end
end

def tasks
  puts '¿Que quieres saber? [introducir 1-4]'
  puts '1. ¿El promedio de las temperaturas mínimas de esta semana?'
  puts '2. ¿El promedio de las temperaturas máximas de esta semana?'
  puts '3. ¿La temperatura de hoy?'
  puts '4. Cambiar el municipio'
  puts '5. ¿salir?'
  print '> '
  answer = gets.chomp.to_i
  puts actions(answer)
  tasks
end

def actions(answer)
  if answer == 1
    @avg = 4
    average(temperatures, 'min')
  elsif answer == 2
    @avg = 5
    average(temperatures, 'max')
  elsif answer == 3
    @values = { min: 4, max: 5 }
    temperature
  elsif answer == 4
    ask_city
  elsif answer == 5
    puts 'Adiós'
    exit
  else
    puts 'Por favor inserte una opción correcta [1-4]'
    tasks
  end
end

def day_adjusted
  #the days in the API start as Saturday = 1 and Date.today starts as monday = 1
  day = Date.today.cwday.to_i
  if (1..5).to_a.include? day
    day + 2
  else
    day - 5
  end
end

def cities_links
  # all the links to the cities's details
  cities = {}
  parse('http://api.tiempo.com/index.php?api_lang=es&division=102')
  @xml_doc.xpath('//data').each do |path|
    cities[path.xpath('name').text] = path.xpath('url').text << '&affiliate_id=zdo2c683olan'
  end
  cities
end

def temperatures
  # array of temperatures (min or max)
  parse(cities_links[@city])
  temperatures = []
  @xml_doc.xpath("//var[icon=#{@avg}]/data/forecast").each do |forecast|
    temperatures << forecast.xpath('@value').text.to_i
  end
  temperatures
end

def temperature
  # data about today's temperature (min and max)
  temp_info = {}
  parse(cities_links[@city])
  temp_info[:min_temp] = @xml_doc.xpath("//var[icon=#{@values[:min]}]/data/forecast[@data_sequence = '#{day_adjusted}']/@value").text.to_i
  temp_info[:max_temp] = @xml_doc.xpath("//var[icon=#{@values[:max]}]/data/forecast[@data_sequence = '#{day_adjusted}']/@value").text.to_i
  "Hoy, la temperatura mínima es #{temp_info[:min_temp]}C y la temperatura máxima es #{temp_info[:max_temp]}C"
end

def average(temp, kind)
  # average of array of temperatures (min or max)
  avg = (temp.inject(0) { |sum, x| sum + x }.to_f / temp.count).round(2)
  "El promedio #{kind} es: #{avg}C"
end

ask_city
