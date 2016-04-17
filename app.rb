require 'sinatra'
require 'sinatra/reloader'
require "sinatra/json"
require 'nokogiri'
require 'syobocal'
require 'pp'
def format_time(time)
  h = time.hour
  h += 24 if h < 5
  m = time.min

  sprintf("%2d:%02d", h, m)
end
  url = "http://www.tsubuani.com/anime"
  anime_list = {}
  anime_tag = {}
  anime_ch = {}
  anime_start = {}
  anime_end = {}


  doc = Nokogiri::HTML(open(url))
  doc.xpath('//tbody/tr').each do |node|
    title = node.css('td/a').inner_text.strip
    hashtag = node.css('.hasttag_cell').inner_text.strip
    # p title
    # p hashtag
    anime_list[title] = hashtag
  end
  # get '/' do
  #   anime_list.to_json
  # end
  #
  params = {"days" => "1"}
  result = Syobocal::CalChk.get(params)
  # get '/' do
  #   result.to_json
  # end
  # 首都圏のチャンネルで放送されるアニメ
  # 現在から

  st = Time.now

  # 次の朝5時まで
  day = st.hour < 5 ? Date.today : Date.today + 1
  ed = Time.new(day.year, day.month, day.day, 5)
  syutoken_ch = [
    1, # NHK総合
    2, # NHK Eテレ
    3, # フジテレビ
    4, # 日本テレビ
    5, # TBS
    6, # テレビ朝日
    7, # テレビ東京
    8, # TVK
    13, # チバテレビ
    14, # テレ玉
    19, # TOKYO MX
  ]
  result.select{|prog|
    # st <= prog[:ed_time] and st >= prog[:st_time] and syutoken_ch.include?(prog[:ch_id])
    st < prog[:ed_time] and prog[:ed_time] < ed and syutoken_ch.include?(prog[:ch_id])
  }.sort_by{|prog|
    prog[:st_time] # 放送開始日時で降順に並べ替え
  }.each{|prog|
    # puts "#{format_time(prog[:st_time])}-#{format_time(prog[:ed_time])} [#{prog[:ch_name]}] #{prog[:title]}"
    # puts anime_list[prog[:title]]
    if anime_list[prog[:title]] != nil
      anime_tag[prog[:title]] = anime_list[prog[:title]]
    else
      anime_tag[prog[:title]] = ""
    end
    anime_ch[prog[:title]] = prog[:ch_name]
    anime_start[prog[:title]] = format_time(prog[:st_time])
    anime_end[prog[:title]] = format_time(prog[:ed_time])
  }
  get '/' do
    # @text = st.strftime("現在日時 %B,%d(%A) %Y %H時 %M分 %S秒 %Z")
    anime_tag.to_json + "," + anime_ch.to_json + "," + anime_start.to_json + "," + anime_end.to_json
  end
