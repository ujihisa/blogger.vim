# Blogger.vim

The only one vim script which handles [Blogger](http://www.blogger.com/) using metarw. We also offer the ruby script blogger.rb which handles Blogger.

Blogger is a blog service that offers \*.blogspot.com. So feel free to call this script blogspot.vim.

## Author

Tatsuhiro UJIHISA [http://ujihisa.blogspot.com/](http://ujihisa.blogspot.com/)

## Requirements

* vim 7.2+
  * [metarw 0.0.3+](http://www.vim.org/scripts/script.php?script_id=2335)
* ruby 1.9.2+
  * (gem) nokogiri 1.2.3+
  * (gem) rpeg-markdown 1.4.4+
* python 2.5.1+
  * html2text 2.35+

## How to use

Before you use blogger.vim, you have to change the setting of blogger.

!(Convert line breaks)[http://gyazo.com/7c8b02a1a3e41fb665347323bf4fab84.png]

## For Developpers

### requirements

* rspec 1.2.6+

### Before commit

    $ spec blogger_spec.rb

### TODOs

Implement them:

* Update an entry
* Use Metarw
* Write document
* Release Version 1.0 to vim.org
* Remove python and html2text. Blogger.vim should not need both ruby and python.
