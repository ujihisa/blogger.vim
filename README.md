# Blogger.vim

The only one vim script which handles [Blogger](http://www.blogger.com/) using
metarw. We also offer the ruby script blogger.rb which handles Blogger.

Blogger is a blog service that offers \*.blogspot.com. Therefore you would feel
free to call this script blogspot.vim.

## Author

Tatsuhiro UJIHISA <http://ujihisa.blogspot.com/>

## Requirements

* vim 7.2+
  * [metarw 0.0.3+](http://www.vim.org/scripts/script.php?script_id=2335)
* ruby 1.9.2+ (recommended: 2.1.0dev)
  * (gem) nokogiri 1.4.2+
  * (gem) net-https-wrapper
* pandoc 1.2+

## How to use

Before you use blogger.vim, you have to change the setting of blogger [like it](http://gyazo.com/7c8b02a1a3e41fb665347323bf4fab84.png).

### Install

After the install of metarw, do them:

    $ cp autoload/metarw/blogger.vim ~/.vim/autoload/metarw/
    $ cp autoload/metarw/blogger.rb ~/.vim/autoload/metarw/

And then add the following to your .vimrc:

    let g:blogger_blogid = 'your_blogid_here'
    let g:blogger_email = 'your_email_here'
    let g:blogger_pass = 'your_blogger_password_here'

`{blogid}` is a big digit number. See the html source of your blog and find  `blogId=****`.

sample blogid: 2961087480852727381

You also can specify Ruby command.

    let g:blogger_ruby_path = expand('~/git/ruby/local/bin/ruby')

The default is `/usr/bin/ruby` that few people are using.

### Get the list of entries from your blog

    :e blogger:list

### Create a new entry to your blog

Write an entry on a buffer. Write the title on the first line, and the content
on the rest of lines.  To post it, type

    :w blogger:create

If an error came, try `:w!` instead.

### Create a draft and save it on your blogger

Add "DRAFT" in the very beginning of the title, the first line of the buffer.

### Put code to gist

If you use git and github, you can put code to gist automatically.

First, setup git. Access [GitHub's account settings](https://github.com/account), and click "Global git config information".

Second, type `git config` on your shell.

Then, add the following line into your `.vimrc`:

    let g:blogger_gist = 1

Now you finished all preparations. Then write code like this:

    below is a sample code.

        a
        a
        a
        a
        a

`blogger.rb` automatically puts codes in your blog post to gist if the codes
are more than 5 lines.

### FAQ

* Q. I put the youbute embed into my blog, but it doesn't appear.

        A. That's because of '&' in the html. You must replace '&' to '&amp;'
        by hand.

### blogger.rb

blogger.rb can do them:

* Get the list of the entries of your blog
* Show the contents of an entry in markdown notation
* Post a new entry with markdown notation
* Edit an existing entry

The corresponding usage:

    $ ruby blogger.rb list {blogid}
    $ ruby blogger.rb show {blogid} {uri}
    $ ruby blogger.rb create {blogid} {email} {password} < aaa.txt
    $ ruby blogger.rb update {blogid} {uri} {email} {password} < aaa.txt

## License

MIT license

Copyright (C) 2009-2013 Tatsuhiro UJIHISA <http://ujihisa.blogspot.com/>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


## For Developpers

### requirements

* rspec 1.2.6+

### Before commit

    $ spec blogger_spec.rb

All specs must be success or pending.

### TODOs

Implement them:

* Write document (~/.vim/doc/blogger.txt)
* Multiblogalization (Now blogger.vim can control only one blog with a vimrc)

# vim: filetype=markdown
