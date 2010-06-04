require 'uri'
require 'cgi'

module Paracode
module Media


  
  class Link
    attr_accessor :html
    
  protected
    def self.url_escape(url)
      CGI::escape(url)
    end
  end

  

  class Text < Link
    def initialize url
      @html = html_escape(url)
    end

  private 
    def html_escape(s)
      s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
    end
  end



  class Href < Link
    def initialize url
      @html ="<a href=\"#{url}\" target=\"_new\">#{url}</a>"
    end
  end



  class Youtube < Link
    YT_EMB = <<EOF
   <object width="120" height="120" type="application/x-shockwave-flash" id="myytplayer" data="http://www.youtube.com/v/%s?video_id=%s&amp;version=3&amp;enablejsapi=1&amp;playerapiid=ytplayer"><param name="allowScriptAccess" value="always"><param name="bgcolor" value="#cccccc"><param name="allowfullscreen" value="true"></object>
EOF

    def initialize url
      if url =~ /[&\?\/]*v[=\/]([^&^\/^\?]*)[&\/?]*/
        @html = YT_EMB % [$1,$1] 
      else
        @html = Href.new(url).html
      end
    end
  end



  class Flickr < Link
    module Base58
      def self.encode(n)
        alphabet = %w(
          1 2 3 4 5 6 7 8 9
          a b c d e f g h i
          j k m n o p q r s
          t u v w x y z A B
          C D E F G H J K L
          M N P Q R S T U V
          W X Y Z
        )

        return alphabet[0] if n == 0

        result = ''
        base = alphabet.length

        while n > 0
          remainder = n % base
          n = n / base
          result = alphabet[remainder] + result
        end
        result
      end
    end

    def initialize(url)
      if( url =~ /http:\/\/www.flickr.com\/photos\/.*?\/([^\/]*)[\/]*/)    #extract&match photoid
        src = "http://flic.kr/p/img/%s_s.jpg" % Base58::encode($1.to_i)
        @html ="<a href=\"#{url}\" target=\"_new\"><img src=\"#{src}\"/></a>"
      else
        @html = Href.new(url).html
      end
    end
  end



  class Google < Link
    G_HTML = <<EOF
<a href="http://google.com?q=%s">%s</a>
EOF
    def initialize url
      @html = G_HTML % [url, url]
    end
  end



  module Linkage
    @@map = {
              'youtube.com' => Youtube, 'www.youtube.com' => Youtube,
             'flickr.com' => Flickr ,'www.flickr.com' => Flickr
            }

    def self.create(url, opts={})
      if(url? url)
        host = extract_host url

        url = url.gsub('javascript','') #naive safety
        
        if(@@map.has_key? host)
          @@map[host].new url
        else
          Href.new url
        end
      else
        klass = opts[:google] ? Google : Text
        klass.new url
      end
    end

  private
    def self.url? url
      url =~ /^http:\/\/.*?\.com/
    end

    def self.extract_host url
      URI.parse(url).host
    end
  end
end
end




