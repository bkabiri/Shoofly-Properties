# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class AiDescriptionGenerator
  def initialize(listing, attrs = {})
    @listing = listing
    @attrs   = attrs || {}
  end

  def call
    prompt = build_prompt

    api_key = ENV["OPENAI_API_KEY"].to_s
    return fallback_text if api_key.empty?

    uri = URI.parse("https://api.openai.com/v1/chat/completions")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{api_key}"
    req["Content-Type"]  = "application/json"

    req.body = {
      model: "gpt-4o-mini",
      temperature: 0.6,
      max_tokens: 450, # enough for ~180–230 words
      messages: [
        {
          role: "system",
          content: "You are a UK estate agency copywriter. Use UK spelling, a warm but factual tone, and avoid hype or prices."
        },
        { role: "user", content: prompt }
      ]
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res  = http.request(req)

    json = JSON.parse(res.body) rescue {}
    if res.code.to_i >= 400
      msg = json.dig("error", "message") || res.message
      raise "OpenAI error (#{res.code}): #{msg}"
    end

    text = json.dig("choices", 0, "message", "content").to_s.strip
    text.present? ? text : fallback_text
  rescue => e
    Rails.logger.error("[AI] OpenAI request failed: #{e.class} #{e.message}")
    fallback_text
  end

  private

  def build_prompt
  a  = attr(:address)
  t  = prettify(attr(:property_type))
  b  = attr(:bedrooms)
  ba = attr(:bathrooms)

  <<~PROMPT
    Write a real estate listing description for a UK audience.

    Property details:
    - Address (approx): #{a.presence || "—"}
    - Property type: #{t.presence || "—"}
    - Bedrooms: #{b.presence || "—"}
    - Bathrooms: #{ba.presence || "—"}

    Output requirements:
    • Structure: exactly 4 paragraphs of prose, no headings or bullet points.  
    • Paragraph 1: One-sentence opener that sets the location and appeal, followed by an overview of the property style and character.  
    • Paragraph 2: Description of the interior layout and features (rooms, light, upgrades, flow, storage, comfort).  
    • Paragraph 3: Outdoor features (garden, patio, balcony, parking, garages, or typical amenities).  
    • Paragraph 4: Lifestyle context — shops, cafés, schools, green spaces, and transport links typical for the area. End with a soft call to action such as “Book a viewing today.”

    Style rules:
    - Tone: clear, inviting, factual, UK spelling.  
    - Length: about 160–220 words total.  
    - Avoid emojis, headings, lists, or prices.  
    - Keep it natural, like a professional UK estate agent.
  PROMPT
end

  def attr(key)
    @attrs[key] || @listing.try(key)
  end

  def prettify(val)
    val.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
  end

  def fallback_text
    a  = attr(:address)
    t  = prettify(attr(:property_type))
    b  = attr(:bedrooms)
    ba = attr(:bathrooms)

    headline = +"A well‑presented"
    headline << " #{b}-bedroom" if b.present?
    headline << " #{t}" if t.present?
    headline << (a.present? ? " on #{a}." : ".")

    para1 = "#{headline} Bright interiors and a practical layout create a comfortable setting for day‑to‑day living, with room to relax and entertain. Finishes are tasteful and neutral, making the home easy to furnish and personalise."
    para2 = "Accommodation includes generous living space, a fitted kitchen and #{ba.present? ? "#{ba} bathrooms" : "well‑appointed bathrooms"}. Outside, there is usable private space for alfresco dining and everyday enjoyment, plus convenient #{t&.downcase&.include?("flat") ? "street" : "off‑street"} parking where available. Book a viewing to appreciate the setting and potential."

    "#{para1}\n\n#{para2}"
  end
end