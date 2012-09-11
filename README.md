# UWaterloo Desire2Learn Scraper

Hello Waterloo student, this is a program to pull all the files from your classes down from Learn.

## How to run

1. Copy `config.yml.example` to `config.yml`, and put in your information. Optionally specify `dropbox_path` to put downloaded files under that path.
2. Run `bundle` and `bundle exec ruby app.rb`

## Beware!

It works on my Macbook. I haven't tested anywhere else.

It scrapes the site, so the second D2L changes their markup, this might break.

This is not affiliated with UW or D2L. Don't sue me, thanks.

---

Made by [Eddie](https://twitter.com/ldquo "Follow me on Twitter!")
