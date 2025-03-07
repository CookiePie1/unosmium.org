# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

require 'miro'

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

Dir.new(Pathname.new(__dir__) + 'data')
  .children
  .select { |f| f.end_with?('.yaml') }
  .reject { |f| f == 'recents.yaml' }
  .map { |f| f.delete_suffix('.yaml') }
  .each do |t|
  proxy "/results/#{t}.html", "/results/template.html",
    locals: { tournament: t }, ignore: true
end

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  STATES_BY_POSTAL_CODE = {
    AK: 'Alaska ',
    AZ: 'Arizona ',
    AR: 'Arkansas ',
    CA: 'California ',
    nCA: 'Northern California',
    sCA: 'Southern California',
    CO: 'Colorado ',
    CT: 'Connecticut ',
    DE: 'Delaware ',
    DC: 'District of Columbia',
    FL: 'Florida ',
    GA: 'Georgia ',
    HI: 'Hawaii ',
    ID: 'Idaho ',
    IL: 'Illinois ',
    IN: 'Indiana ',
    IA: 'Iowa ',
    KS: 'Kansas ',
    KY: 'Kentucky ',
    LA: 'Louisiana ',
    ME: 'Maine ',
    MD: 'Maryland ',
    MA: 'Massachusetts ',
    MI: 'Michigan ',
    MN: 'Minnesota ',
    MS: 'Mississippi ',
    MO: 'Missouri ',
    MT: 'Montana ',
    NE: 'Nebraska ',
    NV: 'Nevada ',
    NH: 'New Hampshire ',
    NJ: 'New Jersey ',
    NM: 'New Mexico ',
    NY: 'New York ',
    NC: 'North Carolina ',
    ND: 'North Dakota ',
    OH: 'Ohio ',
    OK: 'Oklahoma ',
    OR: 'Oregon ',
    PA: 'Pennsylvania ',
    RI: 'Rhode Island ',
    SC: 'South Carolina ',
    SD: 'South Dakota ',
    TN: 'Tennessee ',
    TX: 'Texas ',
    UT: 'Utah ',
    VT: 'Vermont ',
    VA: 'Virginia ',
    WA: 'Washington ',
    WV: 'West Virginia ',
    WI: 'Wisconsin ',
    WY: 'Wyoming '
  }
  def find_logo_path(filename)
    image_dir = Dir.new(Pathname.new(__dir__) + 'source' + 'images' + 'logos')
    potential_logos = [
      filename + '.png',
      filename + '.jpg',
      filename.split('_')[0..-2].join('_') + '.png', # remove _b or _c suffix
      filename.split('_')[0..-2].join('_') + '.jpg', # remove _b or _c suffix
      filename.split('_')[0..-2].join('_') + '.gif', # remove _b or _c suffix
      filename.split('_')[1..-2].join('_') + '.png', # remove date as well
      filename.split('_')[1..-2].join('_') + '.jpg', # remove date as well
      filename.split('_')[1..-2].join('_') + '.gif'  # remove date as well
    ]
    potential_logos.concat(%w[
      default.jpg
    ].shuffle)
    '/images/logos/' + potential_logos.find { |l| image_dir.children.include? l }
  end

  def find_bg_color(path)
    filename = path.delete_prefix('results/').delete_suffix('.html')
    logo_file_path = (Pathname.new(__dir__) +
                      'source' +
                      find_logo_path(filename).delete_prefix('/')).to_s
    colors = Miro::DominantColors.new(logo_file_path)
    color = colors.to_hex[3].paint # String#paint from the chroma gem

    while color.light?
      color = color.darken
    end
    color
  end

  def tournament_title(t)
    case t[:level]
    when 'Nationals'
      'Science Olympiad National Tournament'
    when 'States'
      "#{expand_state_name(t[:state])} Science Olympiad State Tournament"
    when 'Regionals'
      "#{expand_state_name(t[:state])} #{t[:name]} Regional Tournament"
    when 'Invitational'
      "#{t[:name] ? t[:name] : t[:location]} Invitational"
    end
  end

  def tournament_title_short(t)
    case t[:level]
    when 'Nationals'
      'SONT'
    when 'States'
      "#{t[:state]} States"
    when 'Regionals'
      "#{t[:state]} #{t[:name]} Regionals"
    when 'Invitational'
      name = t[:name] ? t[:name] : t[:location]
      title = name.split(' ').count >= 3 ? acronymize(name) : name
      "#{title} Invitational"
    end
  end

  def acronymize(phrase)
    phrase.split(' ')
          .select { |w| /^[[:upper:]]/.match(w) }
          .map { |w| w[0] }
          .join
  end

  def expand_state_name(postal_code)
    STATES_BY_POSTAL_CODE[postal_code.to_sym]
  end

  def format_school(team)
    if team[:'school abbreviation']
      abbr = abbr_school(team[:'school abbreviation'])
      "<abbr title=\"#{team[:school]}\">#{abbr}</abbr>"
    else
      abbr_school(team[:school])
    end
  end

  def abbr_school(school)
    school.sub('Middle School', 'M.S.')
          .sub('Junior High School', 'J.H.S.')
          .sub('High School', 'H.S.')
  end

  def search_string(helper)
    t = helper.tournament
    words = [
      'science',
      'olympiad',
      'tournament',
      t[:name],
      t[:location],
      t[:name] ? acronymize(t[:name]) : nil,
      t[:location] ? acronymize(t[:location]) : nil,
      t[:level],
      t[:level] == "Nationals" ? 'nats' : nil,
      t[:level] == "Nationals" ? 'sont' : nil,
      t[:state],
      t[:state] ? expand_state_name(t[:state]) : nil,
      "div-#{t[:division]}",
      "division-#{t[:division]}",
      t[:year],
      t[:date],
      t[:date].strftime('%A'),
      t[:date].strftime('%B'),
      t[:date].strftime('%-d'),
      t[:date].strftime('%Y')
    ]
    words.compact.map(&:to_s).map(&:downcase).join('|')
  end
end

activate :external_pipeline,
  name: :webpack,
  command: build? ? './node_modules/webpack/bin/webpack.js --bail' : './node_modules/webpack/bin/webpack.js --watch -d',
  source: ".tmp/dist",
  latency: 1

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end
