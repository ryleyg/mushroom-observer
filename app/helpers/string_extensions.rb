if !defined? UTF_TO_ASCII
  # This should cover most everything we'll see, at least all the European
  # characters and accents -- it covers HTML codes &#1 to &#400.
  UTF8_TO_ASCII = {
    "\x00"         => ' ',
    "\x01"         => ' ',
    "\x02"         => ' ',
    "\x03"         => ' ',
    "\x04"         => ' ',
    "\x05"         => ' ',
    "\x06"         => ' ',
    "\x07"         => ' ',
    "\x08"         => ' ',
    "\x0B"         => ' ',
    "\x0C"         => ' ',
    "\x0E"         => ' ',
    "\x0F"         => ' ',
    "\x10"         => ' ',
    "\x11"         => ' ',
    "\x12"         => ' ',
    "\x13"         => ' ',
    "\x14"         => ' ',
    "\x15"         => ' ',
    "\x16"         => ' ',
    "\x17"         => ' ',
    "\x18"         => ' ',
    "\x19"         => ' ',
    "\x1A"         => ' ',
    "\x1B"         => ' ',
    "\x1C"         => ' ',
    "\x1D"         => ' ',
    "\x1E"         => ' ',
    "\x1F"         => ' ',
    "\xE2\x82\xAC" => '$',    # €
    "\xEF\xBF\xBD" => '?',    # �
    "\xE2\x80\x9A" => ',',    # ‚
    "\xC6\x92"     => 'f',    # ƒ
    "\xE2\x80\x9E" => '"',    # „
    "\xE2\x80\xA6" => '...',  # …
    "\xE2\x80\xA0" => '+',    # †
    "\xE2\x80\xA1" => '++',   # ‡
    "\xCB\x86"     => '^',    # ˆ
    "\xE2\x80\xB0" => '%',    # ‰
    "\xC5\xA0"     => 'S',    # Š
    "\xE2\x80\xB9" => '<',    # ‹
    "\xC5\x92"     => 'OE',   # Œ
    "\xEF\xBF\xBD" => '?',    # �
    "\xC5\xBD"     => 'Z',    # Ž
    "\xEF\xBF\xBD" => '?',    # �
    "\xEF\xBF\xBD" => '?',    # �
    "\xE2\x80\x98" => "'",    # ‘
    "\xE2\x80\x99" => "'",    # ’
    "\xE2\x80\x9C" => '"',    # “
    "\xE2\x80\x9D" => '"',    # ”
    "\xE2\x80\xA2" => '.',    # •
    "\xE2\x80\x93" => '-',    # –
    "\xE2\x80\x94" => '-',    # —
    "\xCB\x9C"     => '~',    # ˜
    "\xE2\x84\xA2" => '(TM)', # ™
    "\xC5\xA1"     => 'S',    # š
    "\xE2\x80\xBA" => '>',    # ›
    "\xC5\x93"     => 'oe',   # œ
    "\xEF\xBF\xBD" => '?',    # �
    "\xC5\xBE"     => 'Z',    # ž
    "\xC5\xB8"     => 'Y',    # Ÿ
    "\xC2\xA1"     => '!',    # ¡
    "\xC2\xA2"     => '$',    # ¢
    "\xC2\xA3"     => '$',    # £
    "\xC2\xA4"     => '$',    # ¤
    "\xC2\xA5"     => '$',    # ¥
    "\xC2\xA6"     => '|',    # ¦
    "\xC2\xA7"     => '?',    # §
    "\xC2\xA8"     => '?',    # ¨
    "\xC2\xA9"     => '(C)',  # ©
    "\xC2\xAA"     => 'a',    # ª
    "\xC2\xAB"     => '<<',   # «
    "\xC2\xAC"     => '-',    # ¬
    "\xC2\xAD"     => '-',    # ­
    "\xC2\xAE"     => '(R)',  # ®
    "\xC2\xAF"     => '-',    # ¯
    "\xC2\xB0"     => '(o)',  # °
    "\xC2\xB1"     => '+/-',  # ±
    "\xC2\xB2"     => '(2)',  # ²
    "\xC2\xB3"     => '(3)',  # ³
    "\xC2\xB4"     => "'",    # ´
    "\xC2\xB5"     => 'u',    # µ
    "\xC2\xB6"     => '?',    # ¶
    "\xC2\xB7"     => '.',    # ·
    "\xC2\xB8"     => '.',    # ¸
    "\xC2\xB9"     => '(1)',  # ¹
    "\xC2\xBA"     => '(0)',  # º
    "\xC2\xBB"     => '>>',   # »
    "\xC2\xBC"     => '1/4',  # ¼
    "\xC2\xBD"     => '1/2',  # ½
    "\xC2\xBE"     => '3/4',  # ¾
    "\xC2\xBF"     => '?',    # ¿
    "\xC3\x80"     => 'A',    # À
    "\xC3\x81"     => 'A',    # Á
    "\xC3\x82"     => 'A',    # Â
    "\xC3\x83"     => 'A',    # Ã
    "\xC3\x84"     => 'A',    # Ä
    "\xC3\x85"     => 'A',    # Å
    "\xC3\x86"     => 'AE',   # Æ
    "\xC3\x87"     => 'C',    # Ç
    "\xC3\x88"     => 'E',    # È
    "\xC3\x89"     => 'E',    # É
    "\xC3\x8A"     => 'E',    # Ê
    "\xC3\x8B"     => 'E',    # Ë
    "\xC3\x8C"     => 'I',    # Ì
    "\xC3\x8D"     => 'I',    # Í
    "\xC3\x8E"     => 'I',    # Î
    "\xC3\x8F"     => 'I',    # Ï
    "\xC3\x90"     => 'D',    # Ð
    "\xC3\x91"     => 'N',    # Ñ
    "\xC3\x92"     => 'O',    # Ò
    "\xC3\x93"     => 'O',    # Ó
    "\xC3\x94"     => 'O',    # Ô
    "\xC3\x95"     => 'O',    # Õ
    "\xC3\x96"     => 'O',    # Ö
    "\xC3\x97"     => ' x ',  # ×
    "\xC3\x98"     => 'O',    # Ø
    "\xC3\x99"     => 'U',    # Ù
    "\xC3\x9A"     => 'U',    # Ú
    "\xC3\x9B"     => 'U',    # Û
    "\xC3\x9C"     => 'U',    # Ü
    "\xC3\x9D"     => 'Y',    # Ý
    "\xC3\x9E"     => 'P',    # Þ
    "\xC3\x9F"     => 'ss',   # ß
    "\xC3\xA0"     => 'a',    # à
    "\xC3\xA1"     => 'a',    # á
    "\xC3\xA2"     => 'a',    # â
    "\xC3\xA3"     => 'a',    # ã
    "\xC3\xA4"     => 'a',    # ä
    "\xC3\xA5"     => 'a',    # å
    "\xC3\xA6"     => 'ae',   # æ
    "\xC3\xA7"     => 'c',    # ç
    "\xC3\xA8"     => 'e',    # è
    "\xC3\xA9"     => 'e',    # é
    "\xC3\xAA"     => 'e',    # ê
    "\xC3\xAB"     => 'e',    # ë
    "\xC3\xAC"     => 'i',    # ì
    "\xC3\xAD"     => 'i',    # í
    "\xC3\xAE"     => 'i',    # î
    "\xC3\xAF"     => 'i',    # ï
    "\xC3\xB0"     => 'o',    # ð
    "\xC3\xB1"     => 'n',    # ñ
    "\xC3\xB2"     => 'o',    # ò
    "\xC3\xB3"     => 'o',    # ó
    "\xC3\xB4"     => 'o',    # ô
    "\xC3\xB5"     => 'o',    # õ
    "\xC3\xB6"     => 'o',    # ö
    "\xC3\xB7"     => '/',    # ÷
    "\xC3\xB8"     => 'o',    # ø
    "\xC3\xB9"     => 'u',    # ù
    "\xC3\xBA"     => 'u',    # ú
    "\xC3\xBB"     => 'u',    # û
    "\xC3\xBC"     => 'u',    # ü
    "\xC3\xBD"     => 'y',    # ý
    "\xC3\xBE"     => 'p',    # þ
    "\xC3\xBF"     => 'y',    # ÿ
    "\xC4\x3F"     => 'c',    # č (where did this come from??)
    "\xC4\x80"     => 'A',    # Ā
    "\xC4\x81"     => 'a',    # ā
    "\xC4\x82"     => 'A',    # Ă
    "\xC4\x83"     => 'a',    # ă
    "\xC4\x84"     => 'A',    # Ą
    "\xC4\x85"     => 'a',    # ą
    "\xC4\x86"     => 'C',    # Ć
    "\xC4\x87"     => 'c',    # ć
    "\xC4\x88"     => 'C',    # Ĉ
    "\xC4\x89"     => 'c',    # ĉ
    "\xC4\x8A"     => 'C',    # Ċ
    "\xC4\x8B"     => 'c',    # ċ
    "\xC4\x8C"     => 'C',    # Č
    "\xC4\x8D"     => 'c',    # č
    "\xC4\x8E"     => 'D',    # Ď
    "\xC4\x8F"     => 'd',    # ď
    "\xC4\x90"     => 'D',    # Đ
    "\xC4\x91"     => 'd',    # đ
    "\xC4\x92"     => 'E',    # Ē
    "\xC4\x93"     => 'e',    # ē
    "\xC4\x94"     => 'E',    # Ĕ
    "\xC4\x95"     => 'e',    # ĕ
    "\xC4\x96"     => 'E',    # Ė
    "\xC4\x97"     => 'e',    # ė
    "\xC4\x98"     => 'E',    # Ę
    "\xC4\x99"     => 'e',    # ę
    "\xC4\x9A"     => 'E',    # Ě
    "\xC4\x9B"     => 'e',    # ě
    "\xC4\x9C"     => 'G',    # Ĝ
    "\xC4\x9D"     => 'g',    # ĝ
    "\xC4\x9E"     => 'G',    # Ğ
    "\xC4\x9F"     => 'g',    # ğ
    "\xC4\xA0"     => 'G',    # Ġ
    "\xC4\xA1"     => 'g',    # ġ
    "\xC4\xA2"     => 'G',    # Ģ
    "\xC4\xA3"     => 'g',    # ģ
    "\xC4\xA4"     => 'H',    # Ĥ
    "\xC4\xA5"     => 'h',    # ĥ
    "\xC4\xA6"     => 'H',    # Ħ
    "\xC4\xA7"     => 'h',    # ħ
    "\xC4\xA8"     => 'I',    # Ĩ
    "\xC4\xA9"     => 'i',    # ĩ
    "\xC4\xAA"     => 'I',    # Ī
    "\xC4\xAB"     => 'i',    # ī
    "\xC4\xAC"     => 'I',    # Ĭ
    "\xC4\xAD"     => 'i',    # ĭ
    "\xC4\xAE"     => 'I',    # Į
    "\xC4\xAF"     => 'i',    # į
    "\xC4\xB0"     => 'I',    # İ
    "\xC4\xB1"     => 'i',    # ı
    "\xC4\xB2"     => 'IJ',   # Ĳ
    "\xC4\xB3"     => 'ij',   # ĳ
    "\xC4\xB4"     => 'J',    # Ĵ
    "\xC4\xB5"     => 'j',    # ĵ
    "\xC4\xB6"     => 'K',    # Ķ
    "\xC4\xB7"     => 'k',    # ķ
    "\xC4\xB8"     => 'k',    # ĸ
    "\xC4\xB9"     => 'L',    # Ĺ
    "\xC4\xBA"     => 'l',    # ĺ
    "\xC4\xBB"     => 'L',    # Ļ
    "\xC4\xBC"     => 'l',    # ļ
    "\xC4\xBD"     => 'L',    # Ľ
    "\xC4\xBE"     => 'l',    # ľ
    "\xC4\xBF"     => 'L',    # Ŀ
    "\xC5\x80"     => 'l',    # ŀ
    "\xC5\x81"     => 'L',    # Ł
    "\xC5\x82"     => 'l',    # ł
    "\xC5\x83"     => 'N',    # Ń
    "\xC5\x84"     => 'n',    # ń
    "\xC5\x85"     => 'N',    # Ņ
    "\xC5\x86"     => 'n',    # ņ
    "\xC5\x87"     => 'N',    # Ň
    "\xC5\x88"     => 'n',    # ň
    "\xC5\x89"     => 'n',    # ŉ
    "\xC5\x8A"     => 'N',    # Ŋ
    "\xC5\x8B"     => 'n',    # ŋ
    "\xC5\x8C"     => 'O',    # Ō
    "\xC5\x8D"     => 'o',    # ō
    "\xC5\x8E"     => 'O',    # Ŏ
    "\xC5\x8F"     => 'o',    # ŏ
    "\xC5\x90"     => 'O',    # Ő
    "\xC5\x91"     => 'o',    # ő
    "\xC5\x92"     => 'OE',   # Œ
    "\xC5\x93"     => 'oe',   # œ
    "\xC5\x94"     => 'R',    # Ŕ
    "\xC5\x95"     => 'r',    # ŕ
    "\xC5\x96"     => 'R',    # Ŗ
    "\xC5\x97"     => 'r',    # ŗ
    "\xC5\x98"     => 'R',    # Ř
    "\xC5\x99"     => 'r',    # ř
    "\xC5\x9A"     => 'S',    # Ś
    "\xC5\x9B"     => 's',    # ś
    "\xC5\x9C"     => 'S',    # Ŝ
    "\xC5\x9D"     => 's',    # ŝ
    "\xC5\x9E"     => 'S',    # Ş
    "\xC5\x9F"     => 's',    # ş
    "\xC5\xA0"     => 'S',    # Š
    "\xC5\xA1"     => 's',    # š
    "\xC5\xA2"     => 'T',    # Ţ
    "\xC5\xA3"     => 't',    # ţ
    "\xC5\xA4"     => 'T',    # Ť
    "\xC5\xA5"     => 't',    # ť
    "\xC5\xA6"     => 'T',    # Ŧ
    "\xC5\xA7"     => 't',    # ŧ
    "\xC5\xA8"     => 'U',    # Ũ
    "\xC5\xA9"     => 'u',    # ũ
    "\xC5\xAA"     => 'U',    # Ū
    "\xC5\xAB"     => 'u',    # ū
    "\xC5\xAC"     => 'U',    # Ŭ
    "\xC5\xAD"     => 'u',    # ŭ
    "\xC5\xAE"     => 'U',    # Ů
    "\xC5\xAF"     => 'u',    # ů
    "\xC5\xB0"     => 'U',    # Ű
    "\xC5\xB1"     => 'u',    # ű
    "\xC5\xB2"     => 'U',    # Ų
    "\xC5\xB3"     => 'u',    # ų
    "\xC5\xB4"     => 'W',    # Ŵ
    "\xC5\xB5"     => 'w',    # ŵ
    "\xC5\xB6"     => 'Y',    # Ŷ
    "\xC5\xB7"     => 'y',    # ŷ
    "\xC5\xB8"     => 'Y',    # Ÿ
    "\xC5\xB9"     => 'Z',    # Ź
    "\xC5\xBA"     => 'z',    # ź
    "\xC5\xBB"     => 'Z',    # Ż
    "\xC5\xBC"     => 'z',    # ż
    "\xC5\xBD"     => 'Z',    # Ž
    "\xC5\xBE"     => 'z',    # ž
    "\xC5\xBF"     => 'f',    # ſ
    "\xC6\x80"     => 'b',    # ƀ
    "\xC6\x81"     => 'B',    # Ɓ
    "\xC6\x82"     => 'B',    # Ƃ
    "\xC6\x83"     => 'b',    # ƃ
    "\xC6\x84"     => 'b',    # Ƅ
    "\xC6\x85"     => 'b',    # ƅ
    "\xC6\x86"     => 'C',    # Ɔ
    "\xC6\x87"     => 'C',    # Ƈ
    "\xC6\x88"     => 'c',    # ƈ
    "\xC6\x89"     => 'D',    # Ɖ
    "\xC6\x8A"     => 'D',    # Ɗ
    "\xC6\x8B"     => 'D',    # Ƌ
    "\xC6\x8C"     => 'd',    # ƌ
    "\xC6\x8D"     => 'g',    # ƍ
    "\xC6\x8E"     => 'E',    # Ǝ
    "\xC6\x8F"     => 'e',    # Ə
    "\xC6\x90"     => 'E',    # Ɛ
  }
end

# Plain-text alternatives to the HTML special characters RedCloth uses.
if !defined? HTML_SPECIAL_CHAR_EQUIVALENTS
  HTML_SPECIAL_CHAR_EQUIVALENTS = {
    'amp'   => '&',
    'gt'    => '>',
    'lt'    => '<',
    'quot'  => '"',
    '#39'   => "'",
    '#169'  => '(c)',
    '#174'  => '(r)',
    '#215'  => 'x',
    '#8211' => '-',
    '#8212' => '--',
    '#8216' => "'",
    '#8217' => "'",
    '#8220' => '"',
    '#8221' => '"',
    '#8230' => '...',
    '#8242' => "'",
    '#8243' => '"',
    '#8482' => '(tm)',
    '#8594' => '->',
  }
end

class String
  # Convert string (assumed to be in UTF-8) to plain ASCII.
  def to_ascii
    self.to_s.clone.gsub(/[^\t\n\r\x20-\x7E]/) do |c|
      UTF8_TO_ASCII[c] || ' '
    end
  end

  # Convert string (assumed to be in UTF-8) to any other charset.  All invalid
  # characters are degraded to their rough ASCII equivalent, then converted.
  def iconv(charset)
    iconv = Iconv.new(charset, 'UTF-8')
    self.to_s.clone.gsub(/[^\t\n\r\x20-\x7E]/) do |c|
      begin
        iconv.iconv(c)
      rescue
        iconv.iconv(UTF8_TO_ASCII[c] || ' ')
      end
    end
  end

  # Remove html codes from string.  Used to make sure title is safe for HTML
  # header field.
  def strip_html
    self.gsub(/<[^>]*>/, '')
  end

  # Attempt to turn HTML into plain text.  Remove all <blah> tags, and convert
  # &blah; codes into ASCII equivalents.  Line breaks may still be a problem,
  # but this seems to work pretty well on the output of RedCloth at least.
  def html_to_ascii
    self.gsub(/\n+/, ' ').              # remove all newlines first
         gsub(/<br *\/> */, "\n").      # put one after every line break
         gsub(/<\/p> */, "\n\n").       # put two between paragraphs
         gsub(/[ \t]+(\n|$)/, '\\1').   # remove superfluous trailing whitespace
         gsub(/\n+\Z/, '').             # remove superfluous newlines at end
         gsub(/<[^>]*>/, '').           # remove all <tags>
         gsub(/&(#\d+|[a-zA-Z]+);/) { HTML_SPECIAL_CHAR_EQUIVALENTS[$1].to_s }
                                        # convert &xxx; and &#nnn; to ascii
  end

  # Wrap HTML string in a span that prevents long strings from being broken.
  def nowrap
    '<span style="white-space: nowrap">' + self + '</span>'
  end
end
