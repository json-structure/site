module Jekyll
  class SocialCardGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Generate a social card for each post
      site.posts.docs.each do |post|
        site.pages << SocialCardPage.new(site, post)
      end
    end
  end

  class SocialCardPage < Page
    def initialize(site, post)
      @site = site
      @base = site.source
      @dir = 'social-cards'
      @name = "#{post.data['slug'] || post.basename_without_ext}.svg"

      self.process(@name)
      self.data = {
        'layout' => 'social-card',
        'title' => post.data['card_title'] || post.data['title'],
        'date' => post.data['date'],
        'sitemap' => false
      }
    end
  end
end
