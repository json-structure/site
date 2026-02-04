---
layout: default
title: Blog | JSON Structure
permalink: /blog/
---

# JSON Structure Blog

Welcome to the JSON Structure blog. Here we explore practical applications, dive deeper into features, and share insights about using JSON Structure effectively.

<div class="blog-list">
{% for post in site.posts %}
  <article class="blog-entry">
    <h2><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h2>
    <p class="post-meta">
      <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%B %d, %Y" }}</time>
      {% if post.author %} • {{ post.author }}{% endif %}
    </p>
    {% if post.excerpt %}
    <p class="post-excerpt">{{ post.excerpt | strip_html | truncatewords: 50 }}</p>
    {% endif %}
    <p><a href="{{ post.url | relative_url }}">Read more →</a></p>
  </article>
{% endfor %}
</div>

<p class="rss-link">
  <a href="{{ "/rss.xml" | relative_url }}">Subscribe via RSS</a>
</p>
