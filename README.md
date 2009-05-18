# Blogger.vim

The only one vim script which handles [Blogger](http://www.blogger.com/) using metarw. We also offer the ruby script blogger.rb which handles Blogger.

Blogger is a blog service that offers \*.blogspot.com. Therefore you would feel free to call this script blogspot.vim.

## Author

Tatsuhiro UJIHISA [http://ujihisa.blogspot.com/](http://ujihisa.blogspot.com/)

## Requirements

* vim 7.2+
  * [metarw 0.0.3+](http://www.vim.org/scripts/script.php?script_id=2335)
* ruby 1.9.1+
  * (gem) nokogiri 1.2.3+
  * (gem) rpeg-markdown 1.4.4+
* python 2.5.1+
  * html2text 2.35+

## How to use

Before you use blogger.vim, you have to change the setting of blogger [like it](http://gyazo.com/7c8b02a1a3e41fb665347323bf4fab84.png).

### Install
After the install of metarw, do them:

    $ cp blogger.vim ~/.vim/autoload/metarw/
    $ cp blogger.rb ~/.vim/autoload/metarw/
    $ cp html2text ~/.vim/autoload/metarw/
    $ chmod +x ~/.vim/autoload/metarw/html2text
    $ cat "g:blogger_email = 'your_email_here'" > ~/.vimrc
    $ cat "g:blogger_pass = 'your_blogger_password_here'" > ~/.vimrc

### Get the list of entries from your blog

    :e blogger:{blogid}:list

`{blogid}` is a big digit number. See your blog. There must be it.

sample blogid: 2961087480852727381

### Create a new entry to your blog

Write an entry on a buffer. Write the title on the first line, and the content on the rest of lines.
To post it, type

    :w blogger:{blogid}:create

If an error came, try `:w!` instead.

### blogger.rb

blogger.rb can do them:

* Get the list of the entries of your blog
* Show the contents of an entry in markdown notation
* Post a new entry with markdown notation
* Edit an entry

The corresponding usage:

    $ ruby blogger.rb list {blogid}
    $ ruby blogger.rb show {blogid} {uri}
    $ ruby blogger.rb create {blogid} {email} {password} < aaa.txt
    $ ruby blogger.rb update {blogid} {uri} {email} {password} < aaa.txt

## Licence

MIT

## For Developpers

### requirements

* rspec 1.2.6+

### Before commit

    $ spec blogger_spec.rb

All specs must be success or pending.

### TODOs

Implement them:

* Use Metarw
* Write document (~/.vim/doc/blogger.txt)
* Release Version 1.0 to vim.org
* Remove python and html2text. Blogger.vim should not need both ruby and python.
* Multiblogalization (Now blogger.vim can control only one blog with a vimrc)

### Known bugs

* html2text of python cannot handle multi-byte characters
* html2text does not neccessarily decode markdown. (e.g. continuous <li>s)
* Blogger.update needs to be called twice
